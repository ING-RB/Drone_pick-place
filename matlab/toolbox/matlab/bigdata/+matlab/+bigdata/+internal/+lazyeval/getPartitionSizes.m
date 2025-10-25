function paPartitionSizes = getPartitionSizes(paIn)
% Get an array where each element is the height of the partition of
% corresponding index.

%   Copyright 2017-2018 The MathWorks, Inc.

% TODO(g1473104): Partition sizes should be cached. We also need to
% determine what happens to this array when saved and loaded from a mat
% file.
[paPartitionIndex, paPartitionSizes] = partitionfun(@iGetPartitionSize, paIn);
paPartitionSizes = clientfun(@iParsePartitionSizes, paPartitionIndex, paPartitionSizes);
end

function [isFinished, idx, sz] = iGetPartitionSize(info, x)
% Get the partition size for a single partition
isFinished = info.IsLastChunk;
if isFinished
    idx = [info.PartitionId, info.NumPartitions];
    sz = info.RelativeIndexInPartition + size(x, 1) - 1;
else
    idx = zeros(0, 2);
    sz = zeros(0, 1);
end
end

function cleanSz = iParsePartitionSizes(idx, sz)
% Ensure that partitionSizes is a vector of length numpartitions. This is
% necessary as grouped evaluation does not guarantee to run partitionfun on
% all partitions (e.g. a group does not exist on partition 1).
numPartitions = idx(1, 2);
cleanSz = zeros(numPartitions, 1);
cleanSz(idx(:, 1)) = sz;
end
