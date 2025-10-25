function clientforeach(workerFcn, clientFcn, varargin)
% Apply a client-side for-each operation on the provided
% LazyPartitionedArray inputs.
%

%   Copyright 2022-2024 The MathWorks, Inc.

import matlab.bigdata.internal.lazyeval.LazyPartitionedArray;

workerFcn = iParseFunctionHandle(workerFcn);
clientFcn = iParseFunctionHandle(clientFcn);

intermediate = partitionfun(iCreateForeachWorkerFcn(workerFcn), varargin{:});
[taskGraph, taskToClosureMap, closureToTaskMap, executor, optimUndoGuard] = getEvaluationObjects(intermediate); %#ok<ASGLU>
assert(~isempty(taskGraph), ...
    'Assertion failed: Clientforeach called on a closure that is already complete.');

% This stream output handler will pick out the output
% corresponding with intermediate and stream its chunks to
% clientFcn.
taskId = closureToTaskMap(intermediate.ValueFuture.Closure.Id).Id;
argoutIndex = intermediate.ValueFuture.ArgoutIndex;
clientFcn = iCreateForeachClientFcn(clientFcn);
streamOutputHandler = iCreateStreamOutputHandler(taskId, argoutIndex, clientFcn);

% We include a gather output handler so that any reduced values
% required to be evaluated as part of the input are
% automatically placed in a gathered state on completion.
outputHandlers = [...
    streamOutputHandler; ...
    LazyPartitionedArray.createGatherOutputHandler(taskToClosureMap); ...
    ];

try
    executor.executeWithHandler(taskGraph, outputHandlers);
    LazyPartitionedArray.cleanupOldCacheEntries(taskGraph.CacheEntryKeys);
catch err
    if ~isequal(err.identifier, 'MATLAB:bigdata:executor:ExecutionCancelled')
        rethrow(err);
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Helper function that ensures all received function handles are instances
% of the matlab.bigdata.internal.FunctionHandle class.
function functionHandle = iParseFunctionHandle(functionHandle)
import matlab.bigdata.internal.FunctionHandle;
if ~isa(functionHandle, 'matlab.bigdata.internal.FunctionHandle')
    assert (isa(functionHandle, 'function_handle'), ...
        'Assertion failed: Function handle must be a function_handle or a matlab.bigdata.internal.FunctionHandle.');
    functionHandle = FunctionHandle(functionHandle);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get an output handler object that streams chunks to a function handle.
function handler = iCreateStreamOutputHandler(taskId, argoutIndex, fcn)
import matlab.bigdata.internal.executor.StreamingOutputHandler;
handleFcn = @(varargin) iHandleStreamOutput(varargin{:}, fcn);
handler = StreamingOutputHandler(taskId, argoutIndex, handleFcn);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function cancel = iHandleStreamOutput(~, ~, info, data, fcn)
% Handle stream output by passing pieces of data to a given function as we
% receive it.
hasFinished = feval(fcn, info, vertcat(data{:}, {}));
cancel = hasFinished;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function workerFcn = iCreateForeachWorkerFcn(fcn)
% Create a function handle that encellifies the output of the function call
% so that each output value can be passed exactly to the client function.
workerFcn = @(varargin) iForeachWorkerFcn(fcn, varargin{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [isFinished, value] = iForeachWorkerFcn(fcn, varargin)
% Invoke a clientforeach worker-side function
[isFinished, value] = feval(fcn, varargin{:});
if isempty(value)
    value = cell(0, 1);
else
    value = {value};
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function clientFcn = iCreateForeachClientFcn(fcn)
% Create a function handle that decellifies the input and passes each value
% one by one to the underlying function handle.
import matlab.bigdata.internal.util.StatefulFunction;
clientFcn = StatefulFunction(@(varargin) iForeachClientFcn(fcn, varargin{:}));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [prevChunks, isFinished] = iForeachClientFcn(fcn, prevChunks, info, chunks)
% Invoke a clientforeach client-side function

% We hold the very last received chunk back in-case the next
% invocation of this function has both IsLastChunk true and an
% empty data.
if isempty(prevChunks)
    prevChunks = cell(1, info.NumPartitions);
end
% TODO(g1562385): Removing empty chunks was an behaviour agreed for
% progressive visualization. This ought to live elsewhere.
chunks(cellfun(@isempty, chunks)) = [];
chunks = [prevChunks{info.PartitionIndex}; chunks];
prevChunks{info.PartitionIndex} = [];

% TODO(g1562385): Avoiding calling clientFcn when no input chunks
% was a behaviour agreed for progressive visualization. This ought
% to live elsewhere.
if isempty(chunks)
    isFinished = all(info.CompletedPartitions);
    return;
end

info.PartitionId = info.PartitionIndex;
isLastChunk = info.IsLastChunk;
info.IsLastChunk = false;
info.CompletedPartitions(info.PartitionIndex) = false;

for ii = 1 : numel(chunks) - 1
    isFinished = feval(fcn, info, chunks{ii});
    if isFinished
        return;
    end
end

if isLastChunk
    info.IsLastChunk = true;
    info.CompletedPartitions(info.PartitionIndex) = true;
    isFinished = feval(fcn, info, chunks{end});
else
    prevChunks{info.PartitionIndex} = chunks(end);
    isFinished = false;
end
end
