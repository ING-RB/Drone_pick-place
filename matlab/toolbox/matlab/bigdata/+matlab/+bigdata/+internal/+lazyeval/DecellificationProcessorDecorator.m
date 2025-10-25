%DecellificationProcessorDecorator
% Data Processor that decells each input.
%

%   Copyright 2016-2018 The MathWorks, Inc.

classdef (Sealed) DecellificationProcessorDecorator < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = true;
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % The underlying processor that performs the actual processing.
        UnderlyingProcessor;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function out = process(obj, isLastOfDependencies, in)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            if isempty(in)
                out = cell(0, obj.NumOutputs);
            else
                in = matlab.bigdata.internal.util.vertcatCellContents(in);
                out = obj.UnderlyingProcessor.process(isLastOfDependencies, in);
            end
            obj.IsFinished = isLastOfDependencies;
            obj.IsMoreInputRequired = ~isLastOfDependencies;
        end
    end
    
    methods
        % Private constructor for factory method.
        function obj = DecellificationProcessorDecorator(dataProcessor)
            obj.UnderlyingProcessor = dataProcessor;
            obj.NumOutputs = dataProcessor.NumOutputs;
        end
    end
end
