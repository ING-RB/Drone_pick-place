%PrepartitionablePartition
% Partition class for prepartitionable datastores that partitions upfront
% and holds a copy of a portion of the data. This is used when the
% partitioning can happen before the datastore is sent to the workers,
% minimizing data transfer.
%
% See also: PostpartitionablePartition.

%   Copyright 2020 The MathWorks, Inc.


classdef (Sealed) PrepartitionablePartition < matlab.bigdata.internal.executor.Partition
    properties (SetAccess = immutable)
        % Cell array containing the n partition of all input data.
        PartitionedData
        
        % Cell array containing the datastore id where each partition comes
        % from.
        OriginalDatastoreIds
    end
    
    % Overrides of Partition interface.
    methods
        % Main constructor
        function obj = PrepartitionablePartition(partitionIndex, numPartitions, datastoreList)
            % Build a partition that contains a portion of the data.
            obj = obj@matlab.bigdata.internal.executor.Partition(partitionIndex, numPartitions);
            
            % Create partitioned memory datastore and extract the
            % corresponding data to be hold by this partition.
            nDatastores = numel(datastoreList);
            partitionedData = cell(1, nDatastores);
            datastoreIds = cell(1, nDatastores);
            for ii = 1:nDatastores
                partitionedDatastore = partition(datastoreList{ii}, obj.NumPartitions, obj.PartitionIndex);
                partitionedData{ii} = readall(partitionedDatastore);
                % Keep the id of the datastore used to create this partition
                datastoreIds{ii} = datastoreList{ii}.DatastoreId;
            end
            obj.PartitionedData = partitionedData;
            obj.OriginalDatastoreIds = datastoreIds;
        end
        
        % partitionDatastore injects the corresponding data of this
        % partition to the original datastore with an empty chunk in ds.
        function ds = partitionDatastore(obj, ds)
            % Replace the underlying empty data in ds with the
            % PartitionedData of this partition if the original datastore
            % ids match.
            idx = contains(obj.OriginalDatastoreIds, ds.DatastoreId);
            ds = copy(ds);
            ds.Data = obj.PartitionedData{find(idx, 1, 'first')};
            % Reset datastore to set up indices with respect to this
            % partition.
            ds.PartitionEnd = size(ds.Data, 1);
            reset(ds);
        end
    end
end
