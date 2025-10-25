function mustBeDatastore(ds, msgid)
%mustBeDatastore   Throws if the input is not a datastore subclass.

%   Copyright 2021-2022 The MathWorks, Inc.

    if nargin == 1
        msgid = "MATLAB:io:datastore:common:validation:InvalidDatastoreInput";
    end
    
    import matlab.io.datastore.internal.validators.isDatastore;
    if ~isDatastore(ds)
        error(message(msgid));
    end
end