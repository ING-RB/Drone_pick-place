function n = maxpartitions(nds)
%

%   Copyright 2021 The MathWorks, Inc.

    nds.verifyPartitionable();

    % NestedDatastore partitions at the outer datastore's granularity.
    n = nds.OuterDatastore.numpartitions();
end
