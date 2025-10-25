classdef Kdtree < handle
% Kdtree Kd-tree implementation for codegen.

% Copyright 2023 The MathWorks, Inc.
%#codegen

% Kdtree is the copy of vision.internal.codegen.Kdtree.m
% But this version removed capabilities that are not needed for
% bpsEncoder. Additionally restricted knnsearch to the immediate neighbor.

    properties(Access = private, Hidden)
        InputData       % Input data as unOrganized
        NxNoNaN         % The number of points with no-NaN value
        CutDim          % The dimension along which each node is split, or 0 for a leaf node
        CutVal          % Cutoff value for split.
        LowerBounds     % The lower bounds of the corresponding node along each dimension
        UpperBounds     % The upper bounds of the corresponding node along each dimension
        LeftChild       % Left child index for each node
        RightChild      % Right child index for each node
        LeafNode        % A logical vector indicating whether the node is a leaf node.
        IdxAll          % The point index for all nodes
        IdxDim          % Length of each node
        WasNaNIdx       % The index that has NaN values
        NodeIdxLeft     % The left index in IdxAll of each node
        NodeIdxRight    % The right index in IdxAll of each node
    end

    properties(GetAccess = public, SetAccess = private)
        IsIndexed      % Flag to decide if tree is indexed or not
    end


    methods
        %==================================================================
        % Constructor
        %==================================================================
        function obj = Kdtree(inputClass)
            obj.InputData   = cast([], inputClass);
            obj.NxNoNaN     = 0;
            obj.CutDim      = [];
            obj.CutVal      = [];
            obj.LowerBounds = [];
            obj.UpperBounds = [];
            obj.LeftChild   = [];
            obj.RightChild  = [];
            obj.LeafNode    = cast([], 'logical');
            obj.IdxAll      = zeros(0, 1, 'uint32');
            obj.IdxDim      = zeros(0,1);
            obj.WasNaNIdx   = [];
            obj.IsIndexed   = false;
            obj.NodeIdxLeft = zeros(0, 1, 'uint32');
            obj.NodeIdxRight= zeros(0, 1, 'uint32');
        end

        %==================================================================
        % K nearest neighbor search
        %==================================================================
        function [indices, dists, valid] = knnSearch(obj, queryPoints, K)

        % bpsEncoder only require to find the first nearest neighbor
        % Hence blocking k > 1
            assert(K < 2);
            % validate knnSearch inputs
            checkKNNSearchInputs(obj, queryPoints, K);

            [indices, dists, valid] = invokeKNNSearch(obj, queryPoints, K);
            dists = sqrt(dists);
            indices = cast(indices, class(obj.InputData));
        end


        %==================================================================
        % Index InputData
        %==================================================================
        function index(obj, inputData, varargin)
            narginchk(2,3);

            checkIndexInputs(obj, inputData, varargin{:})

            bucketSize =  50;
            if nargin > 2 && isfield(varargin{1}, 'bucketSize')
                bucketSize = varargin{1}.bucketSize;
            end
            buildIndex(obj, inputData, bucketSize);

            % Once the tree is indexed, Set the IsIndexed Flag to true
            obj.IsIndexed = true;
        end
    end

    methods(Access = private, Hidden)
        %==================================================================
        % Check the inputs into index
        %==================================================================
        function checkIndexInputs(~, ~, varargin)
            if nargin == 3

                % validate bucketSize
                validateattributes(varargin{1}.bucketSize, {'numeric'}, ...
                                   {'real', 'nonsparse', 'nonnan', 'finite', 'integer', 'positive', '>=', 1}, '', 'BucketSize');
            end
        end

        %==================================================================
        % Check the inputs into knnSearch
        %==================================================================
        function checkKNNSearchInputs(obj, ~, K) %#ok<INUSD>
        % check Number of Dimensions of queryPoints

        % check that K is a scalar double
            validateattributes(K, {'double'}, ...
                               {'real', 'nonsparse', 'scalar', 'nonnan', 'finite', 'integer', 'positive'}, '', 'K');
        end


        %==================================================================
        % Index data using a KD-Tree for single/double data
        %==================================================================
        function buildIndex(obj, inputData, bucketSize)
            narginchk(2,3);

            numDims = ndims(inputData);
            featDims = 0;
            if numDims == 2
                featDims = size(inputData, 2);
            elseif numDims == 3
                featDims = size(inputData, 3);
            end

            % Convert inputData to unOrganized Data if it is organized Data
            if ismatrix(inputData)
                X = inputData;
            else
                X = reshape(inputData, [], featDims);
            end

            if nargin < 3
                bucketSize = 50;
            end

            [nXin, nDims] = size(X);

            wasnan = any(isnan(X), 2)';

            hasNaNs = any(wasnan);
            notnan = 1:nXin;
            if hasNaNs
                notnan = find(~wasnan); %index of points with no missing values.
                wasnanIdx = find(wasnan);
                nx = numel(notnan); %the number points with no missing values
            else
                nx = nXin;
                wasnanIdx = [];
            end
            nx_nonan = nx;
            % M is the maximal number of nodes if we choose to cut at the
            % median at each cutting dimension. If the tree is not split at
            % the median in each non-leaf node, the tree may contain more
            % than M nodes.

            m1 = max(nx/bucketSize, 1);
            m2 = log2(m1);
            m3 = ceil(m2)+1;
            M = 2^m3 - 1;

            coder.internal.prefer_const(M, bucketSize);

            % When X is bounded variable size, M is not calculated properly, and because of that
            % dynamic memory allocation is used. This appear to be a Coder bug.
            % A temporary solution is to use the following assertion, which Coder is
            % able to calculate.
            assert(M <= max(nXin/10, 1));

            % Keeping accessing the properties of KDTreeSearcher inside a loop
            % seems affect the performance, therefore We created some temporary
            % variables.
            % The dimension along which each node is split, or 0 for a leaf node.
            % M1 = nXin/10;
            cutDimTemp = zeros(M, 1);

            % cutoff value for split. The points go to left child node if its
            % values on the split dimension is not greater than this cutoff
            % value.
            cutValTemp = zeros(M, 1);
            % each row specifies the lower bounds of the corresponding node along
            % each dimension.
            if coder.target('MATLAB')
                lowerBoundsTemp = -Inf(M, nDims);
            else
                lowerBoundsTemp = -coder.internal.inf(M, coder.internal.indexInt(nDims));
            end

            % each row specifies the upper bounds of the corresponding node along
            % each dimension.
            if coder.target('MATLAB')
                upperBoundsTemp = Inf(M, nDims);
            else
                upperBoundsTemp = coder.internal.inf(M, coder.internal.indexInt(nDims));
            end
            % A column vector indicating the left child index.
            leftChildTemp = zeros(M, 1);
            % A column vector indicating the right child index.
            rightChildTemp= zeros(M, 1);
            % A logical vector indicating whether the node is a leaf node. TRUE
            % for a leaf node.
            leafNodeTemp = false(M, 1);
            % Each row is a double vector indicating the data points belong to the
            % corresponding node. Empty for a non-leaf node.
            idxTemp1 = cell(M, 1);
            idxTemp = coder.nullcopy(idxTemp1);

            % Only data with no NaNs will be used to create the kd-tree
            idxTemp{1} = notnan;

            if coder.internal.isConst(nx)
                coder.varsize('idxTemp{:}', [1, nx], [0, 1]);
            end

            currentNode = 1;
            nextUnusedNode = 2; % The next un-used node number
                                % Start to build the kd-tree
            while(currentNode < nextUnusedNode)
                currentIdx = idxTemp{currentNode};
                nPoints = numel(currentIdx);
                if nPoints <= bucketSize % this.BucketSize
                                         % A leaf node
                    leafNodeTemp(currentNode) = true;
                else % A non-leaf node
                     % find the cutting dimension with the largest spread

                    [~, cuttingDim] = max(max(X(currentIdx, :), [], 1) - ...
                                          min(X(currentIdx, :), [], 1), [], 2);

                    % Choose the median value as the partition value

                    [sx,sidx] = sort(X(currentIdx, cuttingDim));
                    sidx= currentIdx(sidx);
                    half = ceil(size(sx, 1)/2);
                    % The cutting threshold. It will not be the median when
                    % sx has odd number of element.
                    p = (sx(half) + sx(half+1))/2;

                    cutDimTemp(currentNode) = cuttingDim;
                    cutValTemp(currentNode) = p;

                    lChild = nextUnusedNode;
                    rChild = nextUnusedNode + 1;
                    leftChildTemp(currentNode) = lChild;
                    rightChildTemp(currentNode) = rChild;

                    % Decide the upper bounds of the two children
                    temp = upperBoundsTemp(currentNode, :);

                    % Right child keeps the parent's upper bounds
                    upperBoundsTemp(rChild, :) = temp ;
                    temp(cuttingDim) = p;
                    upperBoundsTemp(lChild, :) = temp;

                    % Decide the lower bounds of the two children
                    temp = lowerBoundsTemp(currentNode, :);

                    % Left child keeps the parent's lower bounds
                    lowerBoundsTemp(lChild, :) = temp;
                    temp(cuttingDim) = p;
                    lowerBoundsTemp(rChild, :) = temp;
                    % Add the data points of the current node to its
                    % children
                    idxTemp{currentNode} = zeros(1, 0);
                    idxTemp{lChild} = sidx(1:half);
                    idxTemp{rChild} = sidx(half+1:end);
                    nextUnusedNode = nextUnusedNode+2;
                end
                currentNode = currentNode + 1;
            end %while

            unusedNodes = coder.internal.indexMinus(nextUnusedNode, 1);

            tempDim = zeros(unusedNodes, 1); % number of points in each nodes
            tempIdx = zeros(nXin, 1, 'uint32'); % the index of the point contained in each node
            tempNodeIdxLeft = zeros(unusedNodes, 1, 'uint32'); % The left index in IdxAll of each node
            tempNodeIdxRight = zeros(unusedNodes, 1, 'uint32'); % The right index in IdxAll of each node

            cc = 1;
            for c = 1:unusedNodes
                tempDim(c) = numel(idxTemp{c});
                if tempDim(c) > 0
                    tempIdx(cc:cc+tempDim(c)-1) = idxTemp{c}';
                    tempNodeIdxLeft(c) = cc;
                    cc = cc + tempDim(c);
                    tempNodeIdxRight(c) = cc - 1;
                end
            end
            % Assign the temporary variables to the properties
            obj.InputData = X;
            obj.CutDim = cutDimTemp(1:unusedNodes);
            obj.CutVal = cutValTemp(1:unusedNodes);
            obj.LowerBounds = lowerBoundsTemp(1:unusedNodes,:);
            obj.UpperBounds = upperBoundsTemp(1:unusedNodes,:);
            obj.IdxAll = tempIdx;
            obj.IdxDim = tempDim;
            obj.LeftChild = leftChildTemp(1:unusedNodes);
            obj.RightChild = rightChildTemp(1:unusedNodes);
            obj.LeafNode = leafNodeTemp(1:unusedNodes);
            obj.NxNoNaN = nx_nonan;
            obj.WasNaNIdx = wasnanIdx;
            obj.NodeIdxLeft = tempNodeIdxLeft;
            obj.NodeIdxRight = tempNodeIdxRight;
        end


        %==================================================================
        % Find the K nearest neighbors using an exact search.
        %==================================================================
        function [indices, dists, valid] = invokeKNNSearch(obj, queryPoints, numNNin)
            X = obj.InputData;

            outClass = class(X);
            queryPoints = cast(queryPoints, outClass);

            [nX, ~] = size(X);
            [nY, ~]= size(queryPoints);

            wasNaNY = any(isnan(queryPoints), 2);

            numNN1 = coder.internal.indexInt(min(numNNin, nX));
            assert(numNN1 <= nX);
            % Degenerate case, just return an empty matrix or cell of the proper size.
            if (nY == 0 || numNN1 ==0)
                indices = zeros(numNN1, nY, 'uint32');
                dists = zeros(numNN1, nY, 'like', queryPoints);
                valid = zeros(nY, 1, 'uint32');
                return;
            end

            numNN = coder.internal.indexInt(min(numNN1, obj.NxNoNaN));

            if numNN > 0        %ask for nearest neighbors
                indices = zeros(numNN1, nY, 'uint32');
                % Initialize the distance matrix
                dists = zeros(numNN1, nY, 'like',queryPoints);
                % Initialize the valid matrix
                valid = zeros(nY, 1, 'uint32');

                for j = 1:coder.internal.indexInt(nY)
                    if ~wasNaNY(j) %The jth point in queryPoints has NaN
                        pq = searchKdtree(obj, X, queryPoints(j,:), numNN);

                        [sortD, tempI] = sort(pq.D(1:pq.k));
                        sortI = pq.I(1:pq.k);
                        indices(1:pq.k, j) = sortI(tempI);
                        dists(1:pq.k, j) = sortD;

                        valid(j, 1) = pq.k;
                    end
                end
            else %numNN2 ==0
                indices = zeros(0, nY, 'uint32');
                dists = zeros(0, nY, 'like', queryPoints);
                valid = zeros(nY, 1, 'uint32');
            end
        end


        %==================================================================
        % Helper Function for knnSearch
        %==================================================================
        function pq = searchKdtree(obj, X, queryPt, numNN)

            [nX, nDims] = size(X);
            % Find the node containing the query point
            startNode = getStartingNode(queryPt, obj.CutDim , obj.CutVal, obj.LeafNode, obj.LeftChild, obj.RightChild);

            pq = struct('D', zeros(numNN, 1, 'like', X), 'I', zeros(numNN, 1, 'uint32'), 'k', zeros(1, 'uint32'));

            % Search the starting node
            pq = searchNode(obj, X, queryPt, startNode, numNN, pq);

            % If found enough nearest points and the ball is within the bounds of
            % the starting node, the search is done
            if pq.k > 0
                ballIsWithinBounds = ballWithinBounds(queryPt, obj.LowerBounds(startNode, :),...
                                                      obj.UpperBounds(startNode, :), pq.D(1));
            else
                ballIsWithinBounds = false;
            end

            if pq.k == numNN && ballIsWithinBounds
                return
            end
            nNodes = size(obj.CutDim, 1);
            if coder.internal.isConst(nNodes)
                coder.varsize('nodeStack', [nNodes, 1], [1, 0]);
            elseif coder.internal.isConst(nX)
                coder.varsize('nodeStack', [ceil(nX/10), 1], [1, 0]);
            else
                coder.varsize('nodeStack', [], [1, 0]);
            end

            nodeStack = 1;  % Start from the root node

            while ~isempty(nodeStack)
                assert(size(nodeStack,1) <= nNodes);
                currentNode = nodeStack(1);     % Get the next node to be visited
                nodeStack(1) = [];
                %     nodeStack = nodeStack(2:end);   % Remove the node that is being visited
                isBoundsOverlapBall = boundsOverlapBall(queryPt, obj.LowerBounds(currentNode,:),...
                                                        obj.UpperBounds(currentNode,:), pq.D(1), nDims);

                if pq.k < numNN || isBoundsOverlapBall
                    % we haven't found enough neighbors or the current node overlaps the ball
                    if ~obj.LeafNode(currentNode)
                        if (queryPt(obj.CutDim(currentNode)) <= obj.CutVal(currentNode))
                            % The point is on the left side of the current node
                            % push the right child and then left child, so that
                            % the left child will be visited first
                            nodeStack = [obj.LeftChild(currentNode); obj.RightChild(currentNode); nodeStack]; %#ok
                        else
                            % The point is on the right side
                            % visit the right child first and then the left child
                            nodeStack = [obj.RightChild(currentNode); obj.LeftChild(currentNode); nodeStack]; %#ok
                        end
                    elseif currentNode ~= startNode
                        % current node is a leaf node that we haven't visited
                        pq = searchNode(obj, X, queryPt, currentNode, numNN, pq);
                    end
                end
            end
        end

        %==================================================================
        % Helper function for searchKdtree
        % Search the nearest points within a node.
        %==================================================================
        function pq = searchNode(obj, X, queryPt, node, numNN, pq)
            for i = obj.NodeIdxLeft(node):obj.NodeIdxRight(node)
                idx = obj.IdxAll(i);
                diffAllDim = X(idx,:) - queryPt;
                dist = sum(diffAllDim.^2, 2);
                % If not found enough nearest points or the point is closer
                % than any existing neighbor, add this point into the heap
                if pq.k < numNN || dist < pq.D(1)
                    pq = maxHeapAdd(pq, dist, idx, numNN);
                end
            end
        end
    end
end

%==================================================================
function isBoundsOverlapBall = boundsOverlapBall(queryPt, lowBounds, upBounds, radius, nDims)

    isBoundsOverlapBall = true;
    sumDist = zeros(1, 'like', queryPt);
    for c = 1:nDims
        if queryPt(c) < lowBounds(c)
            distToAdd = coorPow(queryPt(c) - lowBounds(c));
            sumDist = accuDist([sumDist, distToAdd]);
        elseif queryPt(c) > upBounds(c)
            distToAdd = coorPow(queryPt(c) - upBounds(c));
            sumDist = accuDist([sumDist, distToAdd]);
        end
        if sumDist > radius
            isBoundsOverlapBall = false;
            return
        end
    end
end

%==================================================================
function ballIsWithinBounds = ballWithinBounds(queryPt, lowBounds, upBounds, poweredRadius)

    lowDist = coorPow(queryPt - lowBounds);
    upDist = coorPow(queryPt - upBounds);

    if min(lowDist) <= poweredRadius || min(upDist) <= poweredRadius
        ballIsWithinBounds = false;
        return
    end
    ballIsWithinBounds = true;

end

%==================================================================
function node = getStartingNode(queryPt, cutDim , cutVal, leafNode, leftChild, rightChild)
    node = 1;
    while ~leafNode(node)
        if queryPt(cutDim(node)) <= cutVal(node)
            node = leftChild(node);
        else
            node = rightChild(node);
        end
    end
end

%==================================================================
function powDist = coorPow(pRadIn)
    powDist = pRadIn .* pRadIn;
end

%==================================================================
function distOut = accuDist(distIn)
    aDistOut = sum(distIn,2);
    distOut = aDistOut(:, 1);
end

%==================================================================
function pq = maxHeapAdd(pq, dist, idx, numNN)
% Add a point to the heap
    if pq.k == numNN
        pq = removeHeapMax(pq);
    end
    pq.k = pq.k + 1;

    i = pq.k;
    pq.D(i) = dist;
    pq.I(i) = idx;

    while (i > 1) && (pq.D(idivide(i,2)) < pq.D(i))
        pq = swapHeap(pq, i, idivide(i,2));
        i = idivide(i,2);
    end
end

%==================================================================
function pq = removeHeapMax(pq)
% Remove the max point from the heap
    pq.D(1) = pq.D(pq.k);
    pq.I(1) = pq.I(pq.k);
    pq.k = pq.k - 1;
    pq = maxHeapify(pq, 1, pq.k);
end
%==================================================================
function pq = maxHeapify(pq, i, size)
    left = 2*i;
    right = 2*i+1;
    if (left <= size) && (pq.D(left) > pq.D(i))
        largest = left;
    else
        largest = i;
    end

    if (right <= size) && (pq.D(right) > pq.D(largest))
        largest = right;
    end
    if (largest ~= i)
        pq = swapHeap(pq, i, largest);
        pq = maxHeapify(pq, largest, size);
    end
end
%==================================================================
function pq = swapHeap(pq, i, j)
    dist = pq.D(i);
    idx = pq.I(i);
    pq.D(i) = pq.D(j);
    pq.I(i) = pq.I(j);
    pq.D(j) = dist;
    pq.I(j) = idx;
end
