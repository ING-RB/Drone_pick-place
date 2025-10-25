function newds = partition(rds, NumPartitions, Index)
%PARTITION   Returns a partitioned portion of the RangeDatastore.
%
%   NEWDS = PARTITION(RDS, NUMPARTITIONS, I) partitions a RangeDatastore
%       into NUMPARTITIONS parts and returns the I-th part as a new RangeDatastore.
%
%   See also: numpartitions

%   Copyright 2021 The MathWorks, Inc.

    arguments
        rds           (1, 1) matlab.io.datastore.internal.RangeDatastore
        NumPartitions (1, 1) double {mustBePositive, mustBeInteger}
        Index         (1, 1) double {mustBePositive, mustBeInteger, mustBeLessThanOrEqual(Index, NumPartitions)}
    end

    import matlab.io.datastore.internal.RangeDatastore;
    import matlab.io.datastore.internal.util.pigeonHole;

    % Slice the range using common datastore partitioning logic.
    % So if you have:
    %    rds = rangeDatastore(Start=5, End=10);
    %    partition(rds, 3, 2);
    % This would supply:
    %    TotalNumValues -> 6
    %    NumPartitions -> 3
    %    Index -> 2
    % Which results in:
    %    ValueIndices -> [3, 4]
    ValueIndices = pigeonHole(NumPartitions, rds.TotalNumValues, Index);

    if isempty(ValueIndices)
        % Empty partition. Return different RangeDatastores depending on the cause.
        if rds.TotalNumValues == 0
            % The original RangeDatastore was empty. Return a similar empty RangeDatastore.
            newds = RangeDatastore(Start=rds.Start, End=rds.End, ReadSize=rds.ReadSize);
            return;
        else
            % The original RangeDatastore was non-empty, but the requested partition index
            % corresponds to a partition with no data.
            % Due to Nimit's fixes to the pigeon-hole algorithm, this is guaranteed to
            % only happen after all valid (data-holding) partition indices. So preserve the
            % End value, and set the Start value to 1 past the End to make it empty.
            newds = RangeDatastore(Start=rds.End+1, End=rds.End, ReadSize=rds.ReadSize);
            return;
        end
    end

    % The pigeon-hole algorithm used here always returns a contiguous range
    % of value indices. The range of these indices defines the parameters for
    % the partitioned RangeDatastore.
    NewStartValue = ValueIndices(1) + rds.Start - 1;
    NewEndValue = ValueIndices(end) + rds.Start - 1;
    newds = RangeDatastore(Start=NewStartValue, End=NewEndValue, ReadSize=rds.ReadSize);
end
