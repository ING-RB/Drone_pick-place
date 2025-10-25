function verifyShuffleable(ds, methodName)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

if ~ds.isShuffleable()
    ds.buildInvalidTraitError(methodName, 'isShuffleable', 'shuffleable');
end
end