%DatastorePartitionStrategy
% A partitioning strategy based on partitioning a datastore with forced fullfile.
%

%   Copyright 2019 The MathWorks, Inc.

classdef (Sealed) FullfileDatastorePartitionStrategy < matlab.bigdata.internal.executor.PartitionStrategy
    properties (SetAccess = immutable)
        % The datastore object associated with this strategy.
        Datastore;
    end
    
    % Overrides of PartitionStrategy properties.
    properties (SetAccess = immutable)
        MinNumPartitions = 1
        
        MaxNumPartitions
        
        IsDatastorePartitioning = true
        
        IsBroadcast = false
        
        MaxNumReadFailures = 0
    end
    
    methods
        function obj = FullfileDatastorePartitionStrategy(ds, numPartitions)
            % Build a FullfileDatastorePartitionStrategy from the given datastore.
            %
            % obj = FullfileDatastorePartitionStrategy(ds);
            %
            % The numPartitions input is optional and provides an override
            % to the suggested number of partitions.
            obj.Datastore = ds;
            
            if nargin >= 2
                obj.MinNumPartitions = numPartitions;
                obj.MaxNumPartitions = numPartitions;
            else
                % The result of numpartitions can be 0 if there exists no
                % underlying data. We bound it because we need to have at
                % least 1 partition for type propagation to work correctly.
                try
                    obj.MaxNumPartitions = max(numel(obj.Datastore.getFiles), 1);
                catch err
                    matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
                end
            end
        end
        
        function partition = createPartition(obj, partitionIndex, numPartitions, hadoopSplit)
            import matlab.bigdata.internal.executor.HadoopDatastorePartition;
            import matlab.bigdata.internal.executor.FullfilePartition;
            if nargin >= 4
                assert(matlab.io.datastore.internal.shim.isHadoopLocationBased(obj.Datastore), ...
                    'Assertion failed: Attempted to initialize a non-Hadoop datastore with a Hadoop split.');
                partition = HadoopDatastorePartition(partitionIndex, numPartitions, hadoopSplit);
            else
                partition = FullfilePartition(partitionIndex, numPartitions);
            end
        end
        
        % Return a strategy where the number of partitions is now fixed
        % to the provided value.
        function obj = fixNumPartitions(obj, numPartitions)
            obj = matlab.bigdata.internal.executor.FullfileDatastorePartitionStrategy(...
                obj.Datastore, numPartitions);
        end
        
        function obj = resolve(obj, defaultNumPartitionsHint, maxNumPartitionsHint, ~)
            % Resolve a partition strategy to the actual strategy and
            % number of partitions to be used by an environment. This
            % receives hints from the environment about ideal number of
            % partitions, but it is completely up-to the strategy to choose
            % actual number of partitions.
            if isinf(obj.MaxNumPartitions)
                N = defaultNumPartitionsHint;
            else
                N = obj.MaxNumPartitions;
            end
            N = min(N, maxNumPartitionsHint);
            N = max(N, obj.MinNumPartitions);
            obj = fixNumPartitions(obj, N);
        end
        
        function tf = isKnownSinglePartition(~)
            % This should never be true since an execution backend may need
            % to enforce a partitioning based on a different strategy.  For
            % example, on Hadoop, locality / byte offset based partitioning
            % is given priority over whether the datastore reports having
            % only a single partition.
            tf = false;
        end
        
        function options = getSerializedLocationOptions(~)
            % Build the options struct to pass to getSerializedLocation.
            options.ForceFullfile = true;
        end
    end

    methods (Access = protected)
        function tf = typedIsCompatible(obj, other)
            % Override of the per-type implementation of isCompatible.
            tf = isequal(obj, other);
        end

        function typedThrowIfIncompatible(obj, other)
            % Override of the per-type implementation of throwIfIncompatible.
            % Note, obj and other are guaranteed to both be
            % DatastorePartitionStrategy.
            if obj.typedIsCompatible(other)
                return;
            end
            matlab.bigdata.internal.throw(...
                message('MATLAB:bigdata:array:IncompatibleTallDatastore'));
        end

        function obj = typedAlign(obj, other)
            % Override of the per-type implementation of align.
            % Note, obj and other are guaranteed to both be
            % DatastorePartitionStrategy.
            typedThrowIfIncompatible(obj, other);
        end
    end
end
