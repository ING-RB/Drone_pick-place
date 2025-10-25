%RepartitionOperation
% An operation that does communication between workers to move elements of
% one or more partitioned arrays into a chosen partitioning strategy.
%

% Copyright 2016-2018 The MathWorks, Inc.

classdef (Sealed) RepartitionOperation < matlab.bigdata.internal.lazyeval.Operation
    
    properties (SetAccess = immutable)
        % The desired partition strategy after the communication has occurred.
        %
        % This can either be:
        %   - A datastore, Where the partition strategy is exactly matching
        %   that datastore.
        %   - The desired number of partitions itself.
        %   - Empty, which represents letting the executor decide.
        OutputPartitionStrategy;
    end
    
    methods
        function obj = RepartitionOperation(partitionStrategy, numVariables)
            % The main constructor.
            numInputs = numVariables + 1;
            numOutputs = numVariables;
            supportsPreview = false;
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numInputs, numOutputs, supportsPreview);
            obj.OutputPartitionStrategy = partitionStrategy;
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.executor.PartitionStrategy;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.PassthroughProcessorFactory;
            import matlab.bigdata.internal.lazyeval.RepartitionProcessorFactory;
            
            
            if obj.OutputPartitionStrategy.IsBroadcast
                % We have to do this because Any-to-Any communication to
                % broadcast partition strategy is not allowed.
                inputFutureMap = submap(inputFutureMap, 2:obj.NumInputs);
                processorFactory = PassthroughProcessorFactory(obj.NumOutputs,obj.NumOutputs);
                processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);
                task = ExecutionTask.createBroadcastTask(taskDependencies, processorFactory, obj.NumOutputs);
            else
                submissionStack = matlab.bigdata.BigDataException.getClientStack();
                processorFactory = RepartitionProcessorFactory(obj.NumOutputs, ...
                    obj.isInputBroadcast(taskDependencies, inputFutureMap), ...
                    submissionStack);
                processorFactory = InputMapProcessorFactory(processorFactory, ...
                    inputFutureMap);
                task = ExecutionTask.createAnyToAnyTask(taskDependencies, processorFactory, obj.NumOutputs, ...
                    'OutputPartitionStrategy', obj.OutputPartitionStrategy);
            end
        end
    end
end
