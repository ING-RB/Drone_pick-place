function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
% createExecutionTasks creates the execution tasks that represent this
% SlicewiseOperation.

%   Copyright 2022 The MathWorks, Inc.

import matlab.bigdata.internal.executor.ExecutionTask;
import matlab.bigdata.internal.lazyeval.ChunkwiseProcessorFactory;
import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;

isBroadcast = arrayfun(@(x)x.OutputPartitionStrategy.IsBroadcast, taskDependencies);
if ~obj.AllowTallDimExpansion && any(isBroadcast) && ~all(isBroadcast)
    obj.FunctionHandle.throwAsFunction(MException(message('MATLAB:bigdata:array:IncompatibleTallIndexing')));
end

processorFactory = ChunkwiseProcessorFactory(...
    obj.getCheckedFunctionHandle(), obj.NumOutputs, ...
    obj.isInputBroadcast(taskDependencies, inputFutureMap), ...
    obj.AllowTallDimExpansion);
processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);
processorFactory = obj.addGlobalState(processorFactory);

task = ExecutionTask.createSimpleTask(taskDependencies, processorFactory, obj.NumOutputs);
end