%PassthroughProcessorFactory
% Factory for building a PassthroughProcessor

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) PassthroughProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Number of inputs to pass to the function
        NumInputs (1,1) double
        
        % Number of outputs emitted from the function
        NumOutputs (1,1) double
    end
    
    methods
        function obj = PassthroughProcessorFactory(numInputs, numOutputs)
            % Build a PassthroughProcessorFactory whose processors simply
            % pass-through all input to the next processor.
            if nargin < 1
                numInputs = 1;
            end
            obj.NumInputs = numInputs;
            if nargin < 2
                numOutputs = 1;
            end
            obj.NumOutputs = numOutputs;
        end
        
        % Build the processor.
        function processor = feval(obj, ~, ~)
            import matlab.bigdata.internal.lazyeval.PassthroughProcessor
            processor = PassthroughProcessor(obj.NumInputs, obj.NumOutputs);
        end
    end
end
