%DeferredConstantProcessorFactory
% Factory for building a ConstantProcessor from a function

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) DeferredConstantProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Function that generates a N x 1 cell array of constants to be
        % emitted.
        %
        % This must have signature:
        %   constants = fcn();
        ConstantsFunction (1,1)
    end
    
    methods
        function obj = DeferredConstantProcessorFactory(constantsFunction)
            % Build a DeferredConstantProcessorFactory whose processors
            % emit a constant deferred until the processor needs to run.
            obj.ConstantsFunction = constantsFunction;
        end
        
        % Build the processor.
        function dataProcessor = feval(obj, ~, ~)
            import matlab.bigdata.internal.executor.ConstantProcessor;
            constants = feval(obj.ConstantsFunction);
            dataProcessor = ConstantProcessor(constants);
        end
    end
end
