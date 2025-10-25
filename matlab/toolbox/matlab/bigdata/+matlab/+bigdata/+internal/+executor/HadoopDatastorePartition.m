%HadoopDatastorePartition
% A partition that is based on the Hadoop special-case form of partitioning
% on a file-based datastore.
%
% This has the ability to construct a datastore for the current partition.

%   Copyright 2015-2019 The MathWorks, Inc.

classdef (Sealed) HadoopDatastorePartition < matlab.bigdata.internal.executor.Partition
    properties (GetAccess = private, SetAccess = immutable)
        % If a Hadoop split was used to create this partition, this is that
        % split.
        HadoopSplit;
    end
    
    methods
        function obj = HadoopDatastorePartition(partitionIndex, numPartitions, hadoopSplit)
            % Build a partition that has attached Hadoop split information.
            obj = obj@matlab.bigdata.internal.executor.Partition(partitionIndex, numPartitions);
            obj.HadoopSplit = hadoopSplit;
        end
    end
    
    % Overrides of Partition interface.
    methods
        % Partition a datastore to provide the partition of data matching
        % this partition object.
        function ds = partitionDatastore(obj, ds)
            try
                ds = copy(ds);
                matlab.io.datastore.internal.shim.initializeDatastore(ds, obj.HadoopSplit);
            catch err
                matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
            end
        end
    end
end
