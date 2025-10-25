%GlobalStateProcessorDecorator
% Data Processor that manages global state so that the underlying processor
% receives a well defined view of global state.

% NB: This code must be kept in-sync with Operation/applyGlobalState

%   Copyright 2017-2018 The MathWorks, Inc.

classdef (Sealed) GlobalStateProcessorDecorator < matlab.bigdata.internal.executor.DataProcessor
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
        
        % A random stream that is tied to this processor.
        OperationRandStream;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function varargout = process(obj, isLastChunk, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            oldStream = RandStream.getGlobalStream();
            oldStreamCleanup = onCleanup(@() RandStream.setGlobalStream(oldStream));
            RandStream.setGlobalStream(obj.OperationRandStream);
            
            [varargout{1 : nargout}] = obj.UnderlyingProcessor.process(isLastChunk, varargin{:});
            obj.updateState();
        end
    end
    
    methods
        function obj = GlobalStateProcessorDecorator(dataProcessor, randStream)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.NumOutputs = dataProcessor.NumOutputs;
            obj.UnderlyingProcessor = dataProcessor;
            obj.OperationRandStream = randStream;
            obj.updateState();
        end
        
        function updateState(obj)
            obj.IsFinished = obj.UnderlyingProcessor.IsFinished;
            obj.IsMoreInputRequired = obj.UnderlyingProcessor.IsMoreInputRequired;
        end
    end
end
