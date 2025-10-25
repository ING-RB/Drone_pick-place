function tf = isPartitionable(ds)
%isPartitionable   Returns true if this datastore is partitionable.

%   Copyright 2021 The MathWorks, Inc.

    tf = ds.UnderlyingDatastore.isPartitionable();
end
