function out = extractTail(partitionedArray, n)
%EXTRACTTAIL Extract the tail (last rows) of the provided tall array.
%
%   H = extractTail(partitionedArray, n) extracts the tail (last rows)
%   of the provided partition array of size up-to n in the tall dimension.
%

%   Copyright 2016-2019 The MathWorks, Inc.

BIG_N = matlab.bigdata.internal.lazyeval.maxSlicesForReduction();

% TODO (g1337016): This could be more efficient if there was a way to do
% execution in reverse order.
wasPartitionIndependent = isPartitionIndependent(partitionedArray);

if numpartitions(partitionedArray) * n > BIG_N
    % Too much data to reduce. Filter and leave partitioned. This requires
    % us to know the partition sizes.
    szP = matlab.bigdata.internal.lazyeval.getPartitionSizes(partitionedArray);
    szP = matlab.bigdata.internal.broadcast(szP);
    out = partitionfun( @(info,szP,v) iKeepNLastSlices(info, n, szP, v), szP, partitionedArray);
else
    % Small enough to reduce. No need to know sizes in advance.
    [partitionedArray, partitionedSliceIds] = ...
        partitionfun(@(info, v) iLastNWithIdGeneration(info, n, v), partitionedArray);
    [out, ~] = reducefun(@(v, s) iLastN(n, v, s), partitionedArray, partitionedSliceIds);
end


% The framework will assume out is partition dependent because it is
% derived from partitionfun. It is not, so we must correct this.
if wasPartitionIndependent
    out = markPartitionIndependent(out);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [out, sliceId] = iLastN(n, v, sliceId)
% We sort on absolute index of the original array as during a reduction,
% v is not guaranteed to be in order. For example, partition 2 might be
% processed before partition 1.
[sliceId, idx] = sortrows(sliceId);
idx = idx(max(end - n + 1, 1) : end);
sliceId = sliceId(max(end - n + 1, 1) : end, 1);
out = matlab.bigdata.internal.util.indexSlices(v, idx);
end

function [hasFinished, out, sliceId] = iLastNWithIdGeneration(info, n, v)
hasFinished = info.IsLastChunk;

% This pair of indices is equivalent to the absolute index of the slice
% with respect to the ordering given by sortrows.
h = size(v, 1);
sliceId = [info.PartitionId * ones(h, 1), info.RelativeIndexInPartition - 1 + (1:h)'];
[out, sliceId] = iLastN(n, v, sliceId);
end

% Helper to filter out slices we don't need, but keeping the partitioning.
function [hasFinished, out] = iKeepNLastSlices(info, n, partSz, v)
hasFinished = info.IsLastChunk;

% Work out how many elements are in later partitions, and therefore how
% many to keep from this partition.
if info.PartitionId < numel(partSz)
    slicesAfterThisPart = sum(partSz((info.PartitionId+1):end));
else
    % Last partition.
    slicesAfterThisPart = 0;
end
numFromThisPart = n - slicesAfterThisPart;

% If keeping any, work out the minimum index to keep.
if numFromThisPart > 0
    minId = max(1, partSz(info.PartitionId)-numFromThisPart+1);
    blockIds = info.RelativeIndexInPartition - 1 + (1:size(v,1))';
    out = matlab.bigdata.internal.util.indexSlices(v, blockIds>=minId);
else
    out = matlab.bigdata.internal.util.indexSlices(v, []);
    hasFinished = true; % Don't bother reading any remaining blocks
end
end
