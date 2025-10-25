%PartitionContext
% Context for the currently running partition.
%
% This manages state relevant during execuction of one partition. This includes:
%  - Constant metadata (E.G. partition index)
%  - List of read failures so far
%  - Broadcasts made available to the partition or created during the partition
%

%   Copyright 2018-2019 The MathWorks, Inc.

classdef (Sealed) PartitionContext < handle
    properties (Dependent)
        % The index of this partition with the total number of partitions.
        PartitionIndex
        
        % The number of partitions in the strategy.
        NumPartitions
    end
    
    properties (Access = private)
        % Metadata about the currently running partition
        Partition (1,1)
        
        % An accumulator of read failures collected during the currently
        % running partition.
        ReadFailureAccumulator (1,1)
        
        % A map of broadcasts used or created during the lifetime of this
        % partition. This must be a
        % matlab.bigdata.internal.executor.BroadcastMap or something that
        % exposes the same API. If unused, an environment is allowed to set
        % this to empty.
        BroadcastMap
    end
    
    methods
        function obj = PartitionContext(partition, broadcastMap, maxNumReadFailures)
            % Build a partition context around the given partition.
            % Optionally, a maximum number of read failures can be provided
            % to allow the partition to error early if too many read
            % failures.
            obj.Partition = partition;
            assert(isempty(broadcastMap) ...
                || isa(broadcastMap, "matlab.bigdata.internal.executor.BroadcastMap") ...
                || isa(broadcastMap, "parallel.internal.bigdata.ParallelPoolBroadcastMap"), ...
                "Assertion Failed: Broadcast map must be a valid type");
            obj.BroadcastMap = broadcastMap;
            if nargin < 3
                maxNumReadFailures = inf;
            end
            obj.ReadFailureAccumulator = matlab.bigdata.internal.executor.ReadFailureAccumulator(maxNumReadFailures);
        end
        
        function addReadFailures(obj, readFailureSummary)
            % Add the given read failure information to the collection of
            % known failures.
            obj.ReadFailureAccumulator.append(readFailureSummary);
        end
        
        function summary = getReadFailureSummary(obj)
            % Get a summary of all read failures.
            summary = obj.ReadFailureAccumulator.Summary;
        end
        
        function addBroadcast(obj, key, value)
            % Add a broadcast identified by key to the BroadcastMap for the
            % partition.
            assert(~isempty(obj.BroadcastMap), ...
                "Assertion Failed: Attempted to set a broadcast when this logic is not enabled.");
            if obj.NumPartitions == 1
                obj.BroadcastMap.set(key, value);
            else
                obj.BroadcastMap.setPartitions(key, obj.PartitionIndex, {value});
            end
        end
        
        function broadcast = getBroadcast(obj, key)
            % Get the broadcast identified by key from the BroadcastMap for
            % the partition.
            assert(~isempty(obj.BroadcastMap), ...
                "Assertion Failed: Attempted to get a broadcast when this logic is not enabled.");
            broadcast = obj.BroadcastMap.get(key);
        end
    end
    
    % Forwarding methods to make this look like a partition. This is a
    % short term measure while we migrate DataProcessor implementations to
    % the new structure.
    methods
        function index = get.PartitionIndex(obj)
            index = obj.Partition.PartitionIndex;
        end
        
        function N = get.NumPartitions(obj)
            N = obj.Partition.NumPartitions;
        end
        
        function ds = partitionDatastore(obj, ds)
            % Partition a datastore to provide the partition of data matching
            % this partition object.
            ds = partitionDatastore(obj.Partition, ds);
        end
        
        %mapToSubStrategy Map a partition from a ConcatenatedPartitionStrategy
        % to the partition that the sub-strategy of given index subIndex would
        % have created.
        function out = mapToSubStrategy(obj, subIndex)
            out = mapToSubStrategy(obj.Partition, subIndex);
        end
    end
end
