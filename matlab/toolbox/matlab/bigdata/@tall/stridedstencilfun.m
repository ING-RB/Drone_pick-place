function varargout = stridedstencilfun(varargin)
%STRIDEDSTENCILFUN Apply a stencil operation with stride to a partitioned
%array
%
%   Syntax:
%       tA = stridedstencilfun(windowFcn, blockFcn, window, info, tX, outputsLike)
%       tA = stridedstencilfun(opts, ...)
%       [tA, tB, ...] = stridedstencilfun(..., windowFcn, blockFcn, window,
%               info, tX, tY, ..., outputsLike1, outputsLike2, ...)
%
%   Inputs:
%    - windowFcn is a function handle containing the stencil operation
%    that will be applied to each window in the underlying data.
%
%    - blockFcn is a function handle containing the stencil operation that
%    will be applied to windows within a padded block of data.
%
%    - window is a two-element vector [NB NF] of integer values used to
%    encode the stencil extent in the tall dimension. The window is defined
%    as [NB NF] where NB is the number of backwards slices required for the
%    stencil operation. Similarly, NF is the number of forward slices
%    required for the stencil operation.
%
%    - info is a struct that contains relevant information for the strided
%    stencil operation:
%       - Stride: nonnegative integer scalar with the step size between
%       windows.
%
%       - EndPoints: string or char vector with the method to treat windows
%       at the edges of the input data. It can be any of: "shrink",
%       "discard", or "fill".
%
%       - FillValue: contains a sample value data to include as padding. It
%       only applies when EndPoints is "fill".
%
%    - tX is the partitioned array to apply the stencil operation to.
%
%    - outputsLike is a sample value that specifies the type of output tY.
%
%    - opts (optional) specifies options for running the operation such as
%    RNG state.
%
%   Outputs:
%    - tA is the partitioned array that results from applying the strided
%    stencil operation.
%

%   Copyright 2018-2019 The MathWorks, Inc.

import matlab.bigdata.internal.broadcast
import matlab.bigdata.internal.FunctionHandle
import matlab.bigdata.internal.util.StatefulFunction

narginchk(6,Inf);
% First argument might be an options structure
if isa(varargin{1}, 'matlab.bigdata.internal.PartitionedArrayOptions')
    opts = varargin{1};
    varargin(1) = [];
else
    % Use default options
    opts = matlab.bigdata.internal.PartitionedArrayOptions();
end
% Valid syntaxes for the rest are:
% * tA = stridedstencilfun(..., windowFcn, blockFcn, window, info, tX, outputsLike1)
% * [tA, tB, ...] = stridedstencilfun(..., windowFcn, blockFcn, window,
%       info, tX, tY, ..., outputsLike1, outputsLike2, ...)
% The number of outputsLike arguments is equal to the number of requested
% outputs. Tall outputsLike arguments must be compatible in size.
numOutputArgs = nargout;
outputsLike = varargin(end - numOutputArgs + 1:end);
varargin(end - numOutputArgs + 1:end) = [];
% Extract input arguments
assert(numel(varargin)>=5, "Invalid syntax for tall/stridedstencilfun")
[windowFcn, blockFcn, window, strideInfo] = deal(varargin{1:4});
dataArgs = varargin(5:end);

% Throw a comprehensive error if outputsLike is tall but data input
% arguments are not.
if any(cellfun(@istall, outputsLike)) && all(cellfun(@(x) ~istall(x), dataArgs))
    error(message('MATLAB:bigdata:custom:NonTallOutputsLikeRequired'));
end

% Determine the caller function
if isempty(blockFcn)
    isBlockProcessing = false;
else
    % Only blockFcn or windowFcn + blockFcn
    isBlockProcessing = true;
end

% Extract arguments from strideInfo
stride = strideInfo.Stride;
endPoints = strideInfo.EndPoints;

% windowFcn and blockFcn may have been already wrapped as FunctionHandle.
% Extract the underlying function handle as required by the type of
% processing: using windowFcn or using blockFcn. They will be later wrapped
% as part of the stencil operation.
if ~isempty(windowFcn) && isa(windowFcn, 'matlab.bigdata.internal.FunctionHandle')
    underlyingWindowFcn = windowFcn.Handle;
else
    underlyingWindowFcn = windowFcn;
end

if ~isempty(blockFcn) && isa(blockFcn, 'matlab.bigdata.internal.FunctionHandle')
    underlyingBlockFcn = blockFcn.Handle;
else
    underlyingBlockFcn = blockFcn;
end

if all(window == 0)
    % [0 0] window indicates that there is no padding to apply
    % so the stencil operation reduces to a slicewise operation when using
    % windowFcn.
    if ~isBlockProcessing
        % Reduce the number of calls to windowFcn if stride is greater than
        % 1
        if stride > 1
            sliceIds = getAbsoluteSliceIndices(dataArgs{1});
            isStrided = (mod(sliceIds - 1, stride) == 0);
            [stridedInputs{1:numel(dataArgs)}] = filterslices(isStrided, dataArgs{:});
            stridedOutputsLike = cell(1, numOutputArgs);
            for k = 1:numel(outputsLike)
                if istall(outputsLike{k})
                    stridedOutputsLike{k} = filterslices(isStrided, outputsLike{k});
                else
                    stridedOutputsLike{k} = outputsLike{k};
                end
            end
        else
            stridedInputs = dataArgs;
            stridedOutputsLike = outputsLike;
        end
        % Broadcast outputsLike if they are non-tall
        for k = 1:numel(stridedOutputsLike)
            if ~istall(stridedOutputsLike{k})
                stridedOutputsLike{k} = broadcast(stridedOutputsLike{k});
            end
        end
        isTallDimEmpty = broadcast(size(dataArgs{1}, 1) == 0);
        [varargout{1:nargout}] = slicefun(opts, ...
            @(varargin) iSliceStencilFcn(underlyingWindowFcn, varargin{:}), ...
            isTallDimEmpty, stridedInputs{:}, stridedOutputsLike{:});
        return;
    end
end

% First pass: Reduce each partition to the first NF and last NB data slices
summaryFcn = @(varargin) iSummarizePartition(varargin{:});
summaryFH = FunctionHandle(StatefulFunction(summaryFcn));
summaryTable = partitionfun(summaryFH, window, dataArgs{:});
summaryTable.Adaptor = iMakeSummaryTableAdaptor();

% Extract first and last slice indices defined by stride in each partition
summaryTable = clientfun(@iFindStrideIndicesInPartition, summaryTable, window, stride, endPoints);

% Second pass: Apply the stencil function using the partition boundary
% slices obtained in the first pass.
strideInfo.IsBlockProcessing = isBlockProcessing;
strideInfo.WindowFcn = underlyingWindowFcn;
strideInfo.BlockFcn = underlyingBlockFcn;
strideInfo.Window = window;
applyStencilFcn = @(varargin) iApplyStencil(varargin{:});
if isBlockProcessing
    % Copy the error stack from blockFcn to the function handle responsible of
    % the stencil operation.
    applyStencilFH = blockFcn.copyWithNewHandle(StatefulFunction(applyStencilFcn));
else
    % Copy the error stack from windowFcn to the function handle responsible
    % of the stencil operation.
    applyStencilFH = windowFcn.copyWithNewHandle(StatefulFunction(applyStencilFcn));
end
% Broadcast outputsLike if they are non-tall
for k = 1:numel(outputsLike)
    if ~istall(outputsLike{k})
        outputsLike{k} = broadcast(outputsLike{k});
    end
end
[varargout{1:nargout}] = partitionfun(opts, applyStencilFH, strideInfo, broadcast(summaryTable), dataArgs{:}, outputsLike{:});
% The framework assumes the output of partitionfun is dependent on the
% partitioning. We need to correct this here as the output of stencilfun is
% not.
if all(cellfun(@isPartitionIndependent, dataArgs))
    [varargout{:}] = markPartitionIndependent(varargout{:});
end
end

%--------------------------------------------------------------------------
function varargout = iSliceStencilFcn(stencilFcn, isTallDimEmpty, varargin)
% Apply stencil operation per slice when window is [0 0].
import matlab.bigdata.internal.util.indexSlices

if isTallDimEmpty
    % For a tall array that is completely empty, output will be an empty
    % with the same shape as OutputsLike.
    numOutputArgs = nargout;
    outputsLike = varargin(end - numOutputArgs + 1:end);
    varargout = cellfun(@(x) indexSlices(x, []), outputsLike, 'UniformOutput', false);
else
    [varargout{1:nargout}] = feval(stencilFcn, varargin{:});
end
end

%--------------------------------------------------------------------------
function [state, done, out] = iSummarizePartition(state, info, window, varargin)
% Summarize each partition: count the number of slices in the tall
% dimension and extract the halo slices.
import matlab.bigdata.internal.util.indexSlices

dataArgs = varargin;
X = dataArgs{1};

if isempty(state)
    numDataSlices = 0;
    indexedArgs = cellfun(@(x) indexSlices(x, []), dataArgs, 'UniformOutput', false);
    halo = iMakeHaloTable([], indexedArgs{:});
else
    % unpack the state cell
    [numDataSlices, halo] = state{:};
end

% Combine this chunk with any previously reduced chunks
h = size(X,1);
numDataSlices = numDataSlices + h;
sliceId = info.RelativeIndexInPartition - 1 + (1:h)';
chunk = iMakeHaloTable(sliceId, dataArgs{:});
halo = [halo; chunk];

% Reduce the data we've seen thus far to the first NF and last NB slices
NB = window(1); 
NF = window(2);
isFirstNF = iFindSlices(halo.SliceIndex, NF, 'first');
isLastNB = iFindSlices(halo.SliceIndex, NB, 'last');
slicesToKeep = unique([isFirstNF; isLastNB]);
halo = indexSlices(halo, slicesToKeep);

done = info.IsLastChunk;

if done
    out = iMakeSummaryTable(info.PartitionId, numDataSlices, {halo});
else
    % Update state and output an empty row
    state = {numDataSlices, halo};
    out = iMakeSummaryTable([], [], {});
end
end

%--------------------------------------------------------------------------
function summaryTable = iMakeSummaryTable(PartitionId, NumDataSlices, Halo)
FirstStride = NaN*ones(size(PartitionId));
LastStride = NaN*ones(size(PartitionId));
summaryTable = table(PartitionId, NumDataSlices, Halo, FirstStride, LastStride);
end

%--------------------------------------------------------------------------
function adaptor = iMakeSummaryTableAdaptor()
% Creates the necessary table adaptor for the internal summary table
import matlab.bigdata.internal.adaptors.getAdaptorForType
import matlab.bigdata.internal.adaptors.TableAdaptor

varNames = {'PartitionId', 'NumDataSlices', 'Halo', 'FirstStride', 'LastStride'};
genericAdaptor = getAdaptorForType('');
varAdaptors = repmat({genericAdaptor}, size(varNames));
adaptor = TableAdaptor(varNames, varAdaptors);
end

%--------------------------------------------------------------------------
function haloTable = iMakeHaloTable(SliceIndex, varargin)
haloTable = table(SliceIndex, varargin{:});
end

%--------------------------------------------------------------------------
function T = iFindStrideIndicesInPartition(T, window, stride, endPoints)
% Get first and last slice indices in this partition according to the given
% stride. 
% If a partition doesn't contain a stride, assign first and last stride
% equal to the last stride of the previous partition.

numPartitions = T.PartitionId(end);

% T might not have information for all of the partitions if one of them has
% been represented with UnknownEmptyArray.
for ii = 1:size(T, 1)
    % Get first stride for this partition
    if ii > 1
        T.FirstStride(ii) = T.LastStride(ii-1) + stride;
    else
        % This is the first partition with actual data and no
        % UnknownEmptyArray.
        if any(strcmpi(endPoints, {'shrink', 'fill'}))
            % Shrink default behaviour or fill with padding data. Compute
            % the result only with existing elements, even if there are
            % less than the window length. If it is 'fill', fill the
            % remaining elements of the window with padding sample value.
            T.FirstStride(ii) = 1;
        else
            % 'discard'. Find the first element that contains a full
            % window: NB + 1
            T.FirstStride(ii) = window(1) + 1;
        end
    end
    
    % Indices within this partition
    partitionId = T.PartitionId(ii);
    startIdx = sum(T.NumDataSlices(T.PartitionId < partitionId)) + 1;
    lastIdx = startIdx + T.NumDataSlices(ii) - 1;
    
    if partitionId ~= numPartitions
        % Consider the slices introduced as Tail. For 'discard', get the
        % number of remaining slices if it is smaller than the second half
        % of the window.
        if ~strcmpi(endPoints, 'discard')
            lastIdx = lastIdx + window(2);
        else
            remainingSlices = sum(T.NumDataSlices(T.PartitionId > partitionId));
            if window(2) <= remainingSlices
                lastIdx = lastIdx + window(2);
            else
                lastIdx = lastIdx + remainingSlices;
            end
        end
    end
    
    lastStride = lastIdx - rem((lastIdx-T.FirstStride(ii)), stride);
    
    % For 'discard', get the lastStride with full window in all
    % partitions.
    % For 'shrink' (default) or 'fill', get the lastStride with full
    % window only for head and body partitions. For the last partition,
    % get the lastStride within the size of the input with an
    % incomplete window.
    if strcmpi(endPoints, 'discard') ...
            || (any(strcmpi(endPoints, {'shrink', 'fill'})) && partitionId ~= numPartitions)
        while lastIdx - lastStride < window(2)
            lastStride = lastStride - stride;
        end
    elseif (any(strcmpi(endPoints, {'shrink', 'fill'})) && partitionId == numPartitions)
        % Prevent from assigning a stride value outside the last partition
        while lastStride > lastIdx
            lastStride = lastStride - stride;
        end
    end
    
    % Assign the lastStride for this partition. 
    if lastStride < T.FirstStride(ii)
        % There are no windows in this partition, assign previous value
        T.FirstStride(ii) = T.FirstStride(ii) - stride;
        T.LastStride(ii) = T.FirstStride(ii);
    else
        T.LastStride(ii) = lastStride;
    end
end
end

%--------------------------------------------------------------------------
function [obj, done, varargout] = iApplyStencil(obj, info, strideInfo, summaryTable, varargin)
% Apply the stencil operation in each chunk. Before applying it, we need to
% check that we have enough slices in the chunk to apply the stencil. If it
% is not the case, buffer the input slices in the StatefulFunction object
% obj.
import matlab.bigdata.internal.util.indexSlices

% Extract outputsLike and dataArgs
outputsLike = varargin(end - (nargout-2) + 1:end);
varargin(end - (nargout-2) + 1:end) = [];
dataArgs = varargin(1:end);

done = info.IsLastChunk;
if isempty(obj)
    if sum(summaryTable.NumDataSlices) == 0
        % Early exit for a completely empty tall array. Output will be an
        % empty with the same shape as OutputsLike.
        varargout = cellfun(@(x) indexSlices(x, []), outputsLike, 'UniformOutput', false);
        return;
    elseif (sum(summaryTable.NumDataSlices) < sum(strideInfo.Window) + 1) ...
            && strcmpi(strideInfo.EndPoints, 'discard')
        % Early exit for 'discard' and a tall array with fewer slices than
        % the window length. Output will be an empty with the same shape as
        % OutputsLike.
        varargout = cellfun(@(x) indexSlices(x, []), outputsLike, 'UniformOutput', false);
        return;
    end
    
    % obj keeps the state information between chunks in a partition. We
    % create obj in the first chunk of each partition and it will be
    % updated by the following chunks in the same partition.
    obj.InputBuffer = iMakeIndexSlicesTable(dataArgs, []);
    [obj.IsHeadPartition, obj.IsTailPartition, obj.StartSliceIdx] = ...
        iGetPartitionInfo(summaryTable, info.PartitionId);
    
    [obj.Head, obj.Tail] = ...
        iExtractPartitionHalo(summaryTable, info.PartitionId, strideInfo.Window);
    obj.LastStride = NaN;
end

NB = strideInfo.Window(1);
NF = strideInfo.Window(2);
span = NB + NF;
padding = [size(obj.Head, 1) size(obj.Tail, 1)];

% Combine input with any slices that were previously buffered.
for ii = 1:numel(dataArgs)
    dataArgs{ii} = [obj.InputBuffer{:, ii}; dataArgs{ii}];
end
h = size(dataArgs{1}, 1);

if done
    % Done! Apply the tail padding supplied by the following partition(s)
    stencilInfo = iGetStencilInfo(info, obj, strideInfo.Window, padding);
    paddedDataArgs = cell(1, numel(dataArgs));
    for ii = 1:numel(dataArgs)
        paddedDataArgs{ii} = [obj.Head{:, ii}; dataArgs{ii}; obj.Tail{:, ii}];
    end
    [strideIndices, ~] = iFindStrideIndicesInChunk(obj, stencilInfo, ...
        info, summaryTable, strideInfo.Stride, size(dataArgs{1}, 1));
    strideInfo.StrideIndices = strideIndices;
    [varargout{1:nargout-2}] = matlab.bigdata.internal.lazyeval.applyMovingWindow(...
        strideInfo, paddedDataArgs{:}, outputsLike{:});
elseif h <= span
    % Need at least enough slices to satisfy an entire window span or we
    % run out of data in this partition.  Add any data onto the buffer and
    % evaluate an empty body chunk to ensure outputs have correct types.
    obj.InputBuffer = table(dataArgs{:});
    dataArgs = cellfun(@(x) indexSlices(x, []), dataArgs, 'UniformOutput', false);
    stencilInfo = iGetStencilInfo(info, obj, strideInfo.Window, strideInfo.Window);
    [strideIndices, lastAbsoluteStride] = iFindStrideIndicesInChunk(obj, stencilInfo, ...
        info, summaryTable, strideInfo.Stride, size(dataArgs{1}, 1));
    obj.LastStride = lastAbsoluteStride;
    strideInfo.StrideIndices = strideIndices;
    [varargout{1:nargout-2}] = matlab.bigdata.internal.lazyeval.applyMovingWindow(...
        strideInfo, dataArgs{:}, outputsLike{:});
else % h > span
    % Body chunk.  Use the last NF slices of data as padding.
    stencilInfo = iGetStencilInfo(info, obj, strideInfo.Window, [padding(1) NF]);
    paddedDataArgs = cell(1, numel(dataArgs));
    for ii = 1:numel(dataArgs)
        paddedDataArgs{ii} = [obj.Head{:, ii}; dataArgs{ii}];
    end
    [strideIndices, lastAbsoluteStride] = iFindStrideIndicesInChunk(obj, stencilInfo, ...
        info, summaryTable, strideInfo.Stride, size(dataArgs{1}, 1));
    obj.LastStride = lastAbsoluteStride;
    strideInfo.StrideIndices = strideIndices;
    [varargout{1:nargout-2}] = matlab.bigdata.internal.lazyeval.applyMovingWindow(...
        strideInfo, paddedDataArgs{:}, outputsLike{:});
    
    % Buffer slices used as padding this call for the next one.
    obj.Head = iMakeIndexSlicesTable(dataArgs, (h - span + 1 : h - NF));
    obj.InputBuffer = iMakeIndexSlicesTable(dataArgs, (h - NF+1 : h));
end
end

%--------------------------------------------------------------------------
function [head, tail] = iExtractPartitionHalo(T, partitionId, window)
% Convert halos to use absolute indices and extract partition boundaries
[halos, startId, endId] = iMapToAbsoluteIndices(T, partitionId);

% Head padding: previous NB slices to the start of this partition
NB = window(1);
isHead = iFindSlices(halos.SliceIndex < startId, NB, 'last');
head = halos(isHead, 2:end);

% Tail padding: the NF slices that come after the end of this partition
NF = window(2);
isTail = iFindSlices(halos.SliceIndex > endId, NF, 'first');
tail = halos(isTail, 2:end);
end

%--------------------------------------------------------------------------
function [halos, startId, endId] = iMapToAbsoluteIndices(T, partitionId)
% Update the slice indices stored within the halo table so that the slice
% index column contains the overall partitioned array index.
offset = circshift(T.NumDataSlices, 1);
offset(1) = 0; % first partition has no offset
offset = cumsum(offset);

for ii = 2:numel(offset)
    halo = T{ii, 'Halo'};
    halo{:}.SliceIndex = halo{:}.SliceIndex + offset(ii);
    T{ii, 'Halo'} = halo;
end

halos = vertcat(T.Halo{:});

% Work out the first and last absolute slice index for the given partition
offset = offset(T.PartitionId == partitionId);
startId = offset + 1;
endId = startId + T{T.PartitionId == partitionId, 'NumDataSlices'} - 1;
end

%--------------------------------------------------------------------------
function [isHeadPartition, isTailPartition, startIdx] = iGetPartitionInfo(T, partitionId)
% Determine whether the current partition is the absolute head or tail
T = T(T.NumDataSlices ~=0, :); % prune empty partitions

% After pruning empty partitions, T can't be fully empty as fully empty
% tall arrays have been already triggered.
[first, last] = bounds(T.PartitionId);
isHeadPartition = first == partitionId;
isTailPartition = last == partitionId;
startIdx = sum(T.NumDataSlices(T.PartitionId < partitionId)) + 1;
end

%--------------------------------------------------------------------------
function ids = iFindSlices(x, N, opt)
% Simple wrapper around find that allows searching for N == 0 indices
import matlab.bigdata.internal.util.indexSlices

if N > 0
    ids = find(x, N, opt);
else
    % Return empty with the correct shape and type double
    ids = double(indexSlices(x, []));
end
end

%--------------------------------------------------------------------------
function stencilInfo = iGetStencilInfo(info, obj, window, padding)
% Build up the stencil info struct based on the current evaluation state.
isFirstChunk = obj.IsHeadPartition && info.RelativeIndexInPartition(1) == 1;
isLastChunk = obj.IsTailPartition && info.IsLastChunk;
isMissingPadding = padding < window;
startIdx = info.RelativeIndexInPartition(1) + obj.StartSliceIdx - 1;

stencilInfo = struct(...
    'Window', window, ...
    'Padding', padding, ...
    'StartIndex', startIdx, ...
    'IsHead', isFirstChunk || isMissingPadding(1), ...
    'IsTail', isLastChunk || isMissingPadding(2));
end

%--------------------------------------------------------------------------
function [strideIndices, lastAbsoluteStride] = iFindStrideIndicesInChunk(...
    obj, stencilInfo, info, summaryTable, stride, numSlicesInX)

% Extract first and last stride indices computed for the current partition.
firstStrideInPartition = summaryTable.FirstStride(summaryTable.PartitionId == info.PartitionId);
lastStrideInPartition = summaryTable.LastStride(summaryTable.PartitionId == info.PartitionId);

% We do not have enough data in this chunk, data may have been buffered.
if numSlicesInX == 0
    strideIndices = [];
    if info.RelativeIndexInPartition(1) == 1
        % For the first chunk of a partition, lastAbsoluteStride has not
        % been defined.
        lastAbsoluteStride = firstStrideInPartition - stride;
    else
        lastAbsoluteStride = obj.LastStride;
    end
    return;
end

% This chunk can contain a padded input. stencilInfo.StartIndex points to
% the first slice of X, which may not be the first slice in the padded
% input.
numSlicesInHead = size(obj.Head, 1);
numSlicesInBuffer = size(obj.InputBuffer, 1);

% Take into account that numSlicesInX contains bufferedSlices
numSlicesInX = numSlicesInX - numSlicesInBuffer;

% Compute first and last stride indices in a chunk
if info.RelativeIndexInPartition(1) == 1 % First chunk of this partition
    firstAbsoluteStride = firstStrideInPartition;
else
    firstAbsoluteStride = obj.LastStride + stride;
end

if info.IsLastChunk % Last chunk of this partition
    lastAbsoluteStride = lastStrideInPartition;
else
    % Absolute indices in this chunk
    idx = stencilInfo.StartIndex + (0:numSlicesInX - 1);
    
    offsetLastStride = rem(idx(end) - firstAbsoluteStride, stride);
    lastAbsoluteStride = idx(end) - offsetLastStride;
    if offsetLastStride < stencilInfo.Window(2)
        while idx(end) - lastAbsoluteStride < stencilInfo.Window(2) 
            lastAbsoluteStride = lastAbsoluteStride - stride;
        end
    end
end

% Absolute stride indices
absoluteStrideIndices = firstAbsoluteStride:stride:lastAbsoluteStride;
% Return local stride indices for this chunk
strideIndices = absoluteStrideIndices - stencilInfo.StartIndex + 1;
strideIndices = strideIndices + numSlicesInHead + numSlicesInBuffer;
% Only keep stride indices that do not refer to head slices, they have been
% computed in the previous chunk.
strideIndices = strideIndices(strideIndices > numSlicesInHead);
end

%--------------------------------------------------------------------------
function t = iMakeIndexSlicesTable(dataCell, indices)
% Create a table with the result of calling indexSlices for multiple inputs
import matlab.bigdata.internal.util.indexSlices
indexedArgs = cellfun(@(x) indexSlices(x, indices), dataCell, 'UniformOutput', false);
t = table(indexedArgs{:});
end