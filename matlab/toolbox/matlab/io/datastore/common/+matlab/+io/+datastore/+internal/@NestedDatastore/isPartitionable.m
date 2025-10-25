function tf = isPartitionable(nds)
%isPartitionable   Returns true if this datastore is partitionable.

%   Copyright 2021 The MathWorks, Inc.

    % NestedDatastore partitions at the outer datastore's granularity.
    tf = nds.OuterDatastore.isPartitionable();
end
