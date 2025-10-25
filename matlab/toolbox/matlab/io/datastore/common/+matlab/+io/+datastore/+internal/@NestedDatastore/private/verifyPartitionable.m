function verifyPartitionable(nds)
%verifyPartitionable   Throws if the underlying datastore is not partitionable.

%   Copyright 2021 The MathWorks, Inc.

    if ~nds.isPartitionable()
        msgid = "MATLAB:io:datastore:common:validation:UnderlyingDatastoreMustBePartitionable";
        error(message(msgid));
    end
end
