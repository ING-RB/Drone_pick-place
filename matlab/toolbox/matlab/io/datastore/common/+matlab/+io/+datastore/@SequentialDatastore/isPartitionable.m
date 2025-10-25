function tf = isPartitionable(ds)
%isPartitionable   returns true if this datastore is partitionable
%
%   A SequentialDatastore is only partitionable when
%   all of its underlying datastores are partitionable.
%
%   See also: isShuffleable, partition, numpartitions, subset

%   Copyright 2022 The MathWorks, Inc.

tf = all(cellfun(@isPartitionable, ds.UnderlyingDatastores));
end