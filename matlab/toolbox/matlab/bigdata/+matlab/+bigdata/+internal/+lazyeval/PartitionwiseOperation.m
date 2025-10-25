%PartitionwiseOperation
% An operation that acts on each partition of data.

% Copyright 2015-2018 The MathWorks, Inc.

classdef (Sealed) PartitionwiseOperation < matlab.bigdata.internal.lazyeval.Operation
    properties (SetAccess = immutable)
        % The function handle for the operation.
        FunctionHandle;
    end
    
    methods
        % The main constructor.
        function obj = PartitionwiseOperation(options, functionHandle, numInputs, numOutputs, dependsOnlyOnHead)
            if nargin < 5
                dependsOnlyOnHead = false;
            end
            supportsPreview = dependsOnlyOnHead;
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numInputs, numOutputs, supportsPreview, dependsOnlyOnHead);
            obj.FunctionHandle = functionHandle;
            obj.Options = options;
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.PartitionwiseProcessorFactory;
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            
            fh = TaggedArrayFunction.wrap(obj.FunctionHandle, obj.Options);
            processorFactory = PartitionwiseProcessorFactory(...
                fh, obj.NumOutputs, ...
                obj.isInputBroadcast(taskDependencies, inputFutureMap));
            processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);
            processorFactory = obj.addGlobalState(processorFactory);

            task = ExecutionTask.createSimpleTask(taskDependencies, processorFactory, obj.NumOutputs);
        end
    end
end
