function [TF, P] = isLocalStencil(A, opts)
%ISLOCALSTENCIL Identify local extrema using a stencil.

% Copyright 2018-2024 The MathWorks, Inc.

import matlab.bigdata.internal.broadcast
import matlab.bigdata.internal.FunctionHandle
import matlab.bigdata.internal.util.StatefulFunction

inputClass = tall.getClass(A);
if inputClass == "table"
    % Validate the data types here to make sure we issue the correct error.
    A = lazyValidate(A, {@(B) iValidateVariableDataTypes(B, opts.DataVars), ...
        'MATLAB:isLocalExtrema:NonNumericTableVar'});
    initialSummaryState = {0, cell(1, numel(opts.DataVars))};
    opts.InputIsTabular = true;
    opts.ExtractHaloFcn = ...
        @(varargin) iExtractTabularHalo(varargin{:}, opts.DataVars);
    opts.MergeHalosFcn = @iMergeTableSummaryHalos;
    opts.InsertHalosFcn = @iInsertTabularHalos;
    opts.ApplyExtremaFcn = @iFindLocalExtremaTable;
else
    initialSummaryState = {0, []};
    opts.InputIsTabular = false;
    opts.ExtractHaloFcn = @iExtractChunkHalo;
    opts.MergeHalosFcn = @iMergeSummaryHalo;
    opts.InsertHalosFcn = @iInsertChunkHalos;
    opts.ApplyExtremaFcn = @iFindLocalExtremaArray;
end

summaryFcn = @(varargin) iSummarizePartitions(varargin{:}, opts);
summaryFunctor = FunctionHandle(StatefulFunction(summaryFcn, ...
    initialSummaryState));
summaryTable = partitionfun(summaryFunctor, A);
summaryTable.Adaptor = iMkSummaryTableAdaptor();

summaryTable = clientfun(@(t) iAdjustSliceIds(t, opts.InputIsTabular), ...
    summaryTable);
summaryTable.Adaptor = iMkSummaryTableAdaptor();

doLocalExtremaFcn = @(varargin) iFindLocalExtrema(varargin{:}, opts);
localExtremaFunctor = FunctionHandle(StatefulFunction(doLocalExtremaFcn));
[TF,P] = partitionfun(localExtremaFunctor, A, broadcast(summaryTable));

% The framework will assume TF and P are partition dependent because they
% are derived from partitionfun. They are not, so we must correct this.
[TF, P] = copyPartitionIndependence(TF, P, A);
end

%--------------------------------------------------------------------------
function [state, hasFinished, summaryTableRow] = ...
    iSummarizePartitions(state, info, A, opts)
% Summarize each partition to produce a mapping from PartitionId to the
% total number of data slices and the ordered unique halos for the
% partition.  The "ordered unique halos" are the set of closest values on
% either side of a partition once all sequentially repeated elements have
% been removed.  The number of ordered unique halos required is determined
% by opts.ProminenceWindow.

% Unpack the state cell.
[numDataSlices, halo] = state{:};

numDataSlices = numDataSlices + size(A,1);
chunkHalo = opts.ExtractHaloFcn(A, info.RelativeIndexInPartition, ...
    opts.ProminenceWindow);
halo = opts.MergeHalosFcn(halo, chunkHalo, opts.ProminenceWindow);

state = {numDataSlices, halo};
hasFinished = info.IsLastChunk;

if hasFinished
    % Final chunk - emit a table row for this partition containing the
    % total number of data slices as well as the column-wise halos.
    if ~opts.InputIsTabular
        halo = {halo};
    end
    summaryTableRow = ...
        iMakeSummaryTable(info.PartitionId, numDataSlices, halo);
else
    % Return an empty table row within the partition.
    summaryTableRow = iMakeSummaryTable([], [], {});
end
end

%--------------------------------------------------------------------------
function haloMerged = iMergeContinuousRegions(halo)
% Merge connected regions in a halo.
import matlab.bigdata.internal.util.indexSlices;
halo = sortrows(halo, {'SliceStartingIndex', 'ColIndex'});
ids = iFindOrderedUniqueElements(halo.Values);
haloMerged = indexSlices(halo, ids(:,1));
haloMerged.SliceEndingIndex = halo.SliceEndingIndex(ids(:,2));
% Compute the finite counts.
for k = 1:size(ids,1)
    idx = ids(k,1):ids(k,2);
    haloMerged.NumNonMissing(k) = sum(halo.NumNonMissing(idx));
end
end

%--------------------------------------------------------------------------
function halo = iMergeContinuousRegionsOutsideRange(halo, startId, endId)
% Go through the columns.
colIds = unique(halo.ColIndex)';
for jj = colIds
    isInThisColumn = halo.ColIndex == jj;
    % Merge rows before range.
    idxBefore = isInThisColumn & (halo.SliceEndingIndex < startId);
    merged = iMergeContinuousRegions(halo(idxBefore, :));
    halo(idxBefore,:) = [];
    halo = [halo; merged]; %#ok<AGROW> No way of knowing how many.
    % Merge rows after range.
    isInThisColumn = halo.ColIndex == jj;
    idxAfter = isInThisColumn & (halo.SliceStartingIndex > endId);
    merged = iMergeContinuousRegions(halo(idxAfter, :));
    halo(idxAfter,:) = [];
    halo = [halo; merged]; %#ok<AGROW> No way of knowing how many.
end
halo = sortrows(halo, {'SliceStartingIndex', 'ColIndex'});
end

%--------------------------------------------------------------------------
function halo = iMergeSummaryHalo(halo, chunkHalo, promWindow)
% Merge the summary halos.

halo = [halo; chunkHalo];
% Prune unnecessary rows
halo = iMergeContinuousRegions(halo);
rowMask = false(height(halo),1);
colIds = unique(halo.ColIndex)';
N = iDetermineHowManyNeighbors(promWindow);
for jj = colIds
    % Find all entries corresponding to this column.
    idx = find(halo.ColIndex == jj);
    % Keep only the first N(1) and last N(2) ordered unique slices.
    if numel(idx) > sum(N)
        idx = idx([1:N(1), (end-N(2)+1):end]);
    end
    rowMask(idx) = true; 
end
halo = halo(rowMask, :);
end

%--------------------------------------------------------------------------
function halo = iMergeTableSummaryHalos(halo, chunkHalo, promWindow)
% Merge the summary halos for table inputs.

for jj=1:numel(halo)
    halo{jj} = iMergeSummaryHalo(halo{jj}, chunkHalo{jj}, promWindow);
end
end

%--------------------------------------------------------------------------
function T = iAdjustSliceIds(T, inputIsTabular)
% Update the slice indices stored within the halo table so that the slice
% index column contains the overall partitioned array index.

offset = circshift(T.NumDataSlices, 1);
offset(1) = 0;
offset = cumsum(offset);

for ii = 2:numel(offset)
    halo = T{ii, 'ProminenceHalos'};
    
    if inputIsTabular
        for jj = 1:numel(halo)
            halo{jj}.SliceStartingIndex = halo{jj}.SliceStartingIndex + offset(ii);
            halo{jj}.SliceEndingIndex = halo{jj}.SliceEndingIndex + offset(ii);
        end
    else
        halo{:}.SliceStartingIndex = halo{:}.SliceStartingIndex + offset(ii);
        halo{:}.SliceEndingIndex = halo{:}.SliceEndingIndex + offset(ii);
    end
    
    T{ii, 'ProminenceHalos'} = halo;
end
end

%--------------------------------------------------------------------------
function [obj, hasFinished, TF, P] = iFindLocalExtrema(obj, info, A, ...
    summaryTable, opts)
% Find local extrema in a chunk using neighbor halos.

import matlab.bigdata.internal.io.ExternalInputBuffer
import matlab.bigdata.internal.util.indexSlices

if isempty(obj)
    % Use ExternalInputBuffer to read from neighboring chunks in this
    % partition.
    obj.InputBuffer = ExternalInputBuffer();
    obj.Halos = iExtractPartitionHalo(summaryTable, info.PartitionId, ...
        opts.ProminenceWindow, opts.InputIsTabular);
    obj.IsInputFinished = false;
    obj.PartitionStartIndex = iGetPartitionStartIndex(summaryTable, ...
        info.PartitionId);
    obj.BufferedIndexInPartition = 1;
end

if ~obj.IsInputFinished
    obj.InputBuffer.add(A);
    % Need to extract chunks from neighbors and merge them with the
    % neighbor partition halos.
    chunkHalo = opts.ExtractHaloFcn(A, info.RelativeIndexInPartition, ...
        opts.ProminenceWindow);
    obj.Halos = opts.InsertHalosFcn(obj.Halos, chunkHalo, ....
        obj.PartitionStartIndex);

    if info.IsLastChunk
        obj.IsInputFinished = true;
    end
end

if obj.IsInputFinished
    [hasFinished, A] = obj.InputBuffer.getnext();
    startIndex = obj.PartitionStartIndex+obj.BufferedIndexInPartition-1;
    obj.BufferedIndexInPartition = obj.BufferedIndexInPartition+size(A,1);
    [TF, P] = opts.ApplyExtremaFcn(A, opts, obj.Halos, startIndex);
else
    hasFinished = false;
    if opts.IsTabular
        P = indexSlices(A(:, opts.DataVars), []);
        for jj = 1:size(P,2)
            P.(jj) = iCorrectIntegerTypeForProminence(P.(jj));
        end        
        TF = false(0, width(A));
    else
        P = iCorrectIntegerTypeForProminence(indexSlices(A, []));
        TF = logical(indexSlices(A, []));
    end
end
end

%--------------------------------------------------------------------------
function [TF, P] = iFindLocalExtremaArray(A, opts, halos, startIndex)
% Find local extrema in an array chunk given halos from neighboring
% partitions.
szA = size(A);
numCols = prod(szA(2:end));
endIndex = startIndex + szA(1) - 1;

if startsWith(class(A), 'int')
    P = zeros(szA, ['u', class(A)]);
else
    P = zeros(szA, class(A));
end
TF = false(szA);

if isempty(A)
    % No extrema - nothing to do.
    return;
end

% Create sample points vector
N = iDetermineHowManyNeighbors(opts.ProminenceWindow);

for jj=1:numCols
    % Get the head and tail halos.
    [headHalo, tailHalo] = iGetNeighborHalos(halos, jj, ...
        [startIndex endIndex], N);
    % Avoid accidental upcasting to double because of [].
    if islogical(A)
        headHalo.Values = logical(headHalo.Values);
        tailHalo.Values = logical(tailHalo.Values);
    end
    haloA = [headHalo.Values; A(:,jj); tailHalo.Values];
    % Get the sample points corresponding to the values we will use.
    x = [headHalo.SliceIndex; (1:size(A,1))' + startIndex - 1; ...
        tailHalo.SliceIndex];
    localFlatType = opts.FlatType;
    % If the flat region option is "center" we need to switch it to first
    % and then post-process to be sure that the "center" index is truly the
    % center.
    if opts.FlatType == "center"
        localFlatType = "first";
    end
    Dim = 1;
    inmemoryFcnToUse = @matlab.internal.math.isLocalExtrema;
    [tfCol, PCol] = inmemoryFcnToUse(haloA, opts.IsMaxSearch, ...
        Dim, "MinProminence", opts.MinProminence,...
        "FlatSelection", localFlatType, ...
        "ProminenceWindow", opts.ProminenceWindow, ...
        "SamplePoints", x);
    
    % Correct the identification for type "center".
    if opts.FlatType == "center"
        [tfCol, PCol] = iCorrectCentersForFlatRegions(tfCol, PCol, ...
            headHalo, tailHalo, A(:,jj), startIndex, endIndex);
    end
    
    % Remove padding slices
    firstChunkIndex = 1+height(headHalo);
    lastChunkIndex = numel(haloA)-height(tailHalo);
    TF(:, jj) = tfCol(firstChunkIndex:lastChunkIndex);
    P(:, jj) = PCol(firstChunkIndex:lastChunkIndex);
end
end

%--------------------------------------------------------------------------
function [TF, P] = iFindLocalExtremaTable(A, opts, halos, startIndex)
% Find local extrema in a table chunk given halos from neighboring
% partitions.

% Prominence is only returned for the data variables selected.
P = A(:, opts.DataVars);
for k = 1:numel(opts.DataVars)
   P.(k) = iCorrectIntegerTypeForProminence(P.(k)); 
end
% Mask has the same size as the whole input.
TF = false(size(A));

if isempty(A)
    % Nothing to fill
    return;
end

for jj = 1:numel(opts.DataVars)
    colId = opts.DataVars(jj);
    [TF(:, colId), P.(jj)] = iFindLocalExtremaArray(A.(colId), opts, ...
        halos{jj}, startIndex);
end
end

%--------------------------------------------------------------------------
function summaryTable = iMakeSummaryTable(PartitionId, NumDataSlices, ...
    ProminenceHalos)
% SummaryTable: an internal table used to store a mapping between
% PartitionIds and the following variables
%
% 1) NumDataSlices: the total number of slices in the partition.  This
%    variable is used to determine the slice index relative to the start
%    of the tall array.
% 2) ProminenceHalos: the halo values that need to be communicated to
%    neighboring partitions.

summaryTable = table(PartitionId, NumDataSlices, ProminenceHalos);
end

%--------------------------------------------------------------------------
function adaptor = iMkSummaryTableAdaptor()
% Creates the necessary table adaptor for the internal summary table

import matlab.bigdata.internal.adaptors.getAdaptorForType
import matlab.bigdata.internal.adaptors.TableAdaptor

varNames = {'PartitionId', 'NumDataSlices', 'ProminenceHalos'};
genericAdaptor = getAdaptorForType('');
varAdaptors = repmat({genericAdaptor}, size(varNames));
adaptor = TableAdaptor(varNames, varAdaptors);
end

%--------------------------------------------------------------------------
function startIndex = iGetPartitionStartIndex(summaryTable, partitionId)
% Uses the NumDataSlices variable of the given summaryTable to determine
% the first slice index for the given parititonId relative to the start of
% the tall array.

offset = circshift(summaryTable.NumDataSlices, 1);
offset(1) = 0; % first partition has no offset
offset = cumsum(offset);

offset = offset(summaryTable.PartitionId == partitionId);
startIndex = offset + 1;
end

%--------------------------------------------------------------------------
function halo = iExtractPartitionHalo(summaryTable, partitionId, ...
    promWindow, inputIsTabular)
% Extract only the halos needed for the given partition from the
% summary table.

% First work out the first and last slice indices for this partition
partitionStartId = iGetPartitionStartIndex(summaryTable, partitionId);
numSlices = ...
    summaryTable.NumDataSlices(summaryTable.PartitionId == partitionId);
partitionEndId = partitionStartId + numSlices - 1;

extractFcn = @(h) iExtractNeighbors(h, partitionStartId, ...
    partitionEndId, promWindow);

if inputIsTabular
    halo = cell(1, size(summaryTable.ProminenceHalos, 2));
    
    for jj = 1:numel(halo)
        halo{jj} = vertcat(summaryTable.ProminenceHalos{:, jj});
        halo{jj} = extractFcn(halo{jj});
    end
else
    % Unpack all the valid halos
    halo = vertcat(summaryTable.ProminenceHalos{:});
    halo = extractFcn(halo);
end

end

%--------------------------------------------------------------------------
function halo = iExtractNeighbors(halo, startId, endId, promWindow)
% Reduce the supplied halo to only contain the points neighboring to the
% supplied start and end indices.
import matlab.bigdata.internal.util.indexSlices;
halo = iMergeContinuousRegionsOutsideRange(halo, startId, endId);
N = iDetermineHowManyNeighbors(promWindow);

% For each column of input, find the necessary partition halos.
colIds = unique(halo.ColIndex)';
headFilter = false(size(halo,1), 1);
tailFilter = false(size(halo,1), 1);
for jj = colIds
    isInThisColumn = halo.ColIndex == jj;
    % Extract the N(2) (or fewer) ordered unique slices before the start of
    % this partition.
    isEarlier = find(isInThisColumn & (halo.SliceStartingIndex < startId));
    headHaloIds = iFindOrderedUniqueSlices(halo.Values(isEarlier), [0 N(2)]);
    headFilter(isEarlier(headHaloIds(:,1))) = true;
    % Extract the N(1) (or fewer) ordered unique slices after the end of
    % this partition.
    isLater = find(isInThisColumn & (halo.SliceStartingIndex > endId));
    tailHaloIds = iFindOrderedUniqueSlices(halo.Values(isLater), [N(1) 0]);
    tailFilter(isLater(tailHaloIds(:,1))) = true;
end
halo = indexSlices(halo, headFilter | tailFilter);
end

%--------------------------------------------------------------------------
function tableHalo = iExtractTabularHalo(A, startIdx, promWindow, dvars)
% Extract the valid halo from a chunk of input data for tabular data.
tableHalo = cell(1, numel(dvars));

for jj = 1:numel(dvars)
    Avar = A.(dvars(jj));
    tableHalo{jj} = iExtractChunkHalo(Avar, startIdx, promWindow);
end
end

%--------------------------------------------------------------------------
function halo = iExtractChunkHalo(A, startIndex, promWindow)
% Extract the valid halo from a chunk of input data.  We store the valid
% values as defined by promWindow for each column of input data in a table
% with the following variables:
%
% 1) SliceIndex: the slice index of the valid value
% 2) ColIndex: the column index of the valid value
% 3) Values: the valid halo value that needs to be communicated to
%    neighboring chunks or partitions.

if isempty(A)
    % Early return for empty chunk, return an empty table with the correct
    % variables and column types
    SliceStartingIndex = zeros(0,1);
    SliceEndingIndex = zeros(0,1);
    NumNonMissing = zeros(0,1);
    ColIndex = zeros(0,1);
    Values = zeros(0, 1, like=A); % column empty with correct type
    halo = table(SliceStartingIndex, SliceEndingIndex, NumNonMissing, ...
        ColIndex, Values);
    return;
end

[numSlices, numCols] = size(A);
sliceId = startIndex - 1 + (1:numSlices)';
halo = cell(1, numCols);
N = iDetermineHowManyNeighbors(promWindow);
for jj=1:numCols
    Acol = A(:,jj);
    orderedUniqueSlices = iFindOrderedUniqueSlices(Acol, N);
    SliceStartingIndex = sliceId(orderedUniqueSlices(:,1));
    SliceEndingIndex = sliceId(orderedUniqueSlices(:,2));
    % Count the number of finite entries for each value.
    NumNonMissing = zeros(size(SliceStartingIndex));
    for k = 1:size(NumNonMissing,1)
        idx = orderedUniqueSlices(k,1):orderedUniqueSlices(k,2);
        NumNonMissing(k) = nnz(~isnan(Acol(idx)));
    end
    ColIndex = repmat(jj, size(SliceStartingIndex));
    Values = Acol(orderedUniqueSlices(:,1));
    halo{jj} = table(SliceStartingIndex, SliceEndingIndex, NumNonMissing, ...
        ColIndex, Values);
end
halo = vertcat(halo{:});
end

%--------------------------------------------------------------------------
function halos = iInsertTabularHalos(halos, chunkHalos, partitionStartIdx)
% Add chunk halo into halo table while maintaining a sorted order, for
% tabular data.
for jj = 1:numel(halos)
    halos{jj} = ...
        iInsertChunkHalos(halos{jj}, chunkHalos{jj}, partitionStartIdx);
end
end

%--------------------------------------------------------------------------
function halo = iInsertChunkHalos(halo, chunkHalo, partitionStartIndex)
% Add chunk halo into halo table while maintaining a sorted order.
chunkHalo.SliceStartingIndex = chunkHalo.SliceStartingIndex + partitionStartIndex - 1;
chunkHalo.SliceEndingIndex = chunkHalo.SliceEndingIndex + partitionStartIndex - 1;
halo = sortrows([chunkHalo; halo], {'SliceStartingIndex', 'ColIndex'});
end

%--------------------------------------------------------------------------
function combinedHalo = iMakeNeighborHalo(halo)
% Uses the starting and ending indices of each unique value to create
% duplicate points.
needDuplicates = halo.SliceStartingIndex ~= halo.SliceEndingIndex;
SliceIndex = [halo.SliceStartingIndex; halo.SliceEndingIndex(needDuplicates)];
Values = [halo.Values; halo.Values(needDuplicates)];
NumNonMissing = [halo.NumNonMissing - needDuplicates; ones(nnz(needDuplicates),1)];
combinedHalo = table(SliceIndex, Values, NumNonMissing);
combinedHalo = sortrows(combinedHalo, {'SliceIndex'});
end

%--------------------------------------------------------------------------
function [headHalo, tailHalo] = iGetNeighborHalos(halo, colId, ranges, N)
% Find the ordered unique values to use as the padding for the head of the
% given column.
isThisColumn = halo.ColIndex == colId;
isBeforeHead = halo.SliceStartingIndex < ranges(1);
isAfterTail = halo.SliceStartingIndex > ranges(2);

% Find the head portion.
validHeadIndices = find(isThisColumn & isBeforeHead);
headIndices = iFindOrderedUniqueSlices(halo.Values(validHeadIndices), ...
    [0 N(2)]);
validHeadIndices = validHeadIndices(headIndices(:,1));
% Get the head halo.
headHalo = iMakeNeighborHalo(halo(validHeadIndices, :));

% Find the tail portion.
validTailIndices = find(isThisColumn & isAfterTail);
tailIndices = iFindOrderedUniqueSlices(halo.Values(validTailIndices), ...
    [N(1) 0]);
validTailIndices = validTailIndices(tailIndices(:,1));
tailHalo = iMakeNeighborHalo(halo(validTailIndices, :));
end

%--------------------------------------------------------------------------
function N = iDetermineHowManyNeighbors(promWindow)
% Sets the number of leading and trailing ordered unique values each
% partition must share with the other partitions. 
NB = promWindow(1);
NF = promWindow(2);
% Need to share max(2,NF+1) leading ordered unique values and max(2,NB+1)
% trailing ordered unique values.
N = [max(2, NF+1), max(2, NB+1)];
end

%--------------------------------------------------------------------------
function ids = iFindOrderedUniqueSlices(A, N)
% Find first and last ordered unique slices from a chunk.

if isempty(A)
    ids = zeros(0, 2);
    return;
end

ids = iFindOrderedUniqueElements(A);
if size(ids,1) > sum(N)
    % Keep only the first N(1) and last N(2) ordered unique slices.
    ids = ids([1:N(1) (end-N(2)+1):end], :);
end
end

%--------------------------------------------------------------------------
function ind = iFindOrderedUniqueElements(A)
% Find all of the ordered unique elements in a vector of data, using the
% "unique" rules established by islocal*.  "ordered unique" means the set
% of values that remains after we ignore sequentially repeated entries.
    
% Find all non-repeated entries, making sure Inf/-Inf values are treated as
% unique and NaNs are ignored.
t = 1:numel(A);
t = t(~isnan(A));
A = A(~isnan(A));
A = iConvertUnsignedToSigned(A);
if isempty(A)
    ind = zeros(0,2);
else
    % Find the first and last indices of unique points.
    d = [find([true; ~(diff(A) == 0)]), ...
         find(flip([true; ~(diff(flip(A)) == 0)]))];
    if isempty(d)
        d = zeros(0,2);
    end
    ind = t(d);
end
end

%--------------------------------------------------------------------------
function A = iConvertUnsignedToSigned(A)
% Convert unsigned integers to signed integers.
cls = class(A);
if ~startsWith(cls, 'uint')
    return;
end
scls = cls(2:end);
imax = cast(intmax(scls), cls);
B = zeros(size(A), scls);
idx = A <= imax;
B(idx) = cast(A(idx), scls) - intmax(scls) - 1;
B(~idx) = cast(A(~idx) - imax - 1, scls);
A = B;
end

%--------------------------------------------------------------------------
function mergedHalos = iMergeDuplicates(halo, dir)
% Merge duplicate values within a prominence halo, merging to either the
% first or last element.
ids = iFindOrderedUniqueElements(halo.Values);
import matlab.bigdata.internal.util.indexSlices;
if dir == "first"
    mergedHalos = indexSlices(halo, ids(:,1));
else
    mergedHalos = indexSlices(halo, ids(:,2));
end
% Merge the finite counts.
for i = 1:size(ids,1)
    mergedHalos.NumNonMissing(i) = ...
        sum(halo.NumNonMissing(ids(i,1):ids(i,2)));
end
end

%--------------------------------------------------------------------------
function [tf, ind] = iCheckIfCenterIsInThisChunk(np, na, A)
% Check if the center of a region is within chunk boundaries.
nc = nnz(~isnan(A));
ntotal = nc + np + na;
centerIndex = ceil(ntotal / 2);
tf = (centerIndex > np) && (centerIndex <= (nc+np));
if tf
    finIdxInChunk = centerIndex - np;
    finIdx = find(~isnan(A));
    ind = finIdx(finIdxInChunk);
else
    ind = [];
end
end

%--------------------------------------------------------------------------
function [tf, P] = iCorrectCentersForFlatRegions(tf, P, headHalo, ...
    tailHalo, A, startIndex, endIndex)
% Determine correct placement of the center of flat regions.

% Find the ordered unique values of A.
ids = iFindOrderedUniqueElements(A);
if isempty(ids)
    return;
end
% Range of the values of A within the combined chunk.
firstChunkIndex = 1+height(headHalo);
% The halos continue flat regions if the ordered unique endpoints of the
% chunk are not infinite and if they match the corresponding values from
% the halos.
headIsContinuation = ~isinf(A(ids(1,1))) && ~isempty(headHalo.Values) && ...
    (headHalo.Values(end) == A(ids(1,1)));
tailIsContinuation = ~isinf(A(ids(end,1))) && ...
    ~isempty(tailHalo.Values) && (tailHalo.Values(1) == A(ids(end,1)));

% Make a table of the extrema indices to keep track of things once we
% prune the head and tail halos.
extremaIndices = [headHalo.SliceIndex; (startIndex:endIndex)'; tailHalo.SliceIndex];

% Adjust all center regions, skipping the ends if they are continued in the
% neighboring regions.
for k = (1+headIsContinuation):(size(ids,1)-tailIsContinuation)
    % Skip if this is not a local maxima.
    indexInCombined = ids(k,1)+firstChunkIndex-1;
    if ~tf(indexInCombined)
        continue;
    end
    % Find how many elements are in this region.
    % Move the marker from the first point to the center point.
    tf(indexInCombined) = false;
    % Compute the center, factoring in NaN behavior.
    idx = ids(k,1):ids(k,2);
    idx = idx(~isnan(A(idx)));
    centerIndex = idx(ceil(length(idx)/2));
    tf(firstChunkIndex+centerIndex-1) = true;
end

% Since we need to determine the center region, we want to be rid of any
% duplicates in the head and tail halos.
if headIsContinuation
    % Keep only the leading edge of a flat region.
    headHalo = iMergeDuplicates(headHalo, "first");
end
if tailIsContinuation
    % Keep only the trailing edge of a flat region.
    tailHalo = iMergeDuplicates(tailHalo, "last");
end

% There is only 1 unique point when A is entirely flat.
nFinitesPrior = 0;
nFinitesAfter = 0;
if size(ids, 1) == 1
    % Find the start of the flat region.
    if headIsContinuation
        % Leading edge of the region.
        regionStart = headHalo.SliceIndex(end);
        nFinitesPrior = headHalo.NumNonMissing(end);
    else
        regionStart = startIndex;
    end
    isExtrema = tf(regionStart == extremaIndices);
    % Set the current value to false regardless.
    tf(regionStart == extremaIndices) = false;
    % Find the end of the flat region.
    if tailIsContinuation
        if numel(tailHalo.Values) >= 2
            % Trailing edge of the region.
            nFinitesAfter = tailHalo.NumNonMissing(1);
        else
            % The tail halo only has one value, and is a continuation, so
            % we must be at the end of the array.
            nFinitesAfter = Inf;
        end
    elseif isempty(tailHalo.Values)
        % The tail halo is empty, so we are in the last chunk and
        % are thus at an end point.
        nFinitesAfter = Inf;
    end
    % Next, compute where the center index should be.
    [centerInChunk, Aindex] = iCheckIfCenterIsInThisChunk(nFinitesPrior,...
        nFinitesAfter, A);
    if isExtrema && centerInChunk
        % The center of the flat region is within this chunk and it is an
        % extrema, so mark its center appropriately.
        tf(firstChunkIndex + Aindex - 1) = isExtrema;
    end
else
    % Flat region on the left.
    if headIsContinuation && (numel(headHalo.Values) >= 2)
        % Region starts at the slice index of the last head halo row.
        regionStart = headHalo.SliceIndex(end);
        nFinitesPrior = headHalo.NumNonMissing(end);
        [centerInChunk, Aindex] = ...
            iCheckIfCenterIsInThisChunk(nFinitesPrior, 0, A(1:ids(1,2)));
        % Set the center value only if this is an extrema.
        if tf(extremaIndices == regionStart)
            tf(extremaIndices == regionStart) = false;
            if (centerInChunk)
                tf(firstChunkIndex + Aindex - 1) = true;
            end
        end
    end
    % If the head halo only has one value, and is a continuation, we
    % must be at the end of the array and therefore this is not
    % a local extrema anyway.
    
    % Flat region on the right.
    if tailIsContinuation && (numel(tailHalo.Values) >= 2)
        % Region starts at the last ordered unique value from this chunk.
        regionStart = startIndex - 1 + ids(end,1);
        nFinitesAfter = tailHalo.NumNonMissing(1);
        [centerInChunk, Aindex] = ...
            iCheckIfCenterIsInThisChunk(0, nFinitesAfter, A(ids(end,1):end));
        Aindex = Aindex + ids(end,1)-1;
        % Set the center value only if this is an extrema.
        if tf(extremaIndices == regionStart)
            tf(extremaIndices == regionStart) = false;
            if (centerInChunk)
                tf(firstChunkIndex + Aindex - 1) = true;
            end
        end
    end
    % If the tail halo only has one value, and is a continuation, we
    % must be at the end of the array and therefore this is not
    % a local extrema anyway.
end
end

%--------------------------------------------------------------------------
function P = iCorrectIntegerTypeForProminence(P)
if startsWith(class(P), 'int')
    P = cast(P, ['u', class(P)]);
end
end

%--------------------------------------------------------------------------
function tf = iValidateVariableDataTypes(A, DataVars)
tf = all(varfun(@(x) (isnumeric(x) && isreal(x)) || islogical(x), A, ...
    'InputVariables', DataVars, 'OutputFormat', 'uniform'));
end
