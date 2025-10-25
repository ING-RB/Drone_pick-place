%InputMapProcessorDecorator
% A decorator of the DataProcessor interface that converts the input from
% the space of input dependencies to the space of function input arguments.
%

%   Copyright 2016-2018 The MathWorks, Inc.

classdef (Sealed) InputMapProcessorDecorator < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired;
    end
    
    properties (SetAccess = immutable)
        % The underlying processor that performs the actual processing.
        UnderlyingProcessor;
        
        % An object that represents how to convert from dependency input to
        % function handle input.
        InputFutureMap;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        %PROCESS Process the next chunk of data.
        function [data, varargout] = process(obj, isLastOfInputsVector, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            isLastOfInputsVector = obj.InputFutureMap.mapScalars(isLastOfInputsVector);
            varargin = obj.InputFutureMap.mapData(varargin);
            
            [data, varargout{1:nargout - 1}] = obj.UnderlyingProcessor.process(isLastOfInputsVector, varargin{:});
            obj.updateState();
        end
    end
    
    methods
        function obj = InputMapProcessorDecorator(underlyingProcessor, inputFutureMap)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.NumOutputs = underlyingProcessor.NumOutputs;
            obj.UnderlyingProcessor = underlyingProcessor;
            obj.InputFutureMap = inputFutureMap;
            obj.updateState();
        end
        
        function updateState(obj)
            % Update the DataProcessor public properties to correspond with
            % the equivalent of the underlying processor.
            
            obj.IsFinished = obj.UnderlyingProcessor.IsFinished;
            obj.IsMoreInputRequired = obj.InputFutureMap.reverseMapLogicals(obj.UnderlyingProcessor.IsMoreInputRequired);
        end
    end
end
