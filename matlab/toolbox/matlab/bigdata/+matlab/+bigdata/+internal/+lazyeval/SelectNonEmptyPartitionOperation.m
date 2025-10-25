%SelectNonEmptyPartitionOperation
% An operation for vertical concatenation.

% Copyright 2017-2018 The MathWorks, Inc.

classdef (Sealed) SelectNonEmptyPartitionOperation < matlab.bigdata.internal.lazyeval.Operation
    
    properties (SetAccess = immutable)
        % The function handle for error handling
        FunctionHandle;
    end
        
    methods
        % The main constructor.
        function obj = SelectNonEmptyPartitionOperation(functionHandle, numInputs, numOutputs)
            supportsPreview = true;
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numInputs, numOutputs, supportsPreview);
            obj.FunctionHandle = functionHandle;
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.SelectNonEmptyPartitionProcessorFactory;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            
            numVariables = inputFutureMap.NumOperationInputs;
            processorFactory = SelectNonEmptyPartitionProcessorFactory(obj.FunctionHandle, numVariables);
            processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);
            
            task = ExecutionTask.createSimpleTask(taskDependencies, processorFactory, obj.NumOutputs);
        end
    end
end
