%ReduceProcessorFactory
% Factory for building a ReduceProcessor

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) ReduceProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Function that applies the reduce contract to blocks of the input.
        Function (1,1)
        
        % Number of variables to be reduced
        NumVariables (1,1) double
    end
    
    methods
        function obj = ReduceProcessorFactory(fcn, numVariables)
            % Build a ReduceProcessorFactory whose processors apply the
            % reduction contract.
            obj.Function = fcn;
            obj.NumVariables = numVariables;
        end
        
        % Build the processor.
        function processor = feval(obj, ~, ~)
            import matlab.bigdata.internal.lazyeval.ReduceProcessor
            processor = ReduceProcessor(obj.Function, obj.NumVariables);
        end
    end
end
