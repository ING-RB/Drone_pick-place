%OutputCommunicationType
% An enumeration of the different output communication types supported by
% ExecutionTask.
%

%   Copyright 2015-2018 The MathWorks, Inc.

classdef OutputCommunicationType
    enumeration
        % Non-communicating output.
        Simple
        
        % Communication from N partitions to 1 partition.
        AllToOne
        
        % Arbitrary communication from N partitions to M partition.
        AnyToAny
        
        % The output will be padded with empty partitions, either prepended
        % to the beginning, appended to the end or both. This requires the
        % OutputPartitionStrategy to be a ConcatenatedPartitionStrategy.
        PadWithEmptyPartitions;

        % Communication from 1 partition to N partitions.
        Broadcast
        
        % Communication from each partition to itself. This is used as a
        % placeholder for IsPassBoundary in the implementation of
        % convertToIndependentTasks. It will not be used outside of this.
        SameToSame
    end
end
