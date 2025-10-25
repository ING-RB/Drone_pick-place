%PadExecutionProcessorFactory
% DataProcessor factory that wraps an existing factory to make the output
% of the build DataProcessor compatible with a ConcatenatedPartitionStrategy.
% This effectively pads the output of a partitioned array with empty
% partitions before and after.

%   Copyright 2018 The MathWorks, Inc.

classdef PadCommOutputProcessorFactory
    properties (SetAccess = immutable)
        % The underlying DataProcessor factory
        Factory
        
        % Flag whether the underlying processor was from an AnyToAny task.
        % This is important as the first output of the underlying processor
        % will be partition indices for where to send each chunk.
        UnderlyingIsAnyToAny (1,1) logical
        
        % Index into the sub-strategies of ConcatenatedPartitionStrategy
        % that the underlying factory corresponds against.
        SubIndex (1,1) double
    end
    
    methods
        function obj = PadCommOutputProcessorFactory(factory, underlyingIsAnytoAny, subIndex)
            % Wrap a DataProcessor factory with one whose output is
            % compatible with a ConcatenatedPartitionStrategy.
            obj.Factory = factory;
            obj.UnderlyingIsAnyToAny = underlyingIsAnytoAny;
            obj.SubIndex = subIndex;
        end
        
        function dataProcessor = feval(obj, partition, outputPartitionStrategy)
            % Build the data processor for the given partition.
            if obj.UnderlyingIsAnyToAny
                dataProcessor = feval(obj.Factory, partition, outputPartitionStrategy.Strategies{obj.SubIndex});
            else
                dataProcessor = feval(obj.Factory, partition);
            end
            
            numPartitionsToPrepend = outputPartitionStrategy.numPartitionsToPrepend(obj.SubIndex);
            numPartitionsToAppend = outputPartitionStrategy.numPartitionsToAppend(obj.SubIndex);
            totalNumPartitions = outputPartitionStrategy.numpartitions();
            dataProcessor = matlab.bigdata.internal.optimizer.PadCommOutputProcessorDecorator(...
                dataProcessor, obj.UnderlyingIsAnyToAny, ...
                numPartitionsToPrepend, numPartitionsToAppend, totalNumPartitions);
        end
    end
end
