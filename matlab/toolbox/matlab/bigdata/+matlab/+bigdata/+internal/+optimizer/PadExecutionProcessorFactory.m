%PadExecutionProcessorFactory
% DataProcessor factory that wraps an existing factory to make it
% compatible with a ConcatenatedPartitionStrategy. This effectively pads
% the execution of a partitioned array with empty partitions before and
% after, regardless of what the actual execution wants to do.

%   Copyright 2018 The MathWorks, Inc.

classdef PadExecutionProcessorFactory
    properties (SetAccess = immutable)
        % The underlying DataProcessor factory
        Factory
        
        % Index into the sub-strategies of ConcatenatedPartitionStrategy
        % that the underlying factory corresponds against.
        SubIndex (1,1) double
        
        % Number of expected inputs for the build DataProcessor.
        NumProcessorInputs (1,1) double
        
        % Number of expected outputs for the build DataProcessor.
        NumProcessorOutputs (1,1) double
    end
    
    methods
        function obj = PadExecutionProcessorFactory(...
                factory, subIndex, numProcessorInputs, numProcessorOutputs)
            % Wrap a DataProcessor factory with one that is compatible with
            % a ConcatenatedPartitionStrategy.
            obj.Factory = factory;
            obj.SubIndex = subIndex;
            obj.NumProcessorInputs = numProcessorInputs;
            obj.NumProcessorOutputs = numProcessorOutputs;
        end
        
        function dataProcessor = feval(obj, partition, varargin)
            % Build the data processor for the given partition.
            partition = partition.mapToSubStrategy(obj.SubIndex);
            if isempty(partition)
                dataProcessor = matlab.bigdata.internal.executor.ConstantProcessor.buildEmptyProcessor(...
                    obj.NumProcessorInputs, obj.NumProcessorOutputs);
            else
                dataProcessor = feval(obj.Factory, partition, varargin{:});
            end
        end
    end
end
