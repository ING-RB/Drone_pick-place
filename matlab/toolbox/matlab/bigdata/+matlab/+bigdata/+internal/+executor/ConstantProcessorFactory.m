%ConstantProcessorFactory
% Factory for building a ConstantProcessor

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) ConstantProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % A 1 x N cell array of constants to be emitted from the processor
        % once.
        Constants (1,:) cell
    end
    
    methods
        function obj = ConstantProcessorFactory(constants)
            % Build a ConstantProcessorFactory around the provided 1 x N
            % cell array of constants.
            obj.Constants = constants;
        end
        
        % Build the processor.
        function processor = feval(obj, ~, ~)
            import matlab.bigdata.internal.executor.ConstantProcessor;
            processor = ConstantProcessor(obj.Constants);
        end
    end
end
