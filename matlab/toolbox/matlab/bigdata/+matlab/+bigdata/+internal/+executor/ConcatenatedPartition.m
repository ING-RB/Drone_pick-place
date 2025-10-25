%ConcatenatedPartition
% A partition that originates from a ConcatenatedPartitionStrategy. This
% has both:
%  1. Partition information respective to the entire ConcatenatedPartitionStrategy
%  2. Partition information respective to the strategy of the subsection of
%     ConcatenatedPartitionStrategy  that this partition corresponds against.
%
% For example, suppose:
%  subStrategy1 = FixedNumPartitionStrategy(2);
%  subStrategy2 = FixedNumPartitionStrategy(3);
%  concatStrategy = vertcatPartitionStrategies(subStrategy1, subStrategy2);
%
% Partition 3 of concatStrategy will know both:
%  1. It is partition 3 of 5 with respective to concatStrategy.
%  2. It is partition 1 of 3 with respective to underlying subStrategy2.
%

%   Copyright 2018-2019 The MathWorks, Inc.


classdef (Sealed) ConcatenatedPartition < matlab.bigdata.internal.executor.Partition
    properties (SetAccess = immutable)
        % Index into the array of underlying Strategies of the
        % ConcatenatedPartitionStrategy that this partition corresponds
        % against.
        SubIndex (1,1) double
        
        % Partition object from the underlying Strategy that this
        % partition corresponds against.
        SubPartition (1,1)
    end
    
    methods
        function obj = ConcatenatedPartition(partitionIndex, numPartitions, subIndex, subPartition)
            % Wrap a partition with respect to one part of a concatenated
            % tall array into a partition with respected to the
            % concatenated whole.
            obj = obj@matlab.bigdata.internal.executor.Partition(partitionIndex, numPartitions);
            obj.SubIndex = subIndex;
            obj.SubPartition = subPartition;
        end
        
        function out = mapToSubStrategy(obj, subIndex)
            % Map a partition from a ConcatenatedPartitionStrategy to the
            % partition that the sub-strategy of given index subIndex would
            % have created. This will return empty if this partition does
            % not belong to subIndex.
            if subIndex == obj.SubIndex
                out = obj.SubPartition;
            else
                out = [];
            end
        end
    end
    
    % Overrides of Partition interface.
    methods
        % Partition a datastore to provide the partition of data matching
        % this partition object.
        function ds = partitionDatastore(obj, ds)
            ds = partitionDatastore(obj.SubPartition, ds);
        end
    end
end
