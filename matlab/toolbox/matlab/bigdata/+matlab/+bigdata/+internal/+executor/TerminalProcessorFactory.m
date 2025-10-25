%TerminalProcessorFactory
% Factory for building a TerminalProcessor

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) TerminalProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Number of expected variables ending in the built TerminalProcessor
        NumInputs (1,1) double
    end
    
    methods
        function obj = TerminalProcessorFactory(numInputs)
            % Build a TerminalProcessorFactory whose processor "terminates"
            % a data flow. This forces completion of other processors in
            % situations where the useful output is actually the 
            % side-effects.
            obj.NumInputs = numInputs;
        end
        
        % Build the processor.
        function dataProcessor = feval(obj, ~, ~)
            import matlab.bigdata.internal.executor.TerminalProcessor
            dataProcessor = TerminalProcessor(obj.NumInputs);
        end
    end
end
