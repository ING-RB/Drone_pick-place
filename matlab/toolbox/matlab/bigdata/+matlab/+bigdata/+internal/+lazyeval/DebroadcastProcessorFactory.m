%DebroadcastProcessorFactory
% Factory for building a DebroadcastProcessorDecorator

%   Copyright 2018-2022 The MathWorks, Inc.

classdef (Sealed) DebroadcastProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying DataProcessorFactory to be decorated
        Factory (1,1)
        
        % Indices of the inputs to be debroacasted
        BroadcastInputIndices (1,:) double
    end
    
    methods
        function obj = DebroadcastProcessorFactory(factory, inputIndices)
            % Build a DebroadcastProcessorFactory whose processors convert
            % a broadcast into partitioned output.
            obj.Factory = factory;
            obj.BroadcastInputIndices = find(inputIndices);
        end
        
        function processor = feval(obj, partitionContext, varargin)
            import matlab.bigdata.internal.lazyeval.DebroadcastProcessorDecorator
            processor = feval(obj.Factory, partitionContext, varargin{:});
            
            % This decorator is no-op for partition 1.
            if partitionContext.PartitionIndex ~= 1
                processor = DebroadcastProcessorDecorator(processor, obj.BroadcastInputIndices);
            end
        end
    end
    
    methods (Static)
        function factory = wrap(factory, isInputBroadcast)
            % This decorator is a no-op if:
            %  - None of the inputs are broadcast.
            %  - All of the inputs are broadcast, in which case there will
            %  only be a single partition.
            import matlab.bigdata.internal.lazyeval.DebroadcastProcessorFactory
            if any(isInputBroadcast) && ~all(isInputBroadcast)
                inputIndices = find(isInputBroadcast);
                factory = DebroadcastProcessorFactory(factory, inputIndices);
            end
        end
    end
end
