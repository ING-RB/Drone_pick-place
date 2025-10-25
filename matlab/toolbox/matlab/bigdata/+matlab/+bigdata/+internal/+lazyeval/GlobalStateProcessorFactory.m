%GlobalStateProcessorFactory
% Factory for building a GlobalStateProcessorDecorator

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) GlobalStateProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying DataProcessorFactory to be decorated
        Factory (1,1)
        
        % A PartitionedArrayOptions object containing the necessary
        % information to setup global state.
        RandStreamFactory (1,1)
    end
    
    methods
        function obj = GlobalStateProcessorFactory(factory, partitionedArrayOptions)
            % Build a GlobalStateProcessorFactory whose processors ensure
            % global process state (E.G. RandStream) is well defined for
            % a given wrapped processor.
            obj.Factory = factory;
            obj.RandStreamFactory = partitionedArrayOptions.RandStreamFactory;
        end
        
        % Build the processor.
        function processor = feval(obj, partitionContext, varargin)
            import matlab.bigdata.internal.lazyeval.GlobalStateProcessorDecorator
            processor = feval(obj.Factory, partitionContext, varargin{:});
            randStream = getRandStreamForPartition(obj.RandStreamFactory, partitionContext.PartitionIndex);
            processor = GlobalStateProcessorDecorator(processor, randStream);
        end
    end
end
