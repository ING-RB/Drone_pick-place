%NonPartitionedProcessorFactory
% Factory for building a NonPartitionedProcessor

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) NonPartitionedProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying function to be applied chunkwise to the data.
        Function (1,1)
        
        % Number of inputs to pass to the function
        NumInputs (1,1) double
        
        % Number of outputs emitted from the function
        NumOutputs (1,1) double
    end

    methods
        function obj = NonPartitionedProcessorFactory(fcn, numInputs, numOutputs)
            % Build a NonPartitionedProcessorFactory whose processors apply
            % a function to the entirety of the underlying data in one go.
            obj.Function = fcn;
            obj.NumInputs = numInputs;
            obj.NumOutputs = numOutputs;
        end
        
        % Build the processor.
        function processor = feval(obj, ~, ~)
            import matlab.bigdata.internal.lazyeval.NonPartitionedProcessor
            processor = NonPartitionedProcessor(copy(obj.Function), obj.NumInputs, obj.NumOutputs);
        end
    end
end
