%GatedPassthroughProcessor
% A processor that only permits data to pass-through if a condition is true.
%
% This exists to allow a CompositeDataProcessor where certain branches are
% completely disabled if at construction on a worker a condition is true.
%

%   Copyright 2017-2018 The MathWorks, Inc.

classdef GatedPassthroughProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = false;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInput, data)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            obj.IsFinished = isLastOfInput;
            obj.IsMoreInputRequired = ~isLastOfInput;
        end
    end
    
    methods
        function obj = GatedPassthroughProcessor(allowPassthrough, numVariables)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.NumOutputs = numVariables;
            obj.IsFinished = ~allowPassthrough;
            obj.IsMoreInputRequired = allowPassthrough;
        end
    end
end
