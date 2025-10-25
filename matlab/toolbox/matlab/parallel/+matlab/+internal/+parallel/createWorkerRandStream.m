function [cpuStream, gpuStream] = createWorkerRandStream(streamIdxVector)
% Create the RandStream to be used by default for the current worker.
%
% [cpuStream, gpuStream] = createWorkerRandStream([idx1, idx2, ...])
% creates two streams that is guaranteed unique for the combination of
% [idx1, idx2, ...] for up-to 8 indices. CPU take the even streams, GPU
% takes the odd streams.
%
% This takes into account geometry of workers in a parallel job. In a job
% containing multiple tiers of worker, for example a pool of pools, the
% first index corresponds to the outermost pool, the last index corresponds
% to the innermost pool.
%
% A negative streamIdxVector element indicates we wish to assign a stream
% index running backwards from the maximum stream index. This is used for
% backgroundPool workers.

%  Copyright 2020-2021 The MathWorks, Inc.

% Since we allow adding tasks to a running job, it is impossible to set
% NumStreams to the total number of tasks in a job. We therefore use 2^32
% (approx 4.3e+9) as a reasonable upper bound. This corresponds to 100
% computers running 1 task per second for 1 year.
maxStreamIdx = 2^32;
generatorName = "Threefry4x64_20";

% Threefry supports up-to 2^256 stream indices, but the only way to access
% the higher values is to manipulate the stream's state directly. Threefry
% state is made up of 4 64-bit integers, each exposed as 32-bit integers
% in little endian format. This is followed by 288 bits of information
% representing substream, seed and position information that is orthogonal
% to stream index. As StreamIndex sets the lower 32-bits of the first
% 64-bit stream index integer, we map the remaining values in streamIdxVector
% to 32-bit sections of the remaining space in that initial 4 64-bit stream
% index integers. The state becomes:
%
% Stream Idx 1st 64-bit: [idx(2) * 2^32 + idx(1)]
% Stream Idx 2nd 64-bit: [idx(4) * 2^32 + idx(3)]
% Stream Idx 3rd 64-bit: [idx(6) * 2^32 + idx(5)]
% Stream Idx 4th 64-bit: [idx(8) * 2^32 + idx(7)]
% Remaining 288 bits: Left at initial state
parentStateMap = [1,4,3,6,5,8,7];
assert(numel(streamIdxVector) < 8, "Assertion Failed: Stream index larger than 2^256");
parentStateMap = parentStateMap(1:numel(streamIdxVector) - 1);

% Get the default random number generator for the CPU. Even numbered
% streams are used on the CPU, odd numbered ones on the GPU.
streamIdxVector(1) = streamIdxVector(1) * 2;

% For a backgroundPool worker, streamIdxVector may contain a negative
% element, indicating that we should assign streaming indices running
% backwards from the largest possible index. In addition, a backgroundPool
% worker cannot nest another worker, so must be the final element of the
% streamIdxVector array.
if streamIdxVector(end) < 0
    streamIdxVector(end) = maxStreamIdx + streamIdxVector(end);
end

cpuStream = RandStream.create( generatorName, ...
    "NumStreams", maxStreamIdx, ...
    "StreamIndices", streamIdxVector(1) );
state = cpuStream.State;
state(parentStateMap) = streamIdxVector(2:end);
cpuStream.State = state;
if nargout < 2
    return;
end

% Get the default random number generator for the GPU. Even numbered
% streams are used on the CPU, odd numbered ones on the GPU. We have to be
% careful to avoid initializing GPU libraries, which happen on accessing
% State the user-visible API.
state(2) = state(2) + 1;
gpuStream = {generatorName, ...
    "NumStreams", maxStreamIdx, ...
    "StreamIndices", streamIdxVector(1), ...
    "InitialState", state, ...
    "CurrentState", state};
end
