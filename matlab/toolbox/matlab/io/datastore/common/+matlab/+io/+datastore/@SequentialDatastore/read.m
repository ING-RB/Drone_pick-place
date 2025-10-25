function [data, info] = read(ds)
%READ   Read data and information about the extracted data
%
%   DATA = READ(DS) returns the data read from the current
%   underlying datastores in this SequentialDatastore.
%
%   [DATA, INFO] = read(DS) also returns the second output of
%   the READ method on the current underlying datastore.
%
%   See also hasdata, reset, readall, preview

%   Copyright 2022 The MathWorks, Inc.

if hasdata(ds)
    while ~hasdata(ds.UnderlyingDatastores{ds.CurrentDatastoreIndex})
        ds.CurrentDatastoreIndex = ds.CurrentDatastoreIndex + 1;
    end

    try
        currentDatastore = ds.UnderlyingDatastores{ds.CurrentDatastoreIndex};
        [data, info] = read(currentDatastore);
    catch causeException
        msgid = "MATLAB:io:datastore:common:sequentialdatastore:ReadError";
        baseException = MException(msgid, message(msgid, ds.CurrentDatastoreIndex));
        baseException = addCause(baseException, causeException);
        throw(baseException);
    end
    data = matlab.io.datastore.internal.read.iMakeUniform(data, currentDatastore);
else
    msg = message("MATLAB:io:datastore:common:read:NoMoreData");
    throwAsCaller(MException(msg));
end
end