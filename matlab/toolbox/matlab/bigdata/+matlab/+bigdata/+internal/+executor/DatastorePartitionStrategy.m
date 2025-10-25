%DatastorePartitionStrategy
% A partitioning strategy based on partitioning a datastore directly.
%
% This strategy allows the execution environment to decide the partitioning
% based on the provided datastore.
%

%   Copyright 2015-2022 The MathWorks, Inc.

classdef DatastorePartitionStrategy < matlab.bigdata.internal.executor.PartitionStrategy
    properties (SetAccess = immutable)
        % The datastore object associated with this strategy.
        Datastore;
        
        % List of memory datastores that belong to this partition strategy.
        DatastoreList;
        
        % A boolean property that is true if and only if the underlying
        % datastore is partitionable.
        IsPartitionable (1,1) logical;
        
        % A boolean property that is true if the associated datastores can
        % be prepartitioned without making a full copy of the datastore.
        IsPrepartitionable (1,1) logical;
        
        % A boolean property that identifies if partitioning can happen
        % first. This is currently true for prepartitionable datastores in
        % process-based back-ends.
        DoPrepartitioning (1,1) logical;
    end
    
    % Overrides of PartitionStrategy properties.
    properties (SetAccess = immutable)
        MinNumPartitions = 1;
        
        MaxNumPartitions;
        
        IsDatastorePartitioning = true;
        
        IsBroadcast = false;
        
        MaxNumReadFailures
    end
    
    methods
        function obj = DatastorePartitionStrategy(ds, numPartitions, isPartitioningFirst)
            % Build a DatastorePartitionStrategy from the given datastore.
            %
            % obj = DatastorePartitionStrategy(ds);
            % obj = DatastorePartitionStrategy(ds, numPartitions);
            %
            % The numPartitions input is optional and provides an override
            % to the suggested number of partitions.
            
            if iscell(ds)
                % Construction with a list of datastores from an existing
                % partition strategy, used by this class methods:
                % fixNumPartitions or checkPrepartitioningForThisBackEnd.
                obj.DatastoreList = ds;
                ds = ds{1};
            else
                % Main constructor with a single datastore input.
                obj.DatastoreList = {ds};
            end
            
            % Keep the first datastore as the reference datastore for this
            % strategy.
            obj.Datastore = ds;
            obj.IsPartitionable = matlab.io.datastore.internal.shim.isPartitionable(ds);
            
            % A datastore is prepartitionable if it has an Id property.
            obj.IsPrepartitionable = checkAllPrepartitionableDatastores(obj);
            
            if nargin < 2
                numPartitions = NaN;
            end
            
            % Datastores are allowed to register themselves as requiring a
            % fixed partitioning. This exists for testing purposes.
            tallSettings = matlab.bigdata.internal.TallSettings.get();
            if ~isempty(tallSettings.FixedPartitionDatastores)
                clz = class(ds);
                if clz == "matlab.io.datastore.internal.FrameworkDatastore"
                    clz = class(ds.Datastore);
                end
                if ismember(clz, tallSettings.FixedPartitionDatastores)
                    numPartitions = numpartitions(ds);
                end
            end
            
            if iscell(numPartitions)
                % Construction from an existing partition strategy, used by
                % this class methods: fixNumPartitions or
                % checkPrepartitioningForThisBackEnd.
                obj.MinNumPartitions = numPartitions{1};
                obj.MaxNumPartitions = numPartitions{2};
            elseif ~isnan(numPartitions)
                obj.MinNumPartitions = numPartitions;
                obj.MaxNumPartitions = numPartitions;
            elseif obj.IsPartitionable
                % The result of numpartitions can be 0 if there exists no
                % underlying data. We bound it because we need to have at
                % least 1 partition for type propagation to work correctly.
                try
                    obj.MaxNumPartitions = max(numpartitions(obj.Datastore), 1);
                catch err
                    matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
                end
            else
                obj.MaxNumPartitions = 1;
            end
            obj.MaxNumReadFailures = matlab.io.datastore.internal.shim.maxNumReadFailures(ds);
            
            % Set up the information about the current back-end and whether
            % the datastore can be partitioned first.
            if nargin < 3
                obj.DoPrepartitioning = false;
            else
                % To be used by checkPrepartitioningForThisBackEnd
                obj.DoPrepartitioning = isPartitioningFirst;
            end
        end
        
        function partition = createPartition(obj, partitionIndex, numPartitions, hadoopSplit)
            import matlab.bigdata.internal.executor.HadoopDatastorePartition;
            import matlab.bigdata.internal.executor.SimplePartition;
            import matlab.bigdata.internal.executor.PostpartitionablePartition;
            import matlab.bigdata.internal.executor.PrepartitionablePartition;
            if nargin >= 4
                assert(matlab.io.datastore.internal.shim.isHadoopLocationBased(obj.Datastore), ...
                    'Assertion failed: Attempted to initialize a non-Hadoop datastore with a Hadoop split.');
                partition = HadoopDatastorePartition(partitionIndex, numPartitions, hadoopSplit);
            elseif obj.DoPrepartitioning
                % If the datastores are prepartitionable and it's a
                % process-based back-end, create a partition that copies
                % its corresponding data upfront.
                partition = PrepartitionablePartition(partitionIndex, numPartitions, obj.DatastoreList);
            elseif obj.IsPrepartitionable
                % Otherwise, hold a copy of the prepartitionable datastore
                % and set up the corresponding indices for each partition.
                partition = PostpartitionablePartition(partitionIndex, numPartitions, obj.DatastoreList);
            else
                partition = SimplePartition(partitionIndex, numPartitions);
            end
        end
        
        % Return a strategy where the number of partitions is now fixed
        % to the provided value.
        function obj = fixNumPartitions(obj, numPartitions)
            obj = matlab.bigdata.internal.executor.DatastorePartitionStrategy(...
                obj.DatastoreList, numPartitions);
        end
        
        function obj = resolve(obj, defaultNumPartitionsHint, maxNumPartitionsHint, isPartitioningFirst)
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
            % Inject information about the current back-end to identify if
            % partitioning can happen first.
            obj = checkPrepartitioningForThisBackEnd(obj, isPartitioningFirst);
        end

        function tf = isKnownSinglePartition(~)
            % This should never be true since an execution backend may need
            % to enforce a partitioning based on a different strategy.  For
            % example, on Hadoop, locality / byte offset based partitioning
            % is given priority over whether the datastore reports having
            % only a single partition.
            tf = false;
        end
        
        function obj = checkPrepartitioningForThisBackEnd(obj, flag)
            % Identify and inject information about the back-end and
            % whether partitioning can happen first to this partition
            % strategy. This is injected by the current executor.
            
            % We can only do partitioning first when the datastores are
            % prepartitionable and the process-based back-end enables it.
            doPrepartitioning = obj.IsPrepartitionable && flag;
            obj = matlab.bigdata.internal.executor.DatastorePartitionStrategy(...
                obj.DatastoreList, {obj.MinNumPartitions, obj.MaxNumPartitions}, doPrepartitioning);
        end

        function options = getSerializedLocationOptions(~)
            % Build the options struct to pass to getSerializedLocation.
            options.ForceFullfile = false;
        end
    end
    
    methods (Access = protected)
        function tf = typedIsCompatible(obj, other)
            % Override of the per-type implementation of isCompatible.
            % Note, obj and other are guaranteed to both be
            % DatastorePartitionStrategy.
            
            % Early exit true if everything is equal and we don't need to
            % consider subtle aspects of compatibility.
            tf = isequal(obj, other);
            if tf
                return;
            end
            
            % If the two strategies are not equal, nor both
            % MemoryDatastore, we drop out.
            if obj.MinNumPartitions ~= other.MinNumPartitions ...
                    || obj.MaxNumPartitions ~= other.MaxNumPartitions
                return;
            end
            % DatastoreList holds a list of datastores associated to this
            % partition strategy. Taking the first one as a reference for
            % comparisons.
            if ~isa(obj.Datastore, "matlab.bigdata.internal.MemoryDatastore")
                return;
            end
            if ~isa(other.Datastore, "matlab.bigdata.internal.MemoryDatastore")
                return;
            end
            
            % MemoryDatastores of the same height are guaranteed same
            % partitioning.
            tf = isCompatible(obj.Datastore, other.Datastore);
        end

        function typedThrowIfIncompatible(obj, other)
            % Override of the per-type implementation of throwIfIncompatible.
            % Note, obj and other are guaranteed to both be
            % DatastorePartitionStrategy.
            if obj.typedIsCompatible(other)
                return;
            end
            if isa(obj.Datastore, 'matlab.bigdata.internal.MemoryDatastore') ...
                    && isa(other.Datastore, 'matlab.bigdata.internal.MemoryDatastore')
                matlab.bigdata.internal.throw(...
                    message('MATLAB:bigdata:array:IncompatibleTallIndexing'));
            else
                matlab.bigdata.internal.throw(...
                    message('MATLAB:bigdata:array:IncompatibleTallDatastore'));
            end
        end

        function obj = typedAlign(obj, other)
            % Override of the per-type implementation of align.
            % Note, obj and other are guaranteed to both be
            % DatastorePartitionStrategy.
            typedThrowIfIncompatible(obj, other);
            if obj.IsPrepartitionable && other.IsPrepartitionable
                obj = merge(obj, other);
            end
        end
    end
    
    methods (Access = {?matlab.bigdata.internal.executor.PartitionStrategy})
        function obj = merge(obj, strategy)
            % Merge information of two partition strategies to have all the
            % information relative to the underlying prepartitionable
            % datastores. This occurs when we align several partition
            % strategies to form one that will work for all inputs.
            
            assert(checkAllPrepartitionableDatastores(obj), ...
                "Expected all datastores to be prepartitionable in this strategy");
            assert(checkAllPrepartitionableDatastores(strategy), ...
                "Expected all datastores to be prepartitionable in the incoming strategy");
            
            % Only add datastores that do not already exist in the list.
            idsInObj = extractDatastoreIdsFromList(obj);
            idsInStrategy = extractDatastoreIdsFromList(strategy);
            newDatastores = ~ismember(idsInStrategy, idsInObj);
            newList = [obj.DatastoreList; strategy.DatastoreList(newDatastores)];
            obj = matlab.bigdata.internal.executor.DatastorePartitionStrategy(...
                newList, {obj.MinNumPartitions, obj.MaxNumPartitions});
        end
    end
    
    methods (Access = private)
        function tf = checkAllPrepartitionableDatastores(obj)
            tf = all(cellfun(@(x) isprop(x, "DatastoreId"), obj.DatastoreList));
        end
        
        function id = extractDatastoreIdsFromList(obj)
            % Return a cellstr with the ids of each datastore in the list.
            nDatastores = numel(obj.DatastoreList);
            id = cell(1, nDatastores);
            for ii = 1:nDatastores
                id{ii} = obj.DatastoreList{ii}.DatastoreId;
            end
        end
    end
end
