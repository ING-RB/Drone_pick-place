function out = extractHead(partitionedArray, n)
%EXTRACTHEAD Extract the head (first rows) of the provided tall array.
%
%   H = extractHead(partitionedArray, n) extracts the head (first rows)
%   of the provided partition array of size up-to n in the tall dimension.
%

%   Copyright 2015-2019 The MathWorks, Inc.

BIG_N = matlab.bigdata.internal.lazyeval.maxSlicesForReduction();
wasPartitionIndependent = isPartitionIndependent(partitionedArray);
if isprop(partitionedArray,'HasPreviewData') && partitionedArray.HasPreviewData ...
        && n<=size(partitionedArray.PreviewData,1)
    % Shortcut when we already have the data locally
    localOut = matlab.bigdata.internal.util.indexSlices(partitionedArray.PreviewData, 1:n);
    out = matlab.bigdata.internal.lazyeval.LazyPartitionedArray.createFromConstant(localOut);
    return;
    
elseif numpartitions(partitionedArray) * n > BIG_N
    % For Large N, minimize communication by using a mapping of partitions
    % to number of slices to include in the head so that we only get the rows we need
    [numSlicesPerPartition, partitionId] = partitionfun(@(info, v) iGetSlicesPerPartition(info, v, n), partitionedArray);
    [numSlicesPerPartition, partitionId] = clientfun(@(ns, pId) iTrimPartitionSlices(ns, pId, n), numSlicesPerPartition, partitionId);
    numSlicesPerPartition = matlab.bigdata.internal.broadcast(numSlicesPerPartition);
    partitionId = matlab.bigdata.internal.broadcast(partitionId);
    out = partitionfun(@iSelectN, partitionedArray, numSlicesPerPartition, partitionId);
    % NB: leave the result unreduced since it may still be big
    
else
    % Simple reduction version. Result reduced down to a single block.
    [partitionedArray, partitionedSliceIds] = partitionheadfun(@(info, v) iFirstNWithEarlyExit(n, v, info), partitionedArray);
    [out, ~] = reducefun(@(v, s) iFirstN(n, v, s), partitionedArray, partitionedSliceIds);
end

% The framework will assume out is partition dependent because it is
% derived from partitionfun. It is not, so we must correct this.
if wasPartitionIndependent
    out = markPartitionIndependent(out);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [out, sliceId] = iFirstN(n, v, sliceId)
% We sort on absolute index of the original array as during a reduction,
% v is not guaranteed to be in order. For example, partition 2 might be
% processed before partition 1.

[sliceId, idx] = sortrows(sliceId);
sliceId = sliceId(1:min(n, end), :);
idx = idx(1:min(n, end));

out = matlab.bigdata.internal.util.indexSlices(v, idx);
end


function [hasFinished, out, sliceId] = iFirstNWithEarlyExit(n, v, info)
% Keep only the first N entries from this partition, aborting early once N
% is reached.

[hasFinished, numSlicesToEmit] = iGetChunkSize(info, v, n);
% This pair of indices is equivalent to the absolute index of the slice
% with respect to the ordering given by sortrows.
sliceId = [info.PartitionId * ones(numSlicesToEmit, 1), info.RelativeIndexInPartition - 1 + (1:numSlicesToEmit)'];
[out, sliceId] = iFirstN(numSlicesToEmit, v, sliceId);
end

function [hasFinished, numSlicesToEmit] = iGetChunkSize(info, v, N)
% Return the number of slices in this chunk and whether we are done yet
% (either last chunk or have reached N slices).
numSlicesInCurrentChunk = size(v, 1);
numRemainingSlices = max(N - info.RelativeIndexInPartition + 1, 0);
numSlicesToEmit = min(numRemainingSlices, numSlicesInCurrentChunk);

if numRemainingSlices == 0
    hasFinished = true;
    numSlicesToEmit = 0;
else
    hasFinished = info.IsLastChunk || (numRemainingSlices == numSlicesToEmit);
end
end

function [hasFinished, numSlicesToEmit, partitionId] = iGetSlicesPerPartition(info, v, N)
% Count the slices in this partition, aborting early if we get to N.

% Call the chunk-wise count
[hasFinished, numSlicesFromThisChunk] = iGetChunkSize(info, v, N);

if hasFinished
    % Create outputs
    numSliceInPriorChunks = info.RelativeIndexInPartition - 1;
    numSlicesAtEndOfThischunk = numSliceInPriorChunks + numSlicesFromThisChunk;
    % Return [PartitionId, numSlices]
    numSlicesToEmit = min(N, numSlicesAtEndOfThischunk);
    partitionId = info.PartitionId;
else
    % Set empty values until we are done so that we only get one result per
    % partition.
    numSlicesToEmit = zeros(0,1);
    partitionId = zeros(0,1);
end

end

function [numSlicesFromPartition, partitionId] = iTrimPartitionSlices(numSlicesFromPartition, partitionId, N)
% Trim the slices needed from each partition to give N in total.
% numSlicesFromPartition = [ partitionId, numSlices]
lastIndexInPartition = min(cumsum(numSlicesFromPartition), N);
firstIndexInPartition = [1;lastIndexInPartition(1:end-1)+1];

numSlicesFromPartition = lastIndexInPartition - firstIndexInPartition + 1;
end

function [hasFinished, out] = iSelectN(info, v, n, pId)
% n = [ partitionId, numSlices]
N = n(pId==info.PartitionId);
[hasFinished, out] = iFirstNWithEarlyExit(N, v, info);
end