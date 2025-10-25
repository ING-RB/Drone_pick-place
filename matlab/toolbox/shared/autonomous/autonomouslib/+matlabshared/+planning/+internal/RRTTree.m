%matlabshared.planning.internal.RRTTree tree data structure for RRT planning.

% Copyright 2017-2024 The MathWorks, Inc.

%#codegen
classdef RRTTree < matlabshared.planning.internal.EnforceScalarHandle

    properties (Dependent, SetAccess = private)
        %Nodes
        %   Nodes in the tree, of size numNodes-by-3.
        Nodes

        %Edges
        %   Edges in the tree, of size numEdges-by-2. Each row
        %   [startId,endId] in Edges represents an edge from node startId
        %   to node endId.
        Edges

        %Costs
        %   Cumulative edge costs in the tree, of size numEdges-by-1. Each
        %   element in costs represents the cost to the n-th node.
        Costs
    end

    properties (SetAccess = private)
        %NeighborSearcher
        %   Near neighbor searcher object.
        NeighborSearcher
    end

    properties (SetAccess = private,GetAccess = ?matlab.unittest.TestCase)
        NodeBuffer
        NodeIndex

        EdgeBuffer
        EdgeIndex

        CostBuffer

        BufferSize

        NodeDim

        Precision

        RewireFactor = 1;
        kRRT
    end


    %----------------------------------------------------------------------
    % API
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        function this = RRTTree(nodeDim, precision, neighborSearcher, bufferSize)

            validateattributes(nodeDim, {'single','double'}, ...
                               {'real', 'finite', 'positive'}, 'RRTTree', 'node dimension');

            precision = validatestring(precision, {'single','double'}, ...
                                       'RRTTree', 'precision');

            validateattributes(neighborSearcher,...
                               {'matlabshared.planning.internal.NeighborSearcher'}, ...
                               {'scalar'}, 'RRTTree', 'neighborSearcher');

            validateattributes(bufferSize, {'double'}, ...
                               {'real','integer', 'scalar', 'positive'}, 'RRTTree', ...
                               'bufferSize');

            this.NodeDim    = nodeDim;
            this.Precision  = precision;
            this.BufferSize = bufferSize;

            this.NeighborSearcher = neighborSearcher;

            allocateBuffers(this);
            computeK(this);
        end

        %------------------------------------------------------------------
        function reset(this)

        % Reset buffer indices
            this.NodeIndex = 1;
            this.EdgeIndex = 1;

            % Reset neighbor searcher
            reset(this.NeighborSearcher);
        end

        %------------------------------------------------------------------
        function configureNeighborSearcher(this, approxSearch, connMech)

            this.NeighborSearcher = matlabshared.planning.internal.createNeighborSearcher(...
                approxSearch, connMech);
        end

        %------------------------------------------------------------------
        function configureConnectionMechanism(this, connMechanism)

            this.NeighborSearcher.configureConnectionMechanism(...
                connMechanism);
        end

        %------------------------------------------------------------------
        function updateBufferSize(this, bufferSize)

            this.BufferSize = bufferSize;
            this.allocateBuffers();
        end

        %------------------------------------------------------------------
        function id = addNode(this, node)

            id = this.NodeIndex;

            this.NodeBuffer(id,:) = node;

            this.NodeIndex = id + 1;
        end

        %------------------------------------------------------------------
        function addEdge(this, fromId, toId)

            edgeId = this.EdgeIndex;

            this.EdgeBuffer(edgeId,:) = [fromId, toId];

            this.CostBuffer(edgeId) = this.costTo(fromId) + ...
                this.edgeCost(fromId, toId);

            this.EdgeIndex = edgeId + 1;
        end

        %------------------------------------------------------------------
        function parentId = nodeParent(this, childId)

            parentId = this.EdgeBuffer(childId-1,1);
        end

        %------------------------------------------------------------------
        function replaceParent(this, childId, newParentId)

            idx = childId-1;

            this.EdgeBuffer(idx,1) = newParentId;

            this.CostBuffer(idx) = this.costTo(newParentId) + ...
                this.edgeCost(newParentId, childId);

            if isempty(coder.target)
                this.rectifyDownstreamCosts(childId);
            else
                this.rectifyDownstreamCostsNoRecursion(childId);
            end
        end

        %------------------------------------------------------------------
        function cost = edgeCost(this, fromId, toId)

            cost = this.NeighborSearcher.distance(...
                this.NodeBuffer(fromId,:), this.NodeBuffer(toId,:));
        end

        %------------------------------------------------------------------
        function cost = costTo(this, id)

            if id<2
                cost = 0;
            else
                cost = this.CostBuffer(id-1);
            end
        end

        %------------------------------------------------------------------
        function [nearestNode, nearestId] = nearest(this, node)

            [nearestNode, nearestId] = this.NeighborSearcher.nearest(...
                this.NodeBuffer, this.NodeIndex-1, node);
        end

        %------------------------------------------------------------------
        function [nearNodes, nearIds] = near(this, node)

            numNodes = this.NodeIndex-1;
            K = ceil( this.kRRT * log(numNodes + 1) );

            [nearNodes, nearIds] = this.NeighborSearcher.near(...
                this.NodeBuffer, this.NodeIndex-1, node, K);
        end

        %------------------------------------------------------------------
        function [path,totalCost] = shortestPathFromRoot(this, childId, goalNodeIds)


            coder.varsize('path', [1 this.BufferSize], [0 1]);

            % Compute shortest path
            rootId = 1;
            edgeId = max(childId - 1, 1);
            parentId = this.EdgeBuffer(edgeId, 1);

            path = [this.EdgeBuffer(edgeId, 2) parentId];

            % Growing a vector using (end+1) idiom is faster than
            % concatenation. We use this approach in simulation and
            % concatenate during code generation.
            if isempty(coder.target)
                while parentId ~= rootId
                    parentId = this.EdgeBuffer(parentId-1, 1);
                    path(end+1) = parentId;
                end
            else
                while parentId ~= rootId
                    parentId = this.EdgeBuffer(parentId-1, 1);
                    path = [path parentId]; %#ok<AGROW>
                end
            end

            path = path(end : -1 : 1);

            % Remove self-loops
            [~,repeatedGoalNodeIds] = intersect(path, goalNodeIds, 'stable');

            if ~isempty(repeatedGoalNodeIds)
                path = path( 1 : repeatedGoalNodeIds(1) );
            end

            % Find cost to childId
            totalCost = this.costTo(childId);
        end

        %------------------------------------------------------------------
        function G = toDigraph(this)

        % Create node table with poses recorded in variables X, Y and
        % Heading.
            nodes = this.Nodes;
            nodeTable = table(nodes(:,1), nodes(:,2), rad2deg(nodes(:,3)), ...
                              'VariableNames', {'X', 'Y', 'Heading'});

            % Create edge table with costs as edge weights. Note that
            % tree.Costs contains cumulative costs, not edge costs.
            edges = this.Edges;
            costs = arrayfun(@(from,to)this.edgeCost(from,to),edges(:,1),edges(:,2));
            edgeTable = table(edges, costs, 'VariableNames', ...
                              {'EndNodes', 'Weight'});

            % Create digraph object with node and edge tables
            G = digraph(edgeTable, nodeTable);
        end
    end

    %----------------------------------------------------------------------
    % Accessors
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        function nodes = get.Nodes(this)

            nodes = this.NodeBuffer(1 : this.NodeIndex-1, :);
        end

        %------------------------------------------------------------------
        function edges = get.Edges(this)

            edges = this.EdgeBuffer(1 : this.EdgeIndex-1, :);
        end

        %------------------------------------------------------------------
        function costs = get.Costs(this)

            costs = this.CostBuffer(1 : this.EdgeIndex-1);
        end
    end

    %----------------------------------------------------------------------
    % Initialization
    %----------------------------------------------------------------------
    methods (Access = private)
        %------------------------------------------------------------------
        function allocateBuffers(this)

            nodeDim     = coder.const(this.NodeDim);
            precision   = coder.const(this.Precision);

            % Allocate buffers
            this.NodeBuffer = zeros(this.BufferSize, nodeDim, precision);
            this.EdgeBuffer = zeros(this.BufferSize, 2, 'uint32');
            this.CostBuffer = zeros(this.BufferSize, 1, precision);

            % Reset indices
            this.NodeIndex = 1;
            this.EdgeIndex = 1;
        end

        %------------------------------------------------------------------
        function computeK(this)

        % Compute constant factor for number of neighbors
        % See "Sampling-based Algorithms for Optimal Motion Planning".
            stateDim = this.NodeDim-1;
            this.kRRT = this.RewireFactor * 2^(stateDim + 1) * exp(1) ...
                * (1 + 1/stateDim);
        end
    end

    %----------------------------------------------------------------------
    % Cost Management
    %----------------------------------------------------------------------
    methods (Access = private)
        %------------------------------------------------------------------
        function rectifyDownstreamCosts(this, childId)

        % Find all edges whose parent is childId
            edgeIndicesToRectify = find(this.EdgeBuffer(1 : this.EdgeIndex-1,1) == childId);

            if isempty(edgeIndicesToRectify)
                return;
            end

            % Update cost buffer for each of these
            for n = 1 : numel(edgeIndicesToRectify)
                edgeId = edgeIndicesToRectify(n);

                parentId = this.EdgeBuffer(edgeId,1);
                childId  = this.EdgeBuffer(edgeId,2);
                this.CostBuffer(edgeId) = this.costTo(parentId) + this.edgeCost(parentId,childId);

                % Recursive call to rectify costs
                % NOTE: This will terminate because there are no cycles in
                %       the tree.
                this.rectifyDownstreamCosts(childId);
            end
        end

        %------------------------------------------------------------------
        function rectifyDownstreamCostsNoRecursion(this, childId)

            numEdges = size(this.Edges,1);

            % Create a stack to hold on to successors whose costs need to
            % be updated
            stack = coder.internal.stack(childId);

            % Find top-level successors.
            for n = 1 : numEdges
                % Add successor to queue if found
                if this.Edges(n,1) == childId
                    stack = push(stack, n);
                end
            end

            while stackSize(stack) ~= 0

                % Pop edge index from stack
                [edgeId,stack] = pop(stack);

                % Update cost
                parentId = this.Edges(edgeId,1);
                childId  = this.Edges(edgeId,2);

                this.CostBuffer(edgeId) = this.costTo(parentId) + this.edgeCost(parentId, childId);

                % Find successors
                for n = 1 : numEdges
                    % Add successor to queue if found
                    if this.Edges(n,1) == childId
                        stack = push(stack, n);
                    end
                end
            end

        end
    end

    %----------------------------------------------------------------------
    % Code Generation
    %----------------------------------------------------------------------
    methods (Static, Hidden)
        %------------------------------------------------------------------
        function props = matlabCodegenNontunableProperties(~)
            props = {'BufferSize', 'NodeDim', 'Precision', 'RewireFactor', 'kRRT'};
        end
    end
end
