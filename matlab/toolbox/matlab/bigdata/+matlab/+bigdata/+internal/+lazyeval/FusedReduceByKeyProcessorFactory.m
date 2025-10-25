%FusedReduceByKeyProcessorFactory
% Factory for building a FusedReduceByKeyProcessor

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) FusedReduceByKeyProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % A cell array of factories to reduce-by-key processors.
        Factories (1,:) cell
        
        % A vector of number of variables for each element of Functions.
        NumVariablesVector (1,:) double
        
        % Number of dependencies. This can either be 1 or numel(Functions)
        % depending on what stage of the reduce-by-key contract this
        % particular processor factory is associated with.
        NumDependencies (1,1) double
        
        % Whether this should emit partition indices as part of the output.
        % This is necessary just prior to communication.
        RequiresPartitionIndices (1,1) logical
    end
    
    methods
        function obj = FusedReduceByKeyProcessorFactory(byKeyFcns, ...
                numVariablesVector, numDependencies, requiresPartitionIndices)
            % Build a FusedReduceByKeyProcessorFactory whose processor is
            % the fusion of multiple ReduceByKeyProcessor.
            if nargin < 3
                numDependencies = numel(byKeyFcns);
            end
            if nargin < 4
                requiresPartitionIndices = false;
            end
            import matlab.bigdata.internal.lazyeval.ReduceByKeyProcessorFactory
            factories = cell(size(byKeyFcns));
            for ii = 1:numel(byKeyFcns)
                factories{ii} = ReduceByKeyProcessorFactory(byKeyFcns{ii}, ...
                    numVariablesVector(ii), requiresPartitionIndices);
            end
            obj.Factories = factories;
            obj.NumVariablesVector = numVariablesVector;
            obj.NumDependencies = numDependencies;
            obj.RequiresPartitionIndices = requiresPartitionIndices;
        end
        
        % Build the processor.
        function processor = feval(obj, partitionContext, varargin)
            processors = cell(size(obj.Factories));
            for ii = 1:numel(obj.Factories)
                processors{ii} = feval(obj.Factories{ii}, partitionContext, varargin{:});
            end
            
            import matlab.bigdata.internal.lazyeval.FusedReduceByKeyProcessor
            numOutputPartitions = 1;
            if nargin >= 3
                numOutputPartitions = numpartitions(varargin{1});
            end
            processor = FusedReduceByKeyProcessor(processors, ...
                obj.NumVariablesVector, numOutputPartitions, ...
                obj.NumDependencies, obj.RequiresPartitionIndices);
        end
    end
end
