function paY = keyindexslices(paX, paXIdx, paYIdx, varargin)
%KEYINDEXSLICES Perform a keyed indexing operation. This is similar to
% numeric subsref, but where you can replace 1:size(X,1) with sorted indices.
%
% Syntax:
%   paY = keyindexslices(paX, paXIdx, paYIdx) reorders paX, using paXIdx
%   as the source location and paYIdx as the destination location. If
%   paYIdx(n,:) is equal to paXIdx(m,:), then paY(n,:) will also be
%   equal to paX(m,:).
%
%   paY = keyindexslices(...,name1,value1,...) specifies one or more options:
%
%   XPartitionBoundaries: For performance reasons, if the caller already has
%   the first slice of X after the start of each partition (or the next
%   partition in-case of empty), they can avoid an extra pass by providing
%   it directly.
%
%   MissingIdxError: The action to be applied if a key in paYIdx does
%   not exist in paXIdx. This can be an error message ID, a message object
%   or a nullary function that issues an error. If unspecified, the default
%   is to assert.
%
%   DuplicateIdxError: The action to be applied if a key in paXIdx
%   contains duplicates.  This can be an error message ID, a message object
%   or a nullary function that issues an error. If unspecified, this will
%   not be checked.
%

%   Copyright 2017-2019 The MathWorks, Inc.

% To document the algorithm, each pass below will describe how it acts on a
% given example assuming the indices are just slice index of X. This example will be:
%
%   X     Idx
%   A      3 |
%   B      5 | Partition 1
%   C        |
%  ---    ---
%   E      3 |
%   F      1 | Partition 2
%   G        |
%

pnames = {'XPartitionBoundaries', 'MissingIdxError', 'DuplicateIdxError'};
dflts =  {                    [],                [],                  []};
[xPartitionBoundaries, opts.MissingIdxError, opts.DuplicateIdxError, supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
opts.MissingIdxError = matlab.bigdata.internal.util.getErrorFunction(opts.MissingIdxError, ...
    @() error('Assertion failed: Missing X key during keyindexslices.') );
opts.DuplicateIdxError = matlab.bigdata.internal.util.getErrorFunction(opts.DuplicateIdxError, ...
    @() error('Assertion failed: Duplicate X key during keyindexslices.'));
if supplied.DuplicateIdxError
    opts.DuplicateIdxError = matlab.bigdata.internal.util.getErrorFunction(opts.DuplicateIdxError);
end

wasPartitionIndependent = isPartitionIndependent(paX, paXIdx, paYIdx);

% Pass 1. Get the partition boundaries of X and form necessary pieces of metadata
% about X. This is needed to map requested indices to the right partition of X.
%
% Each partition boundary will be the first slice of data after the start
% of each partition. If a partition is empty, the first slice of data will
% come from the subsequent partitions.
%
% For the example, we know partition sizes to be [3,3]. I.e. indices 1:3
% refer to partition 1 of X and indices 4:6 refer to partition 2 of X.
if ~supplied.XPartitionBoundaries
    xPartitionBoundaries = iGetPartitionBoundaries(paXIdx);
end
xPartitionBoundaries = matlab.bigdata.internal.broadcast(xPartitionBoundaries);

% Pass 2. Build an optimized array of requested indices from Idx. Then
% repartition to put each requested index alongside the same partition of X
% as where the corresponding slice can be found.
%
% For the example, pass 2 does the following transformations:
%
%  Idx        ReqIdx XPart IdxPart        ReqIdx XPart IdxPart
%   3    Add    3      1      1             3      1      1
%   5 Partition 5      2      1 Repartition 3      1      2
%      Indices                     to X     1      1      2
%  ---   ->    -----------------    ->     ------------------
%   3           3      1      2             5      2      1
%   1           1      1      2
%
[paReqIndices, paXPartIndices, paYPartIndices] ...
    = iBuildRequestIndexTuples(paYIdx, xPartitionBoundaries, opts);
[paReqIndices, paYPartIndices] ...
    = repartition(paX.PartitionMetadata, paXPartIndices, ...
    paReqIndices, paYPartIndices);

% Pass 3. Map each requested index to its corresponding slice of data. Then
% repartition that information back to the partitioning of Idx.
%
% For the example, pass 3 does the following transformations on the output
% of pass 2:
%
%  ReqIdx IdxPart       ReqIdx IdxPart ReqSlice       ReqIdx IdxPart ReqSlice
%    3       1   Unique   1       2       A             3       1       C
%    3       2     per    3       1       C Repartition 5       1       F
%    1       2  Partition 3       2       C   to Idx
%   ------------   ->    -------------------    ->     -------------------
%    5       1  Then get  5       5       F             1       2       A
%               Slice of                                3       2       C
%               X per row
%
% Note that the output ReqIdx is not in the same order as Idx. This is ok
% as <ReqIdx, ReqSlice> for each partition will used as a random access map.
[paReqIndices, paReqSlices, paYPartIndices] = iMapReqIndicesToData(...
    paX, paXIdx, paReqIndices, paYPartIndices, opts);
[paReqIndices, paReqSlices] ...
    = repartition(paYIdx.PartitionMetadata, paYPartIndices, ...
    paReqIndices, paReqSlices);

% Pass 4. Build the output Y.
%
% For the example, pass 4 uses the output of pass 3 to map index to output
% slice:
%
%  Idx            Y
%   3             C
%   5  Map index  F
%      to slice
%  ---    ->     ---
%   3             C
%   1             A
%
paY = iBuildOutput(paYIdx, paReqIndices, paReqSlices);

% The framework will assume out is partition dependent because it is
% derived from partitionfun/generalpartitionfun. It is not, so we must
% correct this.
if wasPartitionIndependent
    paY = markPartitionIndependent(paY);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pass 1. Get the partition sizes of X and form necessary pieces of metadata
%          about X.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function partitionBoundaries = iGetPartitionBoundaries(paYIdx)
% Get the partition boundaries by retrieving the first slice of each
% partition.
[partitionBoundaries, partitionIndices] = partitionfun(@iGetFirstSliceImpl, paYIdx);
partitionBoundaries = clientfun(@iBuildPartitionBoundaries, partitionBoundaries, partitionIndices);
end

function [isFinished, firstIndex, partitionIndex] = iGetFirstSliceImpl(info, indices)
% Get the first slice of a partition returning it in a cell.
import matlab.bigdata.internal.util.indexSlices;
assert(info.RelativeIndexInPartition == 1, ...
    'Expected to only be invoked at the beginning of a partition.');
if size(indices,1) > 0
    isFinished = true;
    firstIndex = {indexSlices(indices, 1)};
    partitionIndex = [info.PartitionId, info.NumPartitions];
elseif info.IsLastChunk
    isFinished = true;
    firstIndex = {indexSlices(indices, [])};
    partitionIndex = [info.PartitionId, info.NumPartitions];
else
    isFinished = false;
    firstIndex = cell(0,1);
    partitionIndex = zeros(0, 2);
end
end

function partitionBoundaries = iBuildPartitionBoundaries(idx, partitionIndices)
% 
numPartitions = partitionIndices(1, 2);
newIdx = cell(numPartitions, 1);
newIdx(partitionIndices(:, 1)) = idx;
% Combine a cell array of first slices with special handing for empty
% partitions.
carryOver = newIdx{end};
for ii = numel(newIdx)-1:-1:1
    if size(newIdx{ii}, 1) == 0
        newIdx{ii} = carryOver;
    else
        carryOver = newIdx{ii};
    end
end
partitionBoundaries = vertcat(newIdx{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pass 2 Implementation: Build an optimized array of requested indices.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [paReqIndices, paXPartIndices, paYPartIndices] ...
    = iBuildRequestIndexTuples(paYIdx, xPartitionBoundaries, opts)
% Build an optimized array of requested index tuples to retrieve from X.
% Each tuple is of the form:
% <requested index of X, partition of X, destination partition of Idx>

% a. Attempt to optimize the number of indices communicated by removing
% the easy to find duplicates. All remaining duplicates will be removed
% during the sort/unique per partition applied by pass 3.
paReqIndices = chunkfun(@(idx) unique(idx, 'rows'), paYIdx);

% b. Split the indices into partition index and relative index in partition.
% We need the partition index in order to know where to send the request
% for this index.
paXPartIndices = slicefun(@(idx, boundaries) iDiscretizeIdxImpl(idx, boundaries, opts), paReqIndices, xPartitionBoundaries);
paYPartIndices = iGetPartitionIndices(paReqIndices);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function paPartitionIndices = iGetPartitionIndices(paX)
% Form a column vector of partition indices, each value being the partition
% index to which that slice belongs.
fh = @(info, x) deal(info.IsLastChunk, info.PartitionId * ones(size(x,1),1));
paPartitionIndices = partitionfun(fh, paX);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function partIndices = iDiscretizeIdxImpl(idx, boundaries, opts)
% Discretize idx into partition indices based on a set of boundaries. This
% will error early if we detect any idx is outside the range of boundaries.
partIndices = matlab.bigdata.internal.util.discretizerows(idx, boundaries);
if any(partIndices < 1)
    opts.MissingIdxError();
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pass 3 Implementation: Map each requested index to its corresponding slice of data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [paReqIndices, paReqSlices, paYPartIndices] ...
    = iMapReqIndicesToData(paX, paXIdx, paReqIndices, paYPartIndices, opts)
% Map each requested index to its corresponding slice of data. This also
% outputs the requested indices as this part of the algorithm needs them to
% be in sorted order.

% a. Convert the requested indices map into sorted unique form. This is to
% allow (c) to be done without a random access map.
paReqPairs = slicefun(@iMuxIndices, paReqIndices, paYPartIndices);
paReqPairs = iUniqueSortPerPartition(paReqPairs);
[paReqIndices, paYPartIndices] = slicefun(@iDemuxIndices, paReqPairs);

% b. Select the rows of X that are referenced by the request. This will
% duplicate rows that are to be duplicated to two different partitions.
paReqSlices = iMapSortedIndices(paX, paXIdx, paReqIndices, opts);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x = iMuxIndices(x, indices)
% Mux the data and indices together so that we can unique/sort the two together.
if isa(x, 'double') && ismatrix(x)
    x = [x, indices];
elseif istable(x) || istimetable(x)
    x.Properties.DimensionNames = "Original_" + x.Properties.DimensionNames;
    x.Properties.VariableNames = "Original_" + x.Properties.VariableNames;
    x.(width(x) + 1) = indices;
else
    % Build the table up with dot subscripted assignment because the vars might
    % be char row vectors which the table constructor doesn't support.
    xT = table(); xT.PackedArray = x; xT.PartitionIndices = indices;
    x = xT;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x, indices] = iDemuxIndices(x)
% Demux the data and indices after the unique/sort.
if isnumeric(x)
    indices = x(:, end);
    x(:, end) = [];
else
    indices = x.(width(x));
    x.(width(x)) = [];
    
    if width(x) == 1 && x.Properties.VariableNames == "PackedArray"
        x = x.(1);
    else
        x.Properties.DimensionNames = extractAfter(x.Properties.DimensionNames, "Original_");
        x.Properties.VariableNames = extractAfter(x.Properties.VariableNames, "Original_");
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function paX = iUniqueSortPerPartition(paX)
% Perform a unique rows operation across each individual partition. This
% supports matrices of doubles.
fh = matlab.bigdata.internal.io.ExternalSortFunction(@matlab.bigdata.internal.util.quickSortrows);
fh = matlab.bigdata.internal.FunctionHandle(fh);
paX = partitionfun(fh, paX);

fh = matlab.bigdata.internal.util.StatefulFunction(@iUniquePerPartitionImpl);
fh = matlab.bigdata.internal.FunctionHandle(fh);
paX = partitionfun(fh, paX);
end

function [state, isFinished, x] = iUniquePerPartitionImpl(state, info, x)
% Performs a unique, assuming the data is already in sorted order because
% of ExternalSortFunction.
isFinished = info.IsLastChunk;
x = unique([state; x], 'rows');
state = [];

if ~isFinished && ~isempty(x)
    state = x(end, :);
    x(end, :) = [];
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function paY = iMapSortedIndices(paX, paXIdx, paReqIndices, opts)
% Map a column vector of sorted relative indices from the start of each
% partition to the data found at those indices.
paY = generalpartitionfun(...
    @(varargin) iMapSortedIndicesImpl(varargin{:}, opts), ...
    paX, paXIdx, paReqIndices);
end

function [isFinished, unusedInputs, y] = iMapSortedIndicesImpl(info, x, xIndices, yIndices, opts)
% Implementation of iMapSortedIndices.
import matlab.bigdata.internal.util.indexSlices;
import matlab.bigdata.internal.util.quickIsmemberRows;

numX = min(size(x,1), size(xIndices,1));

[isPresent, idx] = quickIsmemberRows(yIndices, indexSlices(xIndices, 1:numX));
assert(issorted(idx(isPresent)), ...
    'Assertion failed: paXIdx is not in sorted order');
numIdx = find(~isPresent, 1) - 1;
if isempty(numIdx)
    numIdx = size(idx, 1);
    if numIdx == 0
        numX = 0;
    else
        numX = idx(end) - 1;
    end
elseif ~info.IsLastChunk(3)
    numX = max(numX - 1, 0);
end

y = indexSlices(x, idx(1:numIdx));

unusedInputs = {indexSlices(x, numX+1:size(x,1)), ...
    indexSlices(xIndices, numX+1:size(xIndices,1)), ...
    indexSlices(yIndices, numIdx+1:size(yIndices,1))};

hasUnusedInputs = cellfun(@(c) size(c,1), unusedInputs) > 0;
isLastOfInputs = ~hasUnusedInputs & info.IsLastChunk;

% We finish when their are no more idxIndices to process.
isFinished = isLastOfInputs(3);

% There are a couple of bad states we need to protect against:
% a) idxIndices/xIndices are of different lengths. This is an implementation
%    fault.
assert(~(isLastOfInputs(1) && hasUnusedInputs(2)) || (isLastOfInputs(2) && hasUnusedInputs(1)), ...
    'Assertion failed: x and xIndices are of different length');

% b) As xIndices is guaranteed sorted, if idxIndices is smaller than xIndices then
%    there will be no xIdx that matches idxIndices. A missing key.
if hasUnusedInputs(3) && ~isempty(xIndices)
    [~, idx] = matlab.bigdata.internal.util.quickSortrows(...
        [indexSlices(xIndices, 1); indexSlices(unusedInputs{3}, 1)]);
    if idx(1) == 2
        opts.MissingIdxError();
    end
end

% c) We ran out of xIndices before idxIndices. A missing key.
if hasUnusedInputs(3) && any(isLastOfInputs(1:2))
    opts.MissingIdxError();
end

% d) There exists duplicate xIndices. This is an optional check because in
%    some use-cases, duplicate xIndices are not possible.
if ~isempty(opts.DuplicateIdxError)
    if numel(xIndices) ~= numel(unique(xIndices, 'rows'))
        opts.DuplicateIdxError();
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pass 4 Implementation: Build the output Y.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tY = iBuildOutput(paYIdx, paReqIndices, paReqSlices)
% Build the output Y using the requested slices of X.

fh = @iBuildOutputImpl;
fh = matlab.bigdata.internal.util.StatefulFunction(fh);
fh = matlab.bigdata.internal.FunctionHandle(fh);
tY = generalpartitionfun(fh, paReqIndices, paReqSlices, paYIdx);
end

function [obj, isFinished, unusedInputs, y] = iBuildOutputImpl(obj, info, reqIndices, reqSlices, idxIndices)
% Implementation of iBuildOutput.
import matlab.bigdata.internal.util.indexSlices;

if isempty(obj)
    obj.PagedMapBuilder = matlab.bigdata.internal.io.PagedRandomAccessMapBuilder(indexSlices(reqIndices, []));
    obj.PagedMap = [];
end
if isempty(obj.PagedMap)
    % The PagedMap object exploits the fact that reqIndices was left in
    % a sorted order by pass 3.
    
    % Until we've retrieved all requested <index, slice> pairs from pass 3,
    % do not start building Y just yet. The paged map must be complete
    % before use because idx can be in any order.
    obj.PagedMapBuilder.add(reqIndices, reqSlices);
    if all(info.IsLastChunk(1 : 2))
        obj.PagedMap = obj.PagedMapBuilder.build();
    else
        isFinished = false;
        unusedInputs = {indexSlices(reqIndices, []), indexSlices(reqSlices, []), idxIndices};
        y = indexSlices(reqSlices, []);
        return;
    end
end

% Once the paged map is complete, we can build Y.
isFinished = info.IsLastChunk(3);
unusedInputs = [];
y = obj.PagedMap.get(idxIndices);
end
