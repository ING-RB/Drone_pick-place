function [TF,P] = isLocalExtrema2(A,isMin,varargin)
%isLocalExtrema2 Detects local extrema in 2D data
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2023 The MathWorks, Inc.
is2D = true;
[~, maxNumExtrema, minSep, minProm, flatType, samplePoints, ~, pwin] = ...
    matlab.internal.math.parseLocalExtremaInputs(A, is2D, varargin{:});

% Quick return for empty inputs
if isempty(A)
    TF = false(size(A));
    if issparse(A)
        TF = sparse(TF);
    end

    if nargout == 2
        P = zeros(size(A),getProminenceType(A));
        if issparse(A)
            P = sparse(P);
        end
    end
    return
end

if isempty(samplePoints{1}) & isempty(samplePoints{2})
    % Generate default sample points
    samplePoints{1} = 1:size(A,1);
    samplePoints{2} = 1:size(A,2);
    notDefaultSamplePoints = false;
else
    notDefaultSamplePoints = true;
end

% Try to convert samplePoints and Pwin to doubles
% 64-bit integers that would lose precision are returned as uint64s
inclusiveUpperBound = false(2,1);
[samplePoints{1},pwin{1},inclusiveUpperBound(1)] = castAndFormatSamplePointsAndPwin(samplePoints{1},pwin{1});
[samplePoints{2},pwin{2},inclusiveUpperBound(2)] = castAndFormatSamplePointsAndPwin(samplePoints{2},pwin{2});

if notDefaultSamplePoints
    diffRowSP= diff(samplePoints{1});
    % Check for strict uniformity
    rowSPUniform = isempty(diffRowSP) || all(diffRowSP == diffRowSP(1));
    diffColSP= diff(samplePoints{2});
    colSPUniform = isempty(diffColSP) || all(diffColSP == diffColSP(1));
    samplePointsAreUniform = rowSPUniform && colSPUniform;
else
    % Default sample points are always uniform
    samplePointsAreUniform = true;
end

if nargout == 2
    needsProminence = true;
else
    needsProminence = minProm > 0 || isscalar(minSep) || minSep{1} > 0 || minSep{2} > 0 || maxNumExtrema ~= inf;
end

if ismatrix(A)
    if nargout == 2 % prominence output needed
        [TF,P] = computeLocalExtrema(A, needsProminence, isMin, ...
            maxNumExtrema, minSep, minProm, flatType, samplePoints, ...
            samplePointsAreUniform, pwin, inclusiveUpperBound);
    else
        TF = computeLocalExtrema(A, needsProminence, isMin, ...
            maxNumExtrema, minSep, minProm, flatType, samplePoints, ...
            samplePointsAreUniform, pwin, inclusiveUpperBound);
    end
else % loop over pages
    TF = false(size(A));
    [~,~,numPages] = size(A);
    if nargout == 2 % prominence output needed
        P = zeros(size(A),getProminenceType(A));
        for page = 1:numPages
            [TF(:,:,page),P(:,:,page)] = computeLocalExtrema(A(:,:,page), ...
                needsProminence,isMin,maxNumExtrema, minSep, minProm, flatType, ...
                samplePoints, samplePointsAreUniform, pwin, inclusiveUpperBound);
        end
    else
        for page = 1:numPages
            TF(:,:,page) = computeLocalExtrema(A(:,:,page), ...
                needsProminence,isMin,maxNumExtrema, minSep, minProm, flatType, ...
                samplePoints, samplePointsAreUniform, pwin, inclusiveUpperBound);
        end
    end
end
end

%--------------------------------------------------------------------------
function [TF,P] = computeLocalExtrema(A, needsProminence, isMin, ...
    maxNumExtrema, minSep, minProm, flatType, samplePoints, ...
    samplePointsAreUniform, pwin, inclusiveUpperBound)

minSepGiven = isscalar(minSep) || minSep{1} > 0 || minSep{2} > 0;
maxNumExtremaGiven = maxNumExtrema < inf;

% Detect extrema
[extremaLinearIndices,isEdge] = findExtrema(A,isMin,minSepGiven);
extremaSubs = getExtremaSubs(extremaLinearIndices,size(A,1));

if needsProminence || matches(flatType,"center")
    [indexCentroids,plateauRadii] = calculateCentroidsAndRadii(extremaSubs,minSepGiven,isscalar(minSep));
end

if needsProminence
    [P,extremaProminence] = calculateProminence(A,extremaLinearIndices, ...
        extremaSubs,indexCentroids,samplePoints,pwin,inclusiveUpperBound,isMin);
end

if minProm > 0
    % Remove any single point extrema or plateaus from their respective
    % lists if their prominence is too low
    extremaToRemove = extremaProminence < minProm;
    extremaLinearIndices(extremaToRemove) = [];
    extremaSubs(:,extremaToRemove) = [];
    extremaProminence(extremaToRemove) = [];
    indexCentroids(:,extremaToRemove) = [];
    if minSepGiven
        plateauRadii(:,extremaToRemove) = [];
        isEdge(extremaToRemove) = [];
    end
end

if minSepGiven || maxNumExtremaGiven
    % Both these options require extrema sorted by prominence
    [~,ind] = sort(extremaProminence,"descend");
    extremaLinearIndices = extremaLinearIndices(ind);
    extremaSubs = extremaSubs(:,ind);
    indexCentroids = indexCentroids(:,ind);
    if minSepGiven
        plateauRadii = plateauRadii(:,ind);
        isEdge = isEdge(ind);
    end
end

if minSepGiven && ~isscalar(extremaLinearIndices)
    extremaToRemove = filterByMinSep(extremaSubs, isEdge, indexCentroids, plateauRadii, minSep, samplePoints);
    extremaSubs(:,extremaToRemove) = [];
    extremaLinearIndices(extremaToRemove) = [];
    indexCentroids(:,extremaToRemove) = [];
end

if maxNumExtremaGiven
    numExtrema = min(maxNumExtrema,numel(extremaLinearIndices));
else
    numExtrema = numel(extremaLinearIndices);
end

% Create output logical array
if issparse(A)
    TF = sparse([],[],false,size(A,1),size(A,2));
else
    TF = false(size(A));
end

switch flatType
    case "all"
        for n = 1:numExtrema
            TF(extremaLinearIndices{n}) = true;
        end
    case "center"
        if samplePointsAreUniform
            for n = 1:numExtrema
                TF(indexCentroids(1,n),indexCentroids(2,n)) = true;
            end
        else
            % Potentially non-uniform sample points
            for n = 1:numExtrema
                % Find the centroid in terms of sample points
                rows = extremaSubs{1,n};
                if isinteger(samplePoints{1})
                    centroidRow = intMean(samplePoints{1}(rows));
                else
                    centroidRow = mean(samplePoints{1}(rows));
                end
                cols = extremaSubs{2,n};
                if isinteger(samplePoints{2})
                    centroidCol = intMean(samplePoints{2}(cols));
                else
                    centroidCol = mean(samplePoints{2}(cols));
                end

                % Find the nearest sample point to the centroid
                [~,row] = min(abs(centroidRow-samplePoints{1}));                
                [~,col] = min(abs(centroidCol-samplePoints{2}));

                TF(row,col) = true;
            end
        end
    case "first"
        for n = 1:numExtrema
            ind = extremaLinearIndices{n}(1);
            TF(ind) = true;
        end
end
end

%--------------------------------------------------------------------------
function [samplePoints,pwin,inclusiveUpperBound] = castAndFormatSamplePointsAndPwin(samplePoints,pwin)
if isnumeric(samplePoints)
    if (~isa(samplePoints,"int64") && ~isa(samplePoints,"uint64")) || ...
            max(abs(samplePoints)) <= flintmax
        % x{1} can be converted to double without loss of precision
        samplePoints = double(samplePoints);
    elseif isa(samplePoints,'int64')
        samplePoints = matlab.internal.math.convertToUnsignedWithSameSpacing(samplePoints);
    end
elseif isduration(samplePoints)
    samplePoints = milliseconds(samplePoints);
else % isdatetime(samplePoints)
    samplePoints = milliseconds(samplePoints - mean(samplePoints));
end

% samplePoints are guaranteed to be doubles or uint64s from this point on

if isempty(pwin)
    inclusiveUpperBound = true; % This value will be unused
else
    [pwin, inclusiveUpperBound] = matlab.internal.math.convertAndSplitWindow(pwin,samplePoints);
end
end

%--------------------------------------------------------------------------
function  [extremaLocations, isEdge] = findExtrema(A,isMin,detectEdges)
m = size(A,1);
n = size(A,2);

isExtrema = true(size(A));
isExtrema(:,1) = false;
isExtrema(:,end) = false;

if isMin
    comp = @gt;
else
    comp = @lt;
end

s = zeros(3*(n-1)*(m-1)+n,1); % Initialize to the maximum possible number of neighbor connections
t = zeros(3*(n-1)*(m-1)+n,1);

count = 1;

for jj = 2:n
    isExtrema(1,jj) = false;
    for ii = 2:m
        currentValue = A(ii,jj);
        currentLinearIndex = m*(jj-1)+ii;
        if ~isfinite(currentValue)
            isExtrema(ii,jj) = comp(0, currentValue); 
            % Always false when currentValue is NaN. Otherwise currentValue
            % must be inf or -inf.
            continue
        end

        % North
        northNeighbor = A(ii-1,jj);
        if comp(currentValue, northNeighbor)
            isExtrema(ii,jj) = false;
        elseif comp(northNeighbor, currentValue)
            isExtrema(ii-1,jj) = false;
        elseif currentValue == northNeighbor
            s(count) = currentLinearIndex;
            t(count) = currentLinearIndex - 1;
            count = count + 1;
        end

        % North-West
        northWestNeighbor = A(ii-1,jj-1);
        if comp(currentValue, northWestNeighbor)
            isExtrema(ii,jj) = false;
        elseif comp(northWestNeighbor, currentValue)
            isExtrema(ii-1,jj-1) = false;
        elseif currentValue == northWestNeighbor
            s(count) = currentLinearIndex;
            t(count) = currentLinearIndex - m - 1;
            count = count + 1;
        end

        % West
        westNeighbor = A(ii,jj-1);
        if comp(currentValue, westNeighbor)
            isExtrema(ii,jj) = false;
        elseif comp(westNeighbor, currentValue)
            isExtrema(ii,jj-1) = false;
        elseif currentValue == westNeighbor
            s(count) = currentLinearIndex;
            t(count) = currentLinearIndex - m;
            count = count + 1;
        end

        if ii < m
            % South-West
            southWestNeighbor = A(ii+1,jj-1);
            if comp(currentValue, southWestNeighbor)
                isExtrema(ii,jj) = false;
            elseif comp(southWestNeighbor, currentValue)
                isExtrema(ii+1,jj-1) = false;
            elseif currentValue == southWestNeighbor
                s(count) = currentLinearIndex;
                t(count) = currentLinearIndex - m + 1;
                count = count + 1;
            end
        end
    end
    isExtrema(end,jj) = false;
end

if count > 1
    % This branch is entered if multiple adjacent elements in A have the
    % same value

    % Conver the lists of "connected" elements - i.e. adjacent elements
    % with the same value - into a list of numbered plateaus. Note that
    % single element extrema are each given their own plateau number.
    d = digraph(s(1:count-1),t(1:count-1),[],numel(A));
    plateauNumbers = conncomp(d, "Type", "weak");

    % Check if there is any element in each plateau that is not an extremum
    isPlateauExtremum = accumarray(plateauNumbers(:), ~isExtrema(:)) == 0;

    % Create a sorted list of plateaus that contain only extrema
    elementsToKeep = find(isPlateauExtremum(plateauNumbers));
    plateauNumbers = plateauNumbers(elementsToKeep);
    [plateauNumbers, ind] = sort(plateauNumbers);
    elementsToKeep = elementsToKeep(ind);

    % Extract the elements of the extrema plateaus and put them in a cell
    % array
    blocksize = accumarray(plateauNumbers(:), 1);
    blocksize(blocksize == 0) = []; % Remove any block of size zero - these are the ones we deleted above
    extremaLocations = mat2cell(elementsToKeep(:)', 1, blocksize);
else
    % This branch is entered if there are no plateaus - there are either no
    % extrema in the data or all the extrema are single points
    extremaIndices = find(isExtrema);
    extremaLocations = num2cell(extremaIndices);
end

if detectEdges
    if count > 1
        % Compute how many of an extremum's neighbors have the same value
        % as it
        plateauElementDegrees = indegree(d,elementsToKeep) + outdegree(d,elementsToKeep);
        % Any extremum with fewer than 8 neighbors of the same value must be
        % either a single element extremum or the edge of a plateau
        isEdge = mat2cell(plateauElementDegrees(:)' < 8, 1, blocksize);
    else
        isEdge = repmat({true},size(extremaLocations));
    end
else
    isEdge = {};
end
end

%--------------------------------------------------------------------------
function extremaSubs = getExtremaSubs(extremaLinearIndices,numRows)
% extremaSubs holds the subscripts (row and column indices) for the points
% in each extrema
% extremaSubs{1,n} holds the row indices for the nth extrema
% extremaSubs{2,n} holds the column indices for the nth extrema

numExtrema = numel(extremaLinearIndices);
extremaSubs = cell(1,numExtrema);
for ii = 1:numExtrema
    zeroBasedInd = extremaLinearIndices{ii} - 1;
    % Find row indices
    extremaSubs{1,ii} = mod(zeroBasedInd,numRows) + 1;

    % Find column indices
    extremaSubs{2,ii} = floor(zeroBasedInd/numRows) + 1;
end
end

%--------------------------------------------------------------------------
function boundingBox = getBoundingBoxes(extremaSubs)
% boundingBox holds the coordinates of the smallest rectangle that
% encloses each extremum
% The rows of boundingBox contain (in order): lowest row, highest row,
% lowest column, highest column
numExtrema = size(extremaSubs,2);
boundingBox = zeros(4,numExtrema);
for ii = 1:numExtrema
    rows = extremaSubs{1,ii};
    cols = extremaSubs{2,ii};
    if isscalar(rows)
        boundingBox(:,ii) = [rows; rows; cols; cols];
    else
        % Elements in extremaSubs are sorted by linear index, which is
        % equivalent to being sorted by column index with ties broken by
        % column index
        boundingBox(:,ii) = [min(rows); max(rows); cols(1); cols(end)];
    end
end
end

%--------------------------------------------------------------------------
function [indexCentroids,plateauRadii] = calculateCentroidsAndRadii(extremaSubs,minSepGiven,euclideanDistance)
numExtrema = size(extremaSubs,2);
indexCentroids = zeros(2,numExtrema);
if minSepGiven && euclideanDistance
    % Keep track of the Euclidean distance from the centroid to the most
    % distant point
    plateauRadii = zeros(1,numExtrema);
else
    % Keep track of the distance in the rows and columns directions between
    % the centroid and the most distant point
    plateauRadii = zeros(2,numExtrema);
end


if minSepGiven
    % Keep track of radii
    for ii = 1:numExtrema
        indexCentroids(1,ii) = floor(mean(extremaSubs{1,ii}));
        indexCentroids(2,ii) = floor(mean(extremaSubs{2,ii}));
        if euclideanDistance
            distancesSquared = (extremaSubs{1,ii}-indexCentroids(1,ii)).^2 + (extremaSubs{2,ii}-indexCentroids(2,ii)).^2;
            plateauRadii(ii) = sqrt(max(distancesSquared));
        else
            plateauRadii(:,ii) = [max(abs(extremaSubs{1,ii}-indexCentroids(1,ii))), max(abs(extremaSubs{2,ii}-indexCentroids(2,ii)))];
        end
    end
else
    for ii = 1:numExtrema
        if isscalar(extremaSubs{1,ii})
            indexCentroids(1,ii) = extremaSubs{1,ii};
            indexCentroids(2,ii) = extremaSubs{2,ii};
        else
            indexCentroids(1,ii) = floor(mean(extremaSubs{1,ii}));
            indexCentroids(2,ii) = floor(mean(extremaSubs{2,ii}));
        end
    end
end
end

%--------------------------------------------------------------------------
function [P,extremaProminence] = calculateProminence(A,extremaLinearIndices, ...
    extremaSubs,indexCentroid,samplePoints,pwin,inclusiveUpperBound,isMin)
numExtrema = numel(extremaLinearIndices);
boundingBox = getBoundingBoxes(extremaSubs);

extremaHeights = zeros(1,numExtrema,"like",A);
for ii = 1:numExtrema
    extremaHeights(ii) = A(extremaLinearIndices{ii}(1));
end

if isMin
    % For minima, the prominence is calculated relative to the smallest of
    % the quadrant maxima (min of max)
    innerFun = @max;
    outerFun = @min;
else
    % For maxima, the prominence is calculated relative to the largest of
    % the quadrant minima (max of min)
    innerFun = @min;
    outerFun = @max;
end

PIsTheSameTypeAsA = isfloat(A) || cast(-1,"like",A) ~= -1; % Floats and unsigned integers

% P is the prominence matrix that will be returned - each point is assigned 
% a prominence
% extremaProminence is a list of the prominence of each extrema in the same
% order as extremaLinearIndices (and extrema heights)
if PIsTheSameTypeAsA
    P = zeros(size(A),"like",A);
    extremaProminence = zeros(numExtrema,1,"like",A);
else % A is a signed integer type
    % Prominence will be returned as an unsigned integer
    unsignedType = getProminenceType(A);
    P = zeros(size(A),unsignedType);
    extremaProminence = zeros(numExtrema,1,unsignedType);
    % Convert heights to unsigned integers
    % This conversion takes a values x and returns x - intmin('like',x) in
    % an unsigned type
    extremaHeights = matlab.internal.math.convertToUnsignedWithSameSpacing(extremaHeights);
end

for ii = 1:numExtrema
    % Find the rectangle around extremum ii that will be used to calculate
    % the prominence
    prominenceBox = getProminenceBox(ii,extremaHeights,boundingBox,samplePoints,pwin,inclusiveUpperBound,isMin,size(A));

    % Extract the prominence basis from the quadrants of prominenceBox
    % relative to indexCentroid
    N = prominenceBox(1):indexCentroid(1,ii);
    S = indexCentroid(1,ii):prominenceBox(2);
    E = indexCentroid(2,ii):prominenceBox(4);
    W = prominenceBox(3):indexCentroid(2,ii);

    % North-West quadrant
    NW = innerFun(A(N,W),[],"all");

    % North-East quadrant
    NE = innerFun(A(N,E),[],"all");

    % South-East quadrant
    SE = innerFun(A(S,E),[],"all");

    % South-West quadrant
    SW = innerFun(A(S,W),[],"all");

    prominenceBasis = outerFun([NW NE SE SW]);
    if prominenceBasis == extremaHeights(ii)
        % The current extremum was the only thing in the prominence box
        prominenceBasis = zeros('like',A);
    end

    if ~PIsTheSameTypeAsA
        % Convert prominenceBasis to match the type and offset of prominenceHeights
        prominenceBasis = matlab.internal.math.convertToUnsignedWithSameSpacing(prominenceBasis);
    end

    if prominenceBasis > extremaHeights(ii)
        currentP = prominenceBasis - extremaHeights(ii);
    else
        currentP = extremaHeights(ii) - prominenceBasis;
    end

    extremaProminence(ii) = currentP;
    P(extremaLinearIndices{ii}) = currentP;
end
end

%--------------------------------------------------------------------------
function prominenceBox = getProminenceBox(extremumIndex,extremaHeights,boundingBox,samplePoints,pwin,inclusiveUpperBound,isMin,sizeA)
% Returns the box surrounding extremum extremumIndex that is bounded by more higher (for
% maxima) or lower (for minima) extrema

% lower row index, higher row index, lower column index, higher column index
currentBound = boundingBox(:,extremumIndex);

% remove extrema that will not influence the prominence box
if isMin
    extremaToInclude = extremaHeights < extremaHeights(extremumIndex);
else
    extremaToInclude = extremaHeights > extremaHeights(extremumIndex);
end
extremaToInclude(extremumIndex) = false; % Remove the current extrema

extremaBoundsToUse = boundingBox(:,extremaToInclude);
rowBounds = extremaBoundsToUse(1:2,:);
colBounds = extremaBoundsToUse(3:4,:);

if isempty(pwin{1}) % if pwin{1} is empty, so is pwin{2}
    % No prominence window input - include edges of data as possible bounds
    rowBounds = rowBounds(:);
    colBounds = colBounds(:);
    rowBounds = [rowBounds; 1; sizeA(1)];
    colBounds = [colBounds; 1; sizeA(2)];
else
    % Prominence window specified
    % Note that samplePoints and pwin are guaranteed to be doubles or 64-bit
    % integers

    pwinMin = zeros(2,1);
    pwinMax = pwinMin;
    boundCounter = 1;
    for dim = 1:2
        pwinMin(dim) = find(samplePoints{dim} >= samplePoints{dim}(currentBound(boundCounter))-pwin{dim}(1),1);
        boundCounter = boundCounter + 1;
        if inclusiveUpperBound(dim)
            pwinMax(dim) = find(samplePoints{dim} <= samplePoints{dim}(currentBound(boundCounter))+pwin{dim}(2),1,'last');
        else
            pwinMax(dim) = find(samplePoints{dim} <  samplePoints{dim}(currentBound(boundCounter))+pwin{dim}(2),1,'last');
        end
        boundCounter = boundCounter + 1;
    end
    
    % Only keep extrema that are in the window
    % To avoid skipping large plateaus, only check that the upper bounds
    % are lower and the lower bounds are higher
    extremaInWindow = (rowBounds(1,:)>=pwinMin(1) & rowBounds(2,:)<=pwinMax(1)) & ...
                      (colBounds(1,:)>=pwinMin(2) & colBounds(2,:)<=pwinMax(2));
    rowBounds = reshape(rowBounds(:,extremaInWindow),[],1);
    colBounds = reshape(colBounds(:,extremaInWindow),[],1);

    rowBounds = [rowBounds; pwinMin(1); pwinMax(1)];
    colBounds = [colBounds; pwinMin(2); pwinMax(2)];
end

prominenceBox = currentBound;

% Lower bounds can only be coincident with the current extremum if there
% are no other potential bounds

potentialLowerRowBounds = rowBounds < currentBound(1);
if ~isempty(potentialLowerRowBounds) && any(potentialLowerRowBounds)
    prominenceBox(1) = max(rowBounds(potentialLowerRowBounds));
end

potentialLowerColBounds = colBounds < currentBound(3);
if ~isempty(potentialLowerColBounds) && any(potentialLowerColBounds)
    prominenceBox(3) = max(colBounds(potentialLowerColBounds));
end

prominenceBox(2) = min(rowBounds(rowBounds >= currentBound(2)));
prominenceBox(4) = min(colBounds(colBounds >= currentBound(4)));
end

%--------------------------------------------------------------------------
function extremaToRemove = filterByMinSep(extremaSubs, isEdge, indexCentroids, plateauRadii, minSep, x)
if isscalar(minSep)
    % Convert sample points to doubles to calculate the Euclidean distance
    % x{1} and x{2} must be uint64 if they are not double
    for ii = 1:2
        if ~isa(x{ii},'double') 
            x{ii} = double(x{ii}-x{ii}(1)); % Shift the values towards 0 before casting to minimize precision loss
        end
    end
    if x{1}(end) > sqrt(realmax) || x{2}(end) > sqrt(realmax)
        % Scale sample points and  minSep if distance calculation could
        % exceed the capacity of doubles
        scaleFactor = max(x{1}(end),x{2}(end));
        x{1} = x{1}/scaleFactor;
        x{2} = x{2}/scaleFactor;
        minSep = minSep/scaleFactor;
    end
end

numExtrema = size(extremaSubs,2);
extremaToRemove = false(numExtrema,1);
useEuclideanDist = isscalar(minSep);
anyIntSP = isinteger(x{1}) || isinteger(x{2});

for ii = 1:numExtrema
    if ~extremaToRemove(ii)
        % Extract the sample points for the edges of extrema ii
        rows1 = x{1}(extremaSubs{1,ii}(isEdge{ii}));
        cols1 = x{2}(extremaSubs{2,ii}(isEdge{ii}));
         for jj = ii + 1:numExtrema
             if ~extremaToRemove(jj)
                 if useEuclideanDist
                     % Estimate the distance between ii and jj using their
                     % centroids and radii (this is a conservative estimate)
                     minDist = sqrt(sum((indexCentroids(:,ii)-indexCentroids(:,jj)).^2)) - plateauRadii(ii) - plateauRadii(jj);
                     % No further checks are needed if the estiate is
                     % greater than minSep
                     checkPoints = minDist <= minSep;
                 else
                     minDist = abs(indexCentroids(:,ii)-indexCentroids(:,jj)) - plateauRadii(:,ii) - plateauRadii(:,jj);
                     checkPoints = minDist(1) <= minSep{1} && minDist(2) <= minSep{2};
                 end

                 if checkPoints
                     % Extract the sample points for the edges of extrema jj
                     rows2 = x{1}(extremaSubs{1,jj}(isEdge{jj}));
                     cols2 = x{2}(extremaSubs{2,jj}(isEdge{jj}));
    
                     % Exhaustively check distance between edge points of extrema
                     if useEuclideanDist
                         extremaToRemove(jj) = euclideanDist(rows1, cols1, rows2, cols2, minSep);
                     elseif anyIntSP
                         extremaToRemove(jj) = rowAndColIntDist(rows1, cols1, rows2, cols2, minSep);
                     else
                         extremaToRemove(jj) = rowAndColDist(rows1, cols1, rows2, cols2, minSep);
                     end
                 end
             end
         end
    end
end
end

%--------------------------------------------------------------------------
function tf = euclideanDist(rows1, cols1, rows2, cols2, minSep)
minSepSquared = minSep^2;
tf = false;
for ii = 1:numel(rows1)
    for jj = 1:numel(rows2)
        if (rows1(ii)-rows2(jj))^2+(cols1(ii)-cols2(jj))^2 < minSepSquared
            tf = true;
            return
        end
    end
end
end

%--------------------------------------------------------------------------
function tf = rowAndColDist(rows1, cols1, rows2, cols2, minSep)
tf = false;
for ii = 1:numel(rows1)
    for jj = 1:numel(rows2)
        if abs(rows1(ii)-rows2(jj))<minSep{1} && abs(cols1(ii)-cols2(jj))<minSep{2}
            tf = true;
            return
        end
    end
end
end

%--------------------------------------------------------------------------
function tf = rowAndColIntDist(rows1, cols1, rows2, cols2, minSep)
tf = false;
for ii = 1:numel(rows1)
    currentRow1 = rows1(ii);
    currentCol1 = cols1(ii);
    for jj = 1:numel(rows2)
        currentRow2 = rows2(jj);
        currentCol2 = cols2(jj);
        if currentRow1 < currentRow2
            rowDist = currentRow2-currentRow1;
        else
            rowDist = currentRow1-currentRow2;
        end
        if currentCol1 < currentCol2
            colDist = currentCol2-currentCol1;
        else
            colDist = currentCol1-currentCol2;
        end
        if rowDist < minSep{1} && colDist < minSep{2}
            tf = true;
            return
        end
    end
end
end

%--------------------------------------------------------------------------
function out = intMean(x)
n = numel(x);
dividendAccum = zeros('like',x);
remainderAccum = dividendAccum;
for ii = 1:n
    currentRemainder = mod(x(ii),n);
    remainderAccum = remainderAccum + currentRemainder;
    dividendAccum = dividendAccum + (x(ii) - currentRemainder)/n;
end
out = dividendAccum + remainderAccum/n;
end

%--------------------------------------------------------------------------
function pType = getProminenceType(A)
% Prominence is returned as either a float or an unsigned integer
if isfloat(A) || cast(-1,"like",A) ~= -1
    pType = class(A);
    return
end
if isa(A,"int8")
    pType = "uint8";
elseif isa(A,"int16")
    pType = "uint16";
elseif isa(A,"int32")
    pType = "uint32";
else % isa(A,"int64")
    pType = "uint64";
end
end