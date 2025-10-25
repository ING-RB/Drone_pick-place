function verifyShuffleable(ds, methodName)
%verifyShuffleable   Throws if the underlying datastore is not shuffleable.

%   Copyright 2021 The MathWorks, Inc.

    if ~ds.isShuffleable()
        msgid = "MATLAB:io:datastore:common:validation:InvalidTraitValue";
        error(message(msgid, methodName, "shuffleable"));
    end
end
