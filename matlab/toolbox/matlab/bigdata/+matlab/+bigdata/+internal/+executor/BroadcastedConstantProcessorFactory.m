%BroadcastedConstantProcessorFactory
% Factory for building a ConstantProcessor from a broadcast key

%   Copyright 2019 The MathWorks, Inc.

classdef (Sealed) BroadcastedConstantProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % A key that uniquely identifies the broadcasted value being retrieved.
        Key (1,1) string
    end
    
    methods
        function obj = BroadcastedConstantProcessorFactory(key)
            % Build a BroadcastedConstantProcessorFactory whose processors
            % emit a constant based on a broadcast.
            obj.Key = key;
        end
        
        % Build the processor.
        function dataProcessor = feval(obj, partitionContext, ~)
            import matlab.bigdata.internal.executor.ConstantProcessor;
            constants = partitionContext.getBroadcast(obj.Key);
            dataProcessor = ConstantProcessor(constants);
        end
    end
end
