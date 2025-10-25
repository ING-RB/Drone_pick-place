function n = maxpartitions(ds)
%maxpartitions   Returns the maximum number of partitions
%   that this datastore can be divided into.

%   Copyright 2021-2022 The MathWorks, Inc.

    try
        ds.verifyPartitionable("numpartitions");

        n = ds.UnderlyingDatastore.numpartitions();
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
