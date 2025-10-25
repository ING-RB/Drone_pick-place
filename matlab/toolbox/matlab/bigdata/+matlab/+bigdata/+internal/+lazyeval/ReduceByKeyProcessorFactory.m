%ReduceByKeyProcessorFactory
% Factory for building a ReduceByKeyProcessor

%   Copyright 2018-2022 The MathWorks, Inc.

classdef (Sealed) ReduceByKeyProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % The underlying ReduceProcessor factory that handles the reduce
        % part of ReduceByKey.
        ReduceFactory (1,1)
        
        % Whether this should emit partition indices as part of the output.
        % This is necessary just prior to communication.
        RequiresPartitionIndices (1,1) logical
    end
    
    methods
        function obj = ReduceByKeyProcessorFactory(byKeyFcn, ...
                numVariables, requiresPartitionIndices)
            % Build a ReduceByKeyProcessorFactory whose processor applies
            % the reduce-by-key contract. This requires the provided
            % function already apply it's action per-key.
            
            if nargin < 3
                requiresPartitionIndices = false;
            end
            import matlab.bigdata.internal.lazyeval.ReduceProcessorFactory
            obj.ReduceFactory = ReduceProcessorFactory(byKeyFcn, numVariables);
            obj.RequiresPartitionIndices = requiresPartitionIndices;
        end
        
        % Build the processor
        function processor = feval(obj, partitionContext, outputPartitionStrategy)
            import matlab.bigdata.internal.lazyeval.ReduceByKeyProcessor
            numOutputPartitions = 1;
            if nargin >= 3
                numOutputPartitions = numpartitions(outputPartitionStrategy);
            end
            
            processor = feval(obj.ReduceFactory, partitionContext);
            if obj.RequiresPartitionIndices
                processor = ReduceByKeyProcessor(processor, numOutputPartitions);
            end
        end
    end
end
