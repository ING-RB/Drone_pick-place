%FullfilePartition
% Partition representing a simple index into the number of files.
%

%   Copyright 2019 The MathWorks, Inc.


classdef (Sealed) FullfilePartition < matlab.bigdata.internal.executor.Partition
    % Overrides of Partition interface.
    methods
        % Partition a datastore to provide the partition of data matching
        % this partition object.
        function ds = partitionDatastore(obj, ds)
            try
                ds = partition(ds, 'Files', obj.PartitionIndex);
                reset(ds);
            catch err
                matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
            end
        end
    end
end
