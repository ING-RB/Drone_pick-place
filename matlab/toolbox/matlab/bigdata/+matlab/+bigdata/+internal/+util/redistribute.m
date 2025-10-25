function tY = redistribute(tX, N)
%REDISTRIBUTE Redistribute a tall array
%   TY = REDISTRIBUTE(TX, N) redistributes tall array TX to N partitions.
%
%   See also matlab.bigdata.internal.util.viewPartitions

% Copyright 2018-2022 The MathWorks, Inc.

import matlab.bigdata.internal.broadcast
import matlab.bigdata.internal.FunctionHandle
import matlab.bigdata.internal.util.StatefulFunction

narginchk(2,2);
nargoutchk(0,1);

assert(istall(tX), ...
    message("MATLAB:bigdata:array:ArgMustBeTall", 1, upper(mfilename)));

validateattributes(N, "numeric", ...
    ["scalar", "integer", "positive"], ...
    "bigdata:redistribute", "N", 2);

paX = hGetValueImpl(tX);

% Work out how many slices of data we have in each partition
countFcn = FunctionHandle(StatefulFunction(@iCountSlices));
opts = matlab.bigdata.internal.PartitionedArrayOptions;
opts.PassTaggedInputs = true;
partitionSliceCount = partitionfun(opts, countFcn, paX);

% Determine how to evenly balance across N partitions
targetPartitionBounds = clientfun(@iPartitionBounds, partitionSliceCount, N);

% Build a mapping from input partition slice to desired output partition
pMap = partitionfun(opts, ...
    @iBuildMap, paX, broadcast(targetPartitionBounds), ...
    broadcast(partitionSliceCount));

% repartition the input into N equal partitions making sure we have beefy
% chunks
partitionMetadata = matlab.bigdata.internal.PartitionMetadata(N);
paY = repartition(partitionMetadata, pMap, paX);
paY = resizechunks(paY);

if isPartitionIndependent(paX)
    paY = markPartitionIndependent(paY);
end

% Repack into a tall array with a copy of the input adaptor
tY = tall(paY);
tY = hSetAdaptor(tY, hGetAdaptor(tX));
end

function [state, done, out] = iCountSlices(state, info, X)

if isempty(state)
    state.NumDataSlices = 0;
end

% X can be UnknownEmptyArray, size(X,1) on the UnknownEmptyArray will
% return 0.
state.NumDataSlices = state.NumDataSlices + size(X, 1);

done = info.IsLastChunk;

if done
    out = state.NumDataSlices;
else
    out = zeros(0,1);
end
end

function partitionBounds = iPartitionBounds(numDataSlices, N)
% Determine the first and last slice indices for the new partitioning
totalNumSlices = sum(numDataSlices);

% Build up a mapping for new partitionIds to start and end absolute indices
targetPartitionBounds = diff(round(linspace(0, totalNumSlices, N+1)))';
lastSliceId = cumsum(targetPartitionBounds);
firstSliceId = circshift(lastSliceId,1) + 1;
firstSliceId(1) = 1;
targetPartitionBounds = [(1:N)' firstSliceId lastSliceId];
partitionBounds = targetPartitionBounds;
end

function [done, map] = iBuildMap(info, X, targetPartitionBounds, numDataSlices)
% Map each slice to the target partition index
% iBuildMap receives TaggedArrays such as BroadcastArray.
% targetPartitionBounds and numDataSlices are BroadcastArrays, unwrap them.
targetPartitionBounds = getUnderlying(targetPartitionBounds);
numDataSlices = getUnderlying(numDataSlices);

done = info.IsLastChunk;
% Here we can use info.PartitionId because we are receiving tagged inputs
% and all the partitions are visited.
absStart = sum(numDataSlices(1:info.PartitionId - 1));
% X might be UnknownEmptyArray, size(X,1) on the UnknownEmptyArray will
% return 0.
id = absStart + (1:size(X,1))' + info.RelativeIndexInPartition - 1;

map = zeros(size(id));

for ii=1:size(targetPartitionBounds,1)
    targetPartitionId = targetPartitionBounds(ii,1);
    firstSliceId = targetPartitionBounds(ii,2);
    lastSliceId = targetPartitionBounds(ii,3);
    map( id >= firstSliceId & id <=lastSliceId ) = targetPartitionId;
end

end
