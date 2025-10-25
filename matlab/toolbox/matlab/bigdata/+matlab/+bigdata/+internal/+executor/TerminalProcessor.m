%TerminalProcessor
% A processor that will ensure all of it's direct dependencies are finished.
%
% This will perform no actual processing. This will simply return true to
% IsMoreInputRequired for all non-finished inputs.
%

%   Copyright 2015-2018 The MathWorks, Inc.

classdef TerminalProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs = 0;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInput, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            obj.IsFinished = all(isLastOfInput);
            obj.IsMoreInputRequired = ~isLastOfInput;
            data = [];
        end
    end
    
    methods
        function obj = TerminalProcessor(numInputs)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.IsMoreInputRequired = true(1, numInputs);
        end
    end
end
