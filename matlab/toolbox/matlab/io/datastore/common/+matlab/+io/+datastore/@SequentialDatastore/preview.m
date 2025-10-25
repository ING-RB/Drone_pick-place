function data = preview(ds)
%PREVIEW   Preview the data contained in the datastore.
%   T = preview(DS) Returns a small amount of data from the start
%   of the first non-empty underlying datastore. If all underlying
%   datastores are empty, preview will return the empty type from
%   the first underlying datastore. If no underlying datastores,
%   preview will return an empty double.
%
%   See also read, hasdata, reset, readall.

%   Copyright 2022 The MathWorks, Inc.

try
    % Empty SequentialDatastore.
    if isempty(ds.UnderlyingDatastores)
        data = readall(ds);
        return
    end

    dscopy = copy(ds);
    reset(dscopy);

    if hasdata(dscopy)
        data = getFirstNonEmptyPreview(dscopy);
    else
        % All underlying datastores are empty, return empty preview type of
        % the first underlying datastore.
        data = preview(dscopy.UnderlyingDatastores{1});
    end
catch causeException
    msgid = "MATLAB:io:datastore:common:sequentialdatastore:PreviewError";
    baseException = MException(msgid, message(msgid));
    baseException = addCause(baseException, causeException);
    throwAsCaller(baseException);
end
end