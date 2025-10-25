function verifySubsettable(ds, methodName)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

if ~ds.isSubsettable()
    ds.buildInvalidTraitError(methodName, 'isSubsettable', 'subsettable');
end
end