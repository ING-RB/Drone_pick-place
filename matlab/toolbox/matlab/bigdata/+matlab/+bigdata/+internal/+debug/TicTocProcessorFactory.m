%TicTocProcessorFactory
% Factory for building a TicTocProcessorDecorator

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) TicTocProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying DataProcessorFactory to be decorated
        Factory (1,1)
        
        % The stack trace of the operation that led up-to the operation.
        OperationStack (:,1) struct
        
        % Folder path to store all timing results during evaluation.
        ResultsFolder (1,1) string
    end
    
    methods
        function obj = TicTocProcessorFactory(factory, operationStack, resultsFolder)
            % Build a TicTocProcessorFactory whose processors measure time
            % taken of tall expression evaluation.
            obj.Factory = factory;
            obj.OperationStack = operationStack;
            obj.ResultsFolder = resultsFolder;
        end
        
        % Build the processor.
        function processor = feval(obj, partitionContext, varargin)
            import matlab.bigdata.internal.debug.TicTocProcessorDecorator;
            processor = feval(obj.Factory, partitionContext, varargin{:});
            processor = TicTocProcessorDecorator(processor, ...
                obj.OperationStack, obj.ResultsFolder);
        end
    end
end
