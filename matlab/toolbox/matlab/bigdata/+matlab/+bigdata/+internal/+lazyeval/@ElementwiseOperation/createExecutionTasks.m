function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
% createExecutionTasks creates the execution tasks that represent this
% ElementwiseOperation

%   Copyright 2022 The MathWorks, Inc.

import matlab.bigdata.internal.executor.ExecutionTask;
import matlab.bigdata.internal.lazyeval.ChunkwiseProcessorFactory;
import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;

processorFactory = ChunkwiseProcessorFactory(...
    obj.getCheckedFunctionHandle(), obj.NumOutputs, ...
    obj.isInputBroadcast(taskDependencies, inputFutureMap));
processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);

processorFactory = obj.addGlobalState(processorFactory);

task = ExecutionTask.createSimpleTask(taskDependencies, processorFactory, obj.NumOutputs);
end