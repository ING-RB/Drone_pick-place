%PostpartitionablePartition
% Partition class for prepartitionable datastores that sets the
% corresponding indices to extract the data from a datastore afterwards.
% This is used when the partitioning must happen after the datastore is
% sent to the workers.
%
% See also: PrepartitionablePartition.

%   Copyright 2020 The MathWorks, Inc.


classdef (Sealed) PostpartitionablePartition < matlab.bigdata.internal.executor.Partition
    properties (SetAccess = immutable)
        % List of memory datastores that belong to this partition strategy.
        DatastoreList = {}
        
        % Cell array containing the datastore id where each partition comes
        % from.
        OriginalDatastoreIds
    end
    
    % Overrides of Partition interface.
    methods
        % Main constructor
        function obj = PostpartitionablePartition(partitionIndex, numPartitions, datastoreList)
            % Build a partition that contains indices to a portion of the
            % given datastores.
            obj = obj@matlab.bigdata.internal.executor.Partition(partitionIndex, numPartitions);
            
            % Keep the id of the datastore used to create this partition
            nDatastores = numel(datastoreList);
            datastoreIds = cell(1, nDatastores);
            for ii = 1:nDatastores
                datastoreIds{ii} = datastoreList{ii}.DatastoreId;
            end
            obj.OriginalDatastoreIds = datastoreIds;
            obj.DatastoreList = datastoreList;
        end
        
        % Partition a datastore with indices to provide the partition of
        % data matching this partition object.
        function ds = partitionDatastore(obj, ds)
            % Partition the datastore by copying the datastore to later on
            % access data with the given indices.
            idx = contains(obj.OriginalDatastoreIds, ds.DatastoreId);
            originalDatastore = obj.DatastoreList{find(idx, 1, 'first')};
            try
                if obj.NumPartitions == 1
                    ds = copy(originalDatastore);
                else
                    ds = partition(originalDatastore, obj.NumPartitions, obj.PartitionIndex);
                end
                reset(ds);
            catch err
                matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
            end
        end
    end
end
