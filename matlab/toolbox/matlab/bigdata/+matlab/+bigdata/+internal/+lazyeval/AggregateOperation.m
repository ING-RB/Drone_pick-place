%AggregateOperation
% An operation that reduces some transformation of the input data to a
% single chunk.

% Copyright 2015-2023 The MathWorks, Inc.

classdef (Sealed) AggregateOperation < matlab.bigdata.internal.lazyeval.AggregateFusibleOperation
    properties (SetAccess = immutable)
        % The function handle to be applied per input chunk of the data.
        PerChunkFunctionHandle;
        
        % The function handle to be applied to perform the reduction.
        ReduceFunctionHandle;
    end
    
    methods
        % The main constructor.
        function obj = AggregateOperation(options, perChunkFunctionHandle, reduceFunctionHandle, numInputs, numOutputs)
            numIntermediates = numOutputs;
            obj = obj@matlab.bigdata.internal.lazyeval.AggregateFusibleOperation(numIntermediates, numInputs, numOutputs);
            obj.PerChunkFunctionHandle = perChunkFunctionHandle;
            obj.ReduceFunctionHandle = reduceFunctionHandle;
            obj.Options = options;
            % If MaxNumSlices is Inf, this operation can be done via
            % calling the function handles on all of the data.
            obj.SupportsDirectEvaluation = isinf(perChunkFunctionHandle.MaxNumSlices);
        end
    end
    
    % Methods overridden in the Operation interface.  
    methods (Access=protected)
        function [varargout] = directEvaluateImpl(obj, varargin)
            % Immediately apply an aggregation to some in-memory data (safe
            % since aggregations always reduce the size of the data).
            heights = cellfun(@(x) size(x, 1), varargin);
            if numel(unique(heights(heights ~= 1))) >= 2
                matlab.bigdata.internal.throw(...
                    MException(message('MATLAB:bigdata:array:IncompatibleTallSize')));
            end
            
            % Create wrappers for the functions to ensure broadcast and
            % other special types are handled correctly.
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            chunkFcn = TaggedArrayFunction.wrap(obj.PerChunkFunctionHandle, obj.Options);
            reduceFcn = TaggedArrayFunction.wrap(obj.ReduceFunctionHandle, obj.Options);
            
            % Apply the per-chunk function to the input to get the
            % intermediate result, then call the reduction to finalize the
            % result (although it may well be a no-op).
            [varargout{1:nargout}] = feval(chunkFcn, varargin{:});
            [varargout{:}] = feval(reduceFcn, varargout{:});
        end
    end
    methods
        function tasks = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.ReduceProcessor;
            
            perChunkProcessorFactory = obj.createPerChunkProcessorFactory(inputFutureMap, obj.isInputBroadcast(taskDependencies, inputFutureMap));
            perChunkProcessorFactory = obj.addGlobalState(perChunkProcessorFactory);
            
            reduceProcessorFactory = obj.createReduceProcessorFactory();

            % Per-Partition, Per-Chunk
            tasks(1) = ExecutionTask.createSimpleTask(taskDependencies, perChunkProcessorFactory, obj.NumOutputs);
            
            % Per-Partition, Across chunk boundary, with output going to a
            % single partition.
            if ~tasks(1).OutputPartitionStrategy.isKnownSinglePartition
                tasks(2) = ExecutionTask.createAllToOneTask(tasks(1), reduceProcessorFactory, obj.NumOutputs, 'IsPassBoundary', true);
            end
            
            % Across chunk and partition boundary. This is broadcast in
            % to allow the result to be used by any partition in following
            % tasks.
            tasks(end + 1) = ExecutionTask.createBroadcastTask(tasks(end), reduceProcessorFactory, obj.NumOutputs, 'IsPassBoundary', true);
        end
    end
    
    % Methods overridden from the AggregateFusibleOperation interface.
    methods
        % Create the DataProcessor that will be applied to every chunk of
        % input before reduction.
        function factory = createPerChunkProcessorFactory(obj, inputFutureMap, isInputBroadcast)
            import matlab.bigdata.internal.lazyeval.ChunkwiseProcessorFactory;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            fh = TaggedArrayFunction.wrap(obj.PerChunkFunctionHandle, obj.Options);
            factory = ChunkwiseProcessorFactory(fh, obj.NumOutputs, isInputBroadcast);
            factory = InputMapProcessorFactory(factory, inputFutureMap);
            factory = obj.addGlobalState(factory);
        end
        
        % Create the DataProcessor that will be applied to reduce
        % consecutive chunks before communication.
        function factory = createCombineProcessorFactory(obj)
            factory = obj.createReduceProcessorFactory();
        end
        
        % Create the DataProcessor that will be applied to reduce
        % consecutive chunks after communication.
        function factory = createReduceProcessorFactory(obj)
            import matlab.bigdata.internal.lazyeval.ReduceProcessorFactory;
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            fh = TaggedArrayFunction.wrap(obj.ReduceFunctionHandle, obj.Options);
            factory = ReduceProcessorFactory(fh, obj.NumOutputs);
            factory = obj.addGlobalState(factory);
        end
    end
end

