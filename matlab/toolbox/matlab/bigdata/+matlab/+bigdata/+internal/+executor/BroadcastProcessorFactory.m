%BroadcastProcessorFactory
% Factory for building a BroadcastProcessor

%   Copyright 2018-2019 The MathWorks, Inc.

classdef (Sealed) BroadcastProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % A key that uniquely identifies the output being broadcasted.
        Key (1,1) string
        
        % Number of variables to broadcast
        NumVariables (1,1) double
    end
    
    methods
        function obj = BroadcastProcessorFactory(key, numVariables)
            % Build a BroadcastProcessorFactory around the provided
            % broadcast function, that accepts and emits the given number
            % of variables.
            obj.Key = key;
            obj.NumVariables = numVariables;
        end
        
        % Build the processor.
        function pocessor = feval(obj, partitionContext, ~)
            import matlab.bigdata.internal.executor.BroadcastProcessor;
            pocessor = BroadcastProcessor(obj.Key, ...
                obj.NumVariables, partitionContext);
        end
    end
end
