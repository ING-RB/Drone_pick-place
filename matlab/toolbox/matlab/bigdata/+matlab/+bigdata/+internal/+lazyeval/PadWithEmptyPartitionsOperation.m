%PadWithEmptyPartitionsOperation
% Operation that pads a partitioned array with empty partitions. These
% partitions appear either at the beginning, the end, or both.
%

% Copyright 2018 The MathWorks, Inc.

classdef (Sealed) PadWithEmptyPartitionsOperation < matlab.bigdata.internal.lazyeval.Operation
    properties (SetAccess = immutable)
        % The desired partition strategy after padding. This must be a
        % ConcatenatedPartitionStrategy.
        OutputPartitionStrategy;
        
        % The index of the input into Strategies property of the
        % ConcatenatedPartitionStrategy.
        SubIndex;
    end
    
    methods
        function obj = PadWithEmptyPartitionsOperation(outputPartitionStrategy, subIndex)
            % Build a PadWithEmptyPartitionsOperation that outputs the
            % given partition Strategy by padding the input to align with
            % partitionStrategy.Strategies(subIndex)
            numVariables = 1;
            supportsPreview = false;
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numVariables, numVariables, supportsPreview);
            assert(isa(outputPartitionStrategy, "matlab.bigdata.internal.executor.ConcatenatedPartitionStrategy"), ...
                "Assertion failed: PadWithEmptyPartitionsOperation requires a ConcatenedPartitionStrategy.");
            assert(subIndex > 0 && subIndex <= numel(outputPartitionStrategy.Strategies), ...
                "Assertion failed: subIndex must reference a sub-strategy of OutputPartitionStrategy.");
            obj.OutputPartitionStrategy = outputPartitionStrategy;
            obj.SubIndex = subIndex;
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function task = createExecutionTasks(obj, taskDependencies, inputFutureMap)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.lazyeval.InputMapProcessorFactory;
            import matlab.bigdata.internal.lazyeval.PassthroughProcessorFactory;
            
            processorFactory = PassthroughProcessorFactory(obj.NumInputs, obj.NumOutputs);
            processorFactory = InputMapProcessorFactory(processorFactory, inputFutureMap);
            task = ExecutionTask.createPadWithEmptyPartitionsTask(...
                taskDependencies, processorFactory, obj.NumOutputs, ...
                'OutputPartitionStrategy', obj.OutputPartitionStrategy, ...
                'OutputSubIndex', obj.SubIndex);
        end
    end
end
