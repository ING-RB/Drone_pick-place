function verifySubsettable(ds, methodName)
%verifySubsettable   Throws if the underlying datastore is not subsettable.

%   Copyright 2021 The MathWorks, Inc.

    if ~ds.isSubsettable()
        msgid = "MATLAB:io:datastore:common:validation:InvalidTraitValue";
        error(message(msgid, methodName, "subsettable"));
    end
end
