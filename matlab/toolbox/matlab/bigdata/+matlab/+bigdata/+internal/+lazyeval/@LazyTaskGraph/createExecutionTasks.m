function newTasks = createExecutionTasks(closure, predecessorClosures, predecessorTasks, annotateForProfiler)
% Create the execution tasks for a given Closure.

% Copyright 2023 The MathWorks, Inc.

import matlab.bigdata.internal.executor.ExecutionTask
import matlab.bigdata.internal.executor.OutputCommunicationType;
import matlab.bigdata.internal.lazyeval.InputFutureMap;
import matlab.bigdata.internal.debug.TallProfiler

[inputFutureMap, additionalConstants] = InputFutureMap.createFromClosures(closure.InputFutures, predecessorClosures);
additionalTask = ExecutionTask.empty();
if ~isempty(additionalConstants)
    additionalTask = createConstantTask(additionalConstants);
    predecessorTasks = [predecessorTasks; additionalTask];
end

newTasks = closure.Operation.createExecutionTasks(predecessorTasks, inputFutureMap);
newTasks = [additionalTask; newTasks(:)];

% TODO(g1905947): This hook should be removed once the general
% logging/annotation framework supports everything needed by
% the profiler.
if annotateForProfiler
    newTasks = TallProfiler.annotate(newTasks, closure.Operation.Stack);
end
end

function task = createConstantTask(constants)
% Create an ExecutionTask that effectively broadcasts the provided
% constants.
import matlab.bigdata.internal.executor.BroadcastPartitionStrategy;
import matlab.bigdata.internal.executor.ConstantProcessorFactory;
import matlab.bigdata.internal.executor.ExecutionTask;
processorFactory = ConstantProcessorFactory(constants);
task = ExecutionTask.createBroadcastTask([], processorFactory, numel(constants), ...
    'ExecutionPartitionStrategy', BroadcastPartitionStrategy());
end

