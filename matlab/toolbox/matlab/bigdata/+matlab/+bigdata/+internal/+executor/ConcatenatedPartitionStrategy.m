%ConcatenatedPartitionStrategy
% Partition strategy that represents the concatenation of 1 or more
% strategies. This exists to allow Backends to be aware about tall/vertcat.

%   Copyright 2018-2020 The MathWorks, Inc.

classdef (Sealed) ConcatenatedPartitionStrategy < matlab.bigdata.internal.executor.PartitionStrategy
    % Overrides of PartitionStrategy properties.
    properties (SetAccess = immutable)
        MinNumPartitions
        
        MaxNumPartitions
        
        IsDatastorePartitioning = false
        
        IsBroadcast = false
        
        MaxNumReadFailures
    end
    
    properties (SetAccess = immutable)
        % A cell array of PartitionStrategy objects whose vertical
        % concatenation is represented by this
        % ConcatenatedPartitionStrategy.
        Strategies (1,:) cell
    end
    
    methods
        function obj = ConcatenatedPartitionStrategy(varargin)
            % Build a ConcatenatedPartitionStrategy from 1 or more input
            % strategies.
            %
            %  obj = ConcatenatedPartitionStrategy(strategy1,strategy2,..)
            minNumPartitions = 0;
            maxNumPartitions = 0;
            maxNumReadFailures = 0;
            for ii = 1:nargin
                assert(isa(varargin{ii}, "matlab.bigdata.internal.executor.PartitionStrategy"), ...
                    "Assertion Failed: ConcatenatedPartitionStrategy requires all inputs to be PartitionStrategy objects.");
                minNumPartitions = minNumPartitions + varargin{ii}.MinNumPartitions;
                maxNumPartitions = maxNumPartitions + varargin{ii}.MaxNumPartitions;
                maxNumReadFailures = maxNumReadFailures + varargin{ii}.MaxNumReadFailures;
            end
            obj.Strategies = varargin;
            obj.MinNumPartitions = minNumPartitions;
            obj.MaxNumPartitions = maxNumPartitions;
            obj.MaxNumReadFailures = maxNumReadFailures;
        end
        
        % Create a partition object that represents the given partition
        % index.
        function partition = createPartition(obj, partitionIndex, numPartitions)
            import matlab.bigdata.internal.executor.ConcatenatedPartition;
            
            subNumPartitions = obj.divideNumPartitions(numPartitions);
            subPartitionIndex = partitionIndex;
            for subIndex = 1:numel(subNumPartitions)
                if subPartitionIndex <= subNumPartitions(subIndex)
                    break;
                end
                subPartitionIndex = subPartitionIndex - subNumPartitions(subIndex);
            end
            
            underlyingPartition = obj.Strategies{subIndex}.createPartition(...
                subPartitionIndex, subNumPartitions(subIndex));
            partition = ConcatenatedPartition(partitionIndex, numPartitions, ...
                subIndex, underlyingPartition);
        end
        
        % Return a strategy where the number of partitions is now fixed
        % to the provided value.
        function obj = fixNumPartitions(obj, numPartitions)
            subNumPartitions = obj.divideNumPartitions(numPartitions);
            strategies = obj.Strategies;
            for ii = 1:numel(strategies)
                strategies{ii} = fixNumPartitions(strategies{ii}, subNumPartitions(ii));
            end
            obj = matlab.bigdata.internal.executor.ConcatenatedPartitionStrategy(...
                strategies{:});
        end
        
        function obj = resolve(obj, defaultNumPartitionsHint, maxNumPartitionsHint, isPartitioningFirst)
            % Resolve a partition strategy to the actual strategy and
            % number of partitions to be used by an environment. This
            % receives hints from the environment about ideal number of
            % partitions, but it is completely up-to the strategy to choose
            % actual number of partitions.
            %
            % This is an override of the default PartitionStrategy behavior
            % that applies the hints to each child strategy in isolation
            % instead of to the concatenated strategy.
            %
            % This exists because of the dangers of partition dependent
            % results, E.G. random numbers. If the tX component of [tX;tY]
            % has a different number of partitions to tX, then all random
            % numbers will be different. So we apply the strategy rules per
            % component, instead of to the whole.
            strategies = obj.Strategies;
            for ii = 1:numel(strategies)
                strategies{ii} = resolve(strategies{ii}, ...
                    defaultNumPartitionsHint, maxNumPartitionsHint, isPartitioningFirst);
            end
            obj = matlab.bigdata.internal.executor.ConcatenatedPartitionStrategy(...
                strategies{:});
        end
        
        function partition = mapPartition(obj, subIndex, partition)
            % Map a partition object from one of the underlying strategies
            % into a partition object from ConcatenatedPartitionStrategy.
            %
            % partition = mapPartition(obj, subPartition, subIndex)
            assert(obj.isResolved(), ...
                'Assertion failed: mapPartition is only supported for resolved strategies');
            assert(partition.NumPartitions == numpartitions(obj.Strategies{subIndex}), ...
                'Assertion failed: Partition object has a different number of partitions than expected');
            base = 0;
            for ii = 1:subIndex - 1
                base = base + numpartitions(obj.Strategies{ii});
            end
            partition = matlab.bigdata.internal.executor.ConcatenatedPartition(...
                base + partition.PartitionIndex, numpartitions(obj), subIndex, partition);
        end
        
        function n = numPartitionsToPrepend(obj, subIndex)
            % Return the number of partitions necessary to prepend to make
            % the Strategy of given subIndex align with this strategy.
            assert(obj.isResolved(), ...
                'Assertion failed: mapPartition is only supported for resolved strategies');
            n = 0;
            for ii = 1:subIndex - 1
                n = n + numpartitions(obj.Strategies{ii});
            end
        end
        
        function n = numPartitionsToAppend(obj, subIndex)
            % Return the number of partitions necessary to append to make
            % the Strategy of given subIndex align with this strategy.
            n = 0;
            for ii = subIndex + 1 : numel(obj.Strategies)
                n = n + numpartitions(obj.Strategies{ii});
            end
        end

        function tf = isKnownSinglePartition(obj)
            % Return a logical scalar whether this partition strategy knows
            % it has exactly one partition.
            tf = obj.MaxNumPartitions <= 1;
        end
    end

    methods (Access = protected)
        function tf = typedIsCompatible(obj, other)
            % Override of the per-type implementation of isCompatible.
            % Note, obj and other are guaranteed to both be
            % ConcatenatedPartitionStrategy.
            if numel(obj.Strategies) ~= numel(other.Strategies)
                tf = false;
                return;
            end
            tf = true;
            for ii = 1:numel(obj.Strategies)
                tf = tf && isCompatible(obj.Strategies{ii}, other.Strategies{ii});
            end
        end

        function typedThrowIfIncompatible(obj, other)
            % Override of the per-type implementation of throwIfIncompatible.
            % Note, obj and other are guaranteed to both be
            % ConcatenatedPartitionStrategy.
            if numel(obj.Strategies) ~= numel(other.Strategies)
                matlab.bigdata.internal.throw(...
                    message('MATLAB:bigdata:array:IncompatibleTallIndexing'));
            end
            for ii = 1:numel(obj.Strategies)
                throwIfIncompatible(obj.Strategies{ii}, other.Strategies);
            end
        end

        function obj = typedAlign(obj, other)
            % Override of the per-type implementation of align.
            % Note, obj and other are guaranteed to both be
            % ConcatenatedPartitionStrategy.
            if isequal(obj, other)
                return;
            end
            if numel(obj.Strategies) ~= numel(other.Strategies)
                matlab.bigdata.internal.throw(...
                    message('MATLAB:bigdata:array:IncompatibleTallIndexing'));
            end
            strategies = obj.Strategies;
            for ii = 1:numel(strategies)
                strategies{ii} = align(strategies{ii}, other.Strategies{ii});
            end
            obj = ConcatenatedPartitionStrategy(strategies{:});
        end
    end
    
    methods (Access = private)
        function values = divideNumPartitions(obj, numPartitions)
            % Divide the requested number of partitions across all
            % underlying partition strategies.
            
            minValues = cellfun(@getMinNumPartitions, obj.Strategies);
            maxValues = cellfun(@getMaxNumPartitions, obj.Strategies);
            % For simplicity, we make all maximums finite.
            maxValues(isinf(maxValues)) = numPartitions;
            
            % First attempt, see whether MinNumPartitions already consumes
            % all partitions.
            values = minValues;
            numRemaining = numPartitions - sum(values);
            if numRemaining == 0
                return;
            end
            assert(numRemaining >= 0, ...
                'Assertion failed: Not enough partitions');
            
            % Next attempt, spread partitions across underlying strategies
            % weighed by max - min.
            x = maxValues - minValues;
            x = (x / sum(x)) * numRemaining;
            
            values = values + floor(x);
            numRemaining = numPartitions - sum(values);
            if numRemaining == 0
                return;
            end
            
            % In cases where partitions do not divide evenly, we need to
            % pigeon-hole the remaining partitions.
            idx = find(x ~= floor(x), numRemaining);
            values(idx) = values(idx) + 1;
        end
    end
end
