%BufferedZipProcessDecoratorFactory
% Factory for building a BufferedZipProcessDecorator

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) PartitionwiseProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying function to be applied chunkwise to the data.
        Function (1,1)
        
        % Number of outputs emitted from the function
        NumOutputs (1,1) double
        
        % For each input, is that input a broadcast?
        IsInputBroadcastVector (1,:) logical
    end
    
    methods
        function obj = PartitionwiseProcessorFactory(fcn, numOutputs, isInputBroadcastVector)
            % Build a PartitionwiseProcessorFactory whose processors apply
            % a partitionwise function to chunks of the underlying data.
            obj.Function = fcn;
            obj.NumOutputs = numOutputs;
            obj.IsInputBroadcastVector = isInputBroadcastVector;
        end
        
        % Build the processor.
        function processor = feval(obj, partitionContext, ~)
            numInputs = numel(obj.IsInputBroadcastVector);
            import matlab.bigdata.internal.lazyeval.PartitionwiseProcessor
            processor = PartitionwiseProcessor(copy(obj.Function), ...
                partitionContext.PartitionIndex, partitionContext.NumPartitions, ...
                numInputs, obj.NumOutputs);
            
            % Need to ensure all inputs arrive at the processor in slice
            % for slice lockstep.
            import matlab.bigdata.internal.lazyeval.BufferedZipProcessDecorator
            allowTallDimExpansion = true;
            processor = BufferedZipProcessDecorator.wrapSimple(processor, ...
                obj.IsInputBroadcastVector, allowTallDimExpansion, ...
                obj.Function.ErrorStack);
        end
    end
end
