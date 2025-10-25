%TicTocProcessorDecorator
% Decorator around DataProcessor that profiles tall evaluation using
% tic-toc.
%
% This is an alternative to CallstatsProcessorDecorator that has far less
% overhead, but at the cost of not being able to step into back-end code in
% the final profile output.

%   Copyright 2018 The MathWorks, Inc.

classdef TicTocProcessorDecorator < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired;
    end
    
    properties (SetAccess = immutable)
        % Unique ID to use as the filename of all results created by this
        % one processor
        Id (1,1) string
        
        % Underlying processor to be measured
        Processor (1,1)
        
        % The stack trace of the operation that led up-to the operation.
        OperationStack (:,1) struct
        
        % Folder path to store all timing results during evaluation.
        ResultsFolder (1,1) string
    end
    
    properties (SetAccess = private)
        % Time taken so far.
        TimeTaken (1,1) double = 0
    end
    
    properties (Constant)
        % Factory for generating unique IDs
        IdFactory = matlab.bigdata.internal.util.UniqueIdFactory('TicToc');
    end
    
    methods
        function obj = TicTocProcessorDecorator(processor, operationStack, resultsFolder)
            % Build a TicTocProcessorDecorator. See
            % ProfilerProcessorFactory.
            obj.Id = obj.IdFactory.nextId();
            obj.NumOutputs = processor.NumOutputs;
            obj.Processor = processor;
            obj.OperationStack = operationStack;
            obj.ResultsFolder = resultsFolder;
            obj.updateState();
        end
        
        function varargout = process(obj, isLastOfInputsVector, varargin)
            % Process the next block of data.
            
            marker = tic;
            [varargout{1:nargout}] = process(obj.Processor, isLastOfInputsVector, varargin{:});
            t = toc(marker);
            
            obj.TimeTaken = obj.TimeTaken + t;
            obj.updateState();
            if obj.IsFinished
                obj.commit();
            end
        end
    end
    
    methods (Access = private)
        function updateState(obj)
            % Update the DataProcessor public properties to correspond with
            % the equivalent of the underlying processor.
            obj.IsFinished = obj.Processor.IsFinished;
            obj.IsMoreInputRequired = obj.Processor.IsMoreInputRequired;
        end
        
        function commit(obj)
            % Commit collected statistics to the results folder.
            
            import matlab.bigdata.internal.debug.ProfileInfo
            info = ProfileInfo.fromStack(obj.OperationStack, obj.TimeTaken);
            
            import matlab.bigdata.internal.debug.TallProfiler
            TallProfiler.writeResults(info, obj.Id, obj.ResultsFolder);
        end
    end
end
