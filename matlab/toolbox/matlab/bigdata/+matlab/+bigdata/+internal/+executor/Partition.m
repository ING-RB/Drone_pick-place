%Partition
% Abstract base class for all objects that represent partition-wide
% constant metadata.
%

%   Copyright 2019 The MathWorks, Inc.

classdef (Abstract) Partition < handle
    properties (SetAccess = immutable)
        % The index of this partition with the total number of partitions.
        PartitionIndex (1,1) double
        
        % The number of partitions in the strategy.
        NumPartitions (1,1) double
    end
    
    methods
        % The main constructor.
        function obj = Partition(partitionIndex, numPartitions)
            validateattributes(partitionIndex, {'double'}, {'positive', 'integer', 'scalar'});
            validateattributes(numPartitions, {'double'}, {'positive', 'integer', 'scalar'});
            obj.PartitionIndex = partitionIndex;
            obj.NumPartitions = numPartitions;
        end
    end
    
    methods (Abstract)
        % Partition a datastore to provide the partition of data matching
        % this partition object.
        %
        %  pds = partitionDatastore(obj, ds) partitions ds to match the
        %  partition. The returned datastore is guaranteed to be a copy or
        %  a partition of the original.
        pds = partitionDatastore(obj, ds);
    end
end
