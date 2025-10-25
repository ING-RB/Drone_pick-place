%FixedChunkwiseOperation
% An operation that acts on each chunk of data such that the chunking is
% fixed.

% Copyright 2016-2018 The MathWorks, Inc.

classdef (Sealed) FixedChunkwiseOperation < matlab.bigdata.internal.lazyeval.Operation
    properties (SetAccess = immutable)
        % The function handle for the operation.
        FunctionHandle;
        
        % The number of slices to be required for each chunk.
        NumSlices;
    end
    
    methods
        % The main constructor.
        function obj = FixedChunkwiseOperation(options, numSlices, functionHandle, numInputs, numOutputs)
            assert(isnumeric(numSlices) && isscalar(numSlices) && numSlices > 0 && mod(numSlices, 1) == 0);
            supportsPreview = true;
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numInputs, numOutputs, supportsPreview);
            obj.NumSlices = numSlices;
            obj.FunctionHandle = functionHandle;
            obj.Options = options;
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.FixedChunkwiseProcessorFactory;
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            
            fh = TaggedArrayFunction.wrap(obj.FunctionHandle, obj.Options);
            
            processorFactory = FixedChunkwiseProcessorFactory(...
                obj.NumSlices, fh, obj.NumOutputs, ...
                obj.isInputBroadcast(taskDependencies, inputFutureMap));
            processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);

            processorFactory = obj.addGlobalState(processorFactory);

            task = ExecutionTask.createSimpleTask(taskDependencies, processorFactory, obj.NumOutputs);
        end
    end
end
