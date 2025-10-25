%CacheOperation
% An operation that represents caching.

% Copyright 2015-2018 The MathWorks, Inc.

classdef (Sealed) CacheOperation < matlab.bigdata.internal.lazyeval.Operation
    
    properties (SetAccess = immutable)
        % A key to the cache entries that correspond to the output of this
        % operation.
        CacheEntryKey;
    end
    
    methods
        % The main constructor.
        function obj = CacheOperation()
            import matlab.bigdata.internal.executor.CacheEntryKey;
            numInputs = 1;
            numOutputs = 1;
            supportsPreview = true;
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numInputs, numOutputs, supportsPreview);
            obj.CacheEntryKey = CacheEntryKey();
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function tasks = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.ChunkwiseProcessorFactory;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.FunctionHandle;
            
            fh = FunctionHandle(@(varargin) deal(varargin{:}));
            processorFactory = ChunkwiseProcessorFactory(...
                fh, obj.NumOutputs, obj.isInputBroadcast(taskDependencies, inputFutureMap));
            processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);
            
            if obj.CacheEntryKey.IsValid
                tasks = ExecutionTask.createSimpleTask(taskDependencies, processorFactory, obj.NumOutputs, ...
                    'CacheLevel', 'All', 'CacheEntryKey', obj.CacheEntryKey);
            else
                tasks = ExecutionTask.createSimpleTask(taskDependencies, processorFactory, obj.NumOutputs);
            end
        end
    end
end
