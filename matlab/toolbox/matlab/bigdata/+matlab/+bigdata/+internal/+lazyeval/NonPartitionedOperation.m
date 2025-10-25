%NonPartitionedOperation
% An operation that requires non-partitioned inputs.

% Copyright 2015-2018 The MathWorks, Inc.

classdef (Sealed) NonPartitionedOperation < matlab.bigdata.internal.lazyeval.AggregateFusibleOperation
    properties (SetAccess = immutable)
        % The function handle for the operation.
        FunctionHandle;
    end
    
    methods
        % The main constructor.
        function obj = NonPartitionedOperation(options, functionHandle, numInputs, numOutputs)
            numIntermediates = numInputs;
            obj = obj@matlab.bigdata.internal.lazyeval.AggregateFusibleOperation(...
                numIntermediates, numInputs, numOutputs);
            obj.Options = options;
            obj.FunctionHandle = functionHandle;
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function tasks = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.GatherOperation;
            import matlab.bigdata.internal.lazyeval.InputFutureMap;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.NonPartitionedProcessorFactory;
            
            gatherOperation = GatherOperation(obj.NumInputs);
            tasks = gatherOperation.createExecutionTasks(taskDependencies, inputFutureMap);
            
            inputFutureMap = InputFutureMap.createPassthrough(inputFutureMap.NumOperationInputs);
            processorFactory = NonPartitionedProcessorFactory(...
                obj.getWrappedFunctionHandle(), obj.NumInputs, obj.NumOutputs);
            processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);
            processorFactory = obj.addGlobalState(processorFactory);
            
            tasks(end + 1) = ExecutionTask.createBroadcastTask(tasks(end), processorFactory, obj.NumOutputs, 'IsPassBoundary', true);
        end
    end
    
    % Methods overridden from the AggregateFusibleOperation interface.
    methods
        % Create the DataProcessor that will be applied to every chunk of
        % input before reduction.
        function factory = createPerChunkProcessorFactory(obj, inputFutureMap, isInputBroadcast)
            import matlab.bigdata.internal.lazyeval.DebroadcastProcessorFactory;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.OutputBufferProcessFactory;
            import matlab.bigdata.internal.lazyeval.PassthroughProcessorFactory;
            factory = PassthroughProcessorFactory(obj.NumInputs);
            factory = DebroadcastProcessorFactory(factory, isInputBroadcast);
            factory = InputMapProcessorFactory(factory, inputFutureMap);
            factory = OutputBufferProcessFactory(factory);
        end
        
        % Create the DataProcessor that will be applied to reduce
        % consecutive chunks before communication.
        function factory = createCombineProcessorFactory(obj)
            import matlab.bigdata.internal.lazyeval.PassthroughProcessorFactory;
            factory = PassthroughProcessorFactory(1, obj.NumInputs);
        end
        
        % Create the DataProcessor that will be applied to reduce
        % consecutive chunks after communication.
        function factory = createReduceProcessorFactory(obj)
            import matlab.bigdata.internal.lazyeval.InputFutureMap;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.NonPartitionedProcessorFactory;
            inputFutureMap = InputFutureMap.createPassthrough(obj.NumInputs);
            factory = NonPartitionedProcessorFactory(...
                obj.getWrappedFunctionHandle(), obj.NumInputs, obj.NumOutputs);
            factory = InputMapProcessorFactory(factory, inputFutureMap);
            factory = obj.addGlobalState(factory);
        end
    end
    
    methods (Access = private)
        function fh = getWrappedFunctionHandle(obj)
            % Apply the necessary FunctionHandle wrappers to deal with
            % TaggedArray input types.
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            fh = TaggedArrayFunction.wrap(obj.FunctionHandle, obj.Options);
        end
    end
end
