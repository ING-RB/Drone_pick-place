function varargout = resizeChunksForVisualization(varargin)
% Resize chunks for visualization. This will collect as much data as
% possible for 1 second (up-to 32 MB) then call the function.
%
% Syntax:
%   [tX,tY,..] = resizeChunksForVisualization(tX,tY,..)
%

%   Copyright 2017-2018 The MathWorks, Inc.

import matlab.bigdata.internal.lazyeval.ChunkResizeOperation;

assert(nargin >= 1, 'Assertion failed: resizeChunksForVisualization called with no inputs.');

inputs = cellfun(@hGetValueImpl, varargin, 'UniformOutput', false);
if iIsSerialExecutor(inputs{:})
    % On serial, we use small values for the limits to ensure the plot is
    % smooth.
    minBytesPerChunk = ChunkResizeOperation.minBytesPerChunkForVisualization();
    maxTimePerChunk = ChunkResizeOperation.maxTimePerChunkForSerialVisualization();
elseif iIsSparkExecutor(inputs{:})
    % On Spark, we can only send data back once at the end of each
    % partition. There is no point trying to stream data back (this will
    % just increase the amount of communication).
    minBytesPerChunk = ChunkResizeOperation.minBytesPerChunkForSparkVisualization();
    maxTimePerChunk = Inf;
else
    % On parallel pool, we use larger values for the limits to reduce the
    % communication of streaming. The number of workers will counterbalance
    % the fewer events.
    minBytesPerChunk = ChunkResizeOperation.minBytesPerChunkForVisualization();
    maxTimePerChunk = ChunkResizeOperation.maxTimePerChunkForParallelVisualization();
end

[varargout{1 : nargout}] = resizechunks(...
    inputs{:}, ...
    'MinBytesPerChunk', minBytesPerChunk, ... % Try to get 32 MB / 128 MB per worker invocation by default.
    'MaxTimePerChunk', maxTimePerChunk);      % But only wait at most 0.5 or 10 seconds by default
                                              % depending on backend.

varargout = cellfun(@tall, varargout, 'UniformOutput', false);
for ii = 1 : numel(varargout)
    varargout{ii} = hSetAdaptor(varargout{ii}, matlab.bigdata.internal.adaptors.getAdaptor(varargin{ii}));
end
end

function tf = iIsSerialExecutor(varargin)
% Check if the tall arrays are backed by the serial execution environment.
executor = varargin{1}.Executor;
tf = executor.supportsSinglePartition();
end

function tf = iIsSparkExecutor(varargin)
% Check if the tall arrays are backed by the serial execution environment.
executor = varargin{1}.Executor;
% This is only true for Spark.
tf = executor.requiresSequenceFileFormat();
end
