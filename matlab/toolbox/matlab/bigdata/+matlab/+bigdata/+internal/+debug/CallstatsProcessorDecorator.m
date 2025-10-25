%CallstatsProcessorDecorator
% Decorator around DataProcessor that profiles tall evaluation using
% callstats (MATLAB Profiler)

%   Copyright 2018 The MathWorks, Inc.

classdef CallstatsProcessorDecorator < matlab.bigdata.internal.executor.DataProcessor
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
        % Profile stats collected so far.
        Info
    end
    
    properties (Constant)
        % Factory for generating unique IDs
        IdFactory = matlab.bigdata.internal.util.UniqueIdFactory('Profiler');
    end
    
    methods
        function obj = CallstatsProcessorDecorator(processor, operationStack, resultsFolder)
            % Build a CallstatsProcessorDecorator. See
            % CallstatsProcessorFactory.
            obj.Id = obj.IdFactory.nextId();
            obj.NumOutputs = processor.NumOutputs;
            obj.Processor = processor;
            obj.OperationStack = operationStack;
            obj.ResultsFolder = resultsFolder;
            obj.updateState();
            import matlab.bigdata.internal.debug.TallProfiler
            TallProfiler.incrementCallstatsCount();
        end
        
        function delete(~)
            import matlab.bigdata.internal.debug.TallProfiler
            TallProfiler.decrementCallstatsCount();
        end
        
        function varargout = process(obj, isLastOfInputsVector, varargin)
            % Process the next block of data.
            
            callstats('reset');
            callstats('resume');
            [varargout{1:nargout}] = process(obj.Processor, isLastOfInputsVector, varargin{:});
            callstats('pause');
            s = callstats('stats');
            
            import matlab.bigdata.internal.debug.ProfileInfo
            info = ProfileInfo(s);
            % Remove internal frames above this class. We do this here
            % instead of the end of the processor because less functions
            % reduces overhead when combining results.
            info = removeCallersOfFunction(info, ...
                "CallstatsProcessorDecorator>CallstatsProcessorDecorator.process");
            if isempty(obj.Info)
                obj.Info = info;
            else
                obj.Info = combine(obj.Info, info);
            end
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
            info = obj.Info;
            % This is the magic that reparents profiled execution to the
            % line of code that scheduled the operation.
            info = replaceFunction(info, ...
                "CallstatsProcessorDecorator>CallstatsProcessorDecorator.process", ...
                obj.OperationStack);
            % We remove internal names to make the final output clearer. It
            % connects tall algorithm code direct to the profile of functions
            % passed into funfun methods.
            info = removeFunctionsByBlacklist(info, ...
                ["BufferedZipProcessDecorator", "Processor", "TaggedArrayFunction", ...
                "FunctionHandle", "InputFutureMap", "Operation"]);
            
            import matlab.bigdata.internal.debug.TallProfiler
            TallProfiler.writeResults(info, obj.Id, obj.ResultsFolder);
        end
    end
end
