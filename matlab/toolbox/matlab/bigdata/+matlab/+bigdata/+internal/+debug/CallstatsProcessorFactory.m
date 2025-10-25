%CallstatsProcessorFactory
% Factory for building a CallstatsProcessorDecorator

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) CallstatsProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying DataProcessorFactory to be decorated
        Factory (1,1)
        
        % The stack trace of the operation that led up-to the operation.
        OperationStack (:,1) struct
        
        % Folder path to store all timing results during evaluation.
        ResultsFolder (1,1) string
    end
    
    methods
        function obj = CallstatsProcessorFactory(factory, operationStack, resultsFolder)
            % Build a CallstatsProcessorFactory whose processors profile
            % tall expression evaluation.
            obj.Factory = factory;
            obj.OperationStack = operationStack;
            obj.ResultsFolder = resultsFolder;
        end
        
        % Build the processor.
        function processor = feval(obj, partitionContext, varargin)
            import matlab.bigdata.internal.debug.CallstatsProcessorDecorator;
            processor = feval(obj.Factory, partitionContext, varargin{:});
            processor = CallstatsProcessorDecorator(processor, ...
                obj.OperationStack, obj.ResultsFolder);
        end
    end
end
