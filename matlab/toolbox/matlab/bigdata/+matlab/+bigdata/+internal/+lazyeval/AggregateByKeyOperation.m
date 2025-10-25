%AggregateByKeyOperation
% An operation that reduces some transformation of the input data to a
% single chunk per key.

% Copyright 2015-2018 The MathWorks, Inc.

classdef (Sealed) AggregateByKeyOperation < matlab.bigdata.internal.lazyeval.Operation
    properties (SetAccess = immutable)
        % The function handle to be applied per input chunk of the data.
        PerChunkFunctionHandle;
        
        % The function handle to be applied to perform the reduction.
        ReduceFunctionHandle;
    end
    
    methods
        % The main constructor.
        function obj = AggregateByKeyOperation(options, perChunkFunctionHandle, reduceFunctionHandle, numInputs, numOutputs)
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numInputs, numOutputs);
            obj.PerChunkFunctionHandle = perChunkFunctionHandle;
            obj.ReduceFunctionHandle = reduceFunctionHandle;
            obj.Options = options;
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function tasks = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.ReduceByKeyProcessorFactory;
            import matlab.bigdata.internal.lazyeval.ChunkwiseProcessorFactory;
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            import matlab.bigdata.internal.lazyeval.GroupedByKeyFunction;
            import matlab.bigdata.internal.lazyeval.InputFutureMap;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            
            isBroadcast = arrayfun(@(x)x.OutputPartitionStrategy.IsBroadcast, taskDependencies);
            if any(isBroadcast) && ~all(isBroadcast)
                obj.PerChunkFunctionHandle.throwAsFunction(MException(message('MATLAB:bigdata:array:IncompatibleTallStrictSize')));
            end
            
            perChunkFunction = obj.PerChunkFunctionHandle;
            perChunkFunction = TaggedArrayFunction.wrap(perChunkFunction, obj.Options);
            perChunkFunction = GroupedByKeyFunction.wrap(perChunkFunction);
            
            reduceFunction = obj.ReduceFunctionHandle;
            reduceFunction = TaggedArrayFunction.wrap(reduceFunction, obj.Options);
            reduceFunction = GroupedByKeyFunction.wrap(reduceFunction);
            
            allowTallDimExpansion = false;
            perChunkProcessorFactory = ChunkwiseProcessorFactory(...
                perChunkFunction, obj.NumOutputs, ...
                obj.isInputBroadcast(taskDependencies, inputFutureMap), allowTallDimExpansion);
            perChunkProcessorFactory = InputMapProcessorFactory(perChunkProcessorFactory, inputFutureMap);
            perChunkProcessorFactory = obj.addGlobalState(perChunkProcessorFactory);
            
            
            % Per-Partition, Per-Chunk
            % Invoke perChunkFcn on each chunk from the original inputs
            tasks(1) = ExecutionTask.createSimpleTask(taskDependencies, perChunkProcessorFactory, obj.NumOutputs);
            
            % Per-Partition, Across all chunks
            % If there exists more than one partition, we start by doing an
            % initial partial reduction across each entire partition. The
            % output of this will be any-to-any communicated. All partial
            % results for a given key will be moved to the same partition.
            if ~tasks(1).OutputPartitionStrategy.IsBroadcast
                requiresPartitionIndices = true;
                reduceProcessorFactory = ReduceByKeyProcessorFactory(...
                    reduceFunction, obj.NumOutputs, requiresPartitionIndices);
                reduceProcessorFactory = obj.addGlobalState(reduceProcessorFactory );
                % The output is expected to be far smaller than the input
                % even though it is still partitioned. We differentiate the
                % two to avoid displaying this calculation as two separate
                % passes, one which is much faster than the other.
                tasks(2) = ExecutionTask.createAnyToAnyTask(tasks(1), reduceProcessorFactory, obj.NumOutputs, ...
                    'IsPassBoundary', true, 'IsOutputLarge', false);
            end
            
            % Across all remaining boundaries
            % After the communication has been done, or if there is only
            % one partition, we need to do one final reduction phase across
            % each partition. At this point, all data for a given key is
            % guaranteed to be in the same partition.
            reduceProcessorFactory = ReduceByKeyProcessorFactory(...
                reduceFunction, obj.NumOutputs);
            reduceProcessorFactory = obj.addGlobalState(reduceProcessorFactory );
            tasks(end + 1) = ExecutionTask.createSimpleTask(tasks(end), reduceProcessorFactory, obj.NumOutputs, 'IsPassBoundary', true);
        end
    end
end
