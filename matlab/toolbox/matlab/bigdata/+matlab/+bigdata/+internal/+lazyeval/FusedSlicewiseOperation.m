%FusedSlicewiseOperation
% A composite of several slicewise or elementwise operations.

% Copyright 2015-2018 The MathWorks, Inc.

classdef (Sealed) FusedSlicewiseOperation < matlab.bigdata.internal.lazyeval.Operation
    properties (SetAccess = immutable)
        % The function handle for the operation.
        FunctionHandle;
        
        % An error handler that will be invoked on each incompatible size
        % error during evaluation.
        IncompatibleErrorHandler;
        
        % A logical scalar that specifies if this slicewise operation is
        % allowed to use singleton expansion in the tall dimension.
        AllowTallDimExpansion = true;
    end
    
    methods
        % The main constructor.
        function obj = FusedSlicewiseOperation(options, functionHandle, incompatibleErrorHandler, numInputs, numOutputs)
            supportsPreview = true;
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numInputs, numOutputs, supportsPreview);
            obj.Options = options;
            obj.FunctionHandle = functionHandle;
            obj.IncompatibleErrorHandler = incompatibleErrorHandler;
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.ChunkwiseProcessorFactory;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            
            isBroadcast = arrayfun(@(x)x.OutputPartitionStrategy.IsBroadcast, taskDependencies);
            if ~obj.AllowTallDimExpansion && any(isBroadcast) && ~all(isBroadcast)
                obj.FunctionHandle.throwAsFunction(MException(message('MATLAB:bigdata:array:IncompatibleTallStrictSize')));
            end
            
            processorFactory = ChunkwiseProcessorFactory(...
                obj.FunctionHandle, obj.NumOutputs, ...
                obj.isInputBroadcast(taskDependencies, inputFutureMap), ...
                obj.AllowTallDimExpansion, obj.IncompatibleErrorHandler);
            processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);
            processorFactory = obj.addGlobalState(processorFactory);

            task = ExecutionTask.createSimpleTask(taskDependencies, processorFactory, obj.NumOutputs);
        end
    end
end
