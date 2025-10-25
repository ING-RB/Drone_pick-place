%SimplePartition
% Partition class representing a simple index into the number of partitions.
%

%   Copyright 2015-2019 The MathWorks, Inc.


classdef (Sealed) SimplePartition < matlab.bigdata.internal.executor.Partition
    % Overrides of Partition interface.
    methods
        % Partition a datastore to provide the partition of data matching
        % this partition object.
        function ds = partitionDatastore(obj, ds)
            try
                if obj.NumPartitions == 1
                    ds = copy(ds);
                else
                    ds = partition(ds, obj.NumPartitions, obj.PartitionIndex);
                end
                reset(ds);
            catch err
                matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
            end
        end
    end
end
