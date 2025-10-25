function partds = partition(nds, N, index)
%PARTITION Return a partitioned part of the Datastore.
%
%   SUBDS = PARTITION(DS,N,INDEX) partitions DS into
%   N parts and returns the partitioned Datastore, SUBDS,
%   corresponding to INDEX. An estimate for a reasonable value for
%   N can be obtained by using the NUMPARTITIONS function.
%
%   See also matlab.io.datastore.Partitionable, numpartitions,
%   maxpartitions.

%   Copyright 2021 The MathWorks, Inc.

    import matlab.io.datastore.internal.NestedDatastore;

    nds.verifyPartitionable();

    % NestedDatastore operates at the outer datastore's granularity.
    % So just partition the outer datastore and return a NestedDatastore
    % that iterates over it.
    outerPartDs = nds.OuterDatastore.partition(N, index);
    partds = NestedDatastore(outerPartDs, nds.InnerDatastoreFcn, IncludeInfo=nds.IncludeInfo);
end
