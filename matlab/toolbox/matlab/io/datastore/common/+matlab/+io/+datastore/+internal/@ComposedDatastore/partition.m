function newds = partition(ds, n, index)
%PARTITION   Return a new datastore containing a part of the original datastore.
%
%   NEWDS = PARTITION(DS, N, INDEX) partitions DS into
%       N parts and returns the partitioned Datastore, NEWDS,
%       corresponding to INDEX. An estimate for a reasonable
%       value for N can be obtained by using the NUMPARTITIONS
%       function.
%
%   A datastore is only partitionable when the isPartitionable
%   method returns true.
%
%   See also: isPartitionable, numpartitions

%   Copyright 2021-2022 The MathWorks, Inc.

    try
        ds.verifyPartitionable("partition");

        newds = copy(ds);
        newds.UnderlyingDatastore = ds.UnderlyingDatastore.partition(n, index);
        newds.reset();
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
