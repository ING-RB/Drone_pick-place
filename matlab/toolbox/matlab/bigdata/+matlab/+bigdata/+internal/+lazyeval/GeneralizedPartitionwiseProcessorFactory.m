%GeneralizedPartitionwiseProcessorFactory
% Factory for building a GeneralizedPartitionwiseProcessor

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) GeneralizedPartitionwiseProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying function to be applied chunkwise to the data.
        Function (1,1)
        
        % Number of outputs emitted from the function.
        NumOutputs (1,1) double
        
        % Logical array, for each input true if that input is a broadcast.
        IsInputBroadcastVector (1,:) logical
    end
    methods
        function obj = GeneralizedPartitionwiseProcessorFactory(fcn, numOutputs, isInputBroadcastVector)
            % Build a GeneralizedPartitionwiseProcessorFactory whose
            % processors apply the generalized partitionwise contract on
            % chunks of the underlying data.
            obj.Function = fcn;
            obj.NumOutputs = numOutputs;
            obj.IsInputBroadcastVector = isInputBroadcastVector;
        end
        
        % Build the processor.
        function processor = feval(obj, partitionContext, ~)
            import matlab.bigdata.internal.lazyeval.GeneralizedPartitionwiseProcessor
            processor = GeneralizedPartitionwiseProcessor(copy(obj.Function), ...
                partitionContext.PartitionIndex, partitionContext.NumPartitions, ...
                obj.NumOutputs, obj.IsInputBroadcastVector);
        end
    end
end
