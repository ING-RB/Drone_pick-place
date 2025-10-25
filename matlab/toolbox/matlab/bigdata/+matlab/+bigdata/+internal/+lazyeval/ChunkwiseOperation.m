%ChunkwiseOperation
% An operation that acts on each chunk of data.

% Copyright 2015-2018 The MathWorks, Inc.

classdef (Sealed) ChunkwiseOperation < matlab.bigdata.internal.lazyeval.Operation
    properties (SetAccess = immutable)
        % The function handle for the operation.
        FunctionHandle;
    end
    
    methods
        % The main constructor.
        function obj = ChunkwiseOperation(options, functionHandle, numInputs, numOutputs)
            supportsPreview = true;
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numInputs, numOutputs, supportsPreview);
            obj.Options = options;
            obj.FunctionHandle = functionHandle;
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.ChunkwiseProcessorFactory;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            
            fh = TaggedArrayFunction.wrap(obj.FunctionHandle, obj.Options);
            processorFactory = ChunkwiseProcessorFactory(...
                fh, obj.NumOutputs, obj.isInputBroadcast(taskDependencies, inputFutureMap));
            processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);
            processorFactory = obj.addGlobalState(processorFactory);
            
            task = ExecutionTask.createSimpleTask(taskDependencies, processorFactory, obj.NumOutputs);
        end
    end
end
