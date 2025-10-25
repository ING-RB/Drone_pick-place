function verifyPartitionable(ds, methodName)
%verifyPartitionable   Throws if the underlying datastore is not partitionable.

%   Copyright 2021 The MathWorks, Inc.

    if ~ds.isPartitionable()
        msgid = "MATLAB:io:datastore:common:validation:InvalidTraitValue";
        error(message(msgid, methodName, "partitionable"));
    end
end
