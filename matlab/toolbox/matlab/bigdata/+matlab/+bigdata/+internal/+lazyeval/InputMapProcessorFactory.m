%InputMapProcessorFactory
% Factory for building a InputMapProcessorDecorator

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) InputMapProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying DataProcessorFactory to be decorated
        Factory (1,1)
        
        % The relevant InputFutureMap to map dependencies to the input of
        % the underlying DataProcessor
        Map (1,1)
    end
    
    methods
        function obj = InputMapProcessorFactory(factory, map)
            % Build a InputMapProcessorFactory whose processor maps the
            % varargout output of predecessors to the inputs of the
            % operation to be passed to the underlying processor.
            obj.Factory = factory;
            obj.Map = map;
        end
        
        % Build the processor.
        function processor = feval(obj, partitionContext, varargin)
            import matlab.bigdata.internal.lazyeval.InputMapProcessorDecorator
            processor = feval(obj.Factory, partitionContext, varargin{:});
            processor = InputMapProcessorDecorator(processor, obj.Map);
        end
    end
end
