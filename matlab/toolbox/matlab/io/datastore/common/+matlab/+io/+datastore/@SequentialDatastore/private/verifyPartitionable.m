function verifyPartitionable(ds, methodName)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

if ~ds.isPartitionable()
    ds.buildInvalidTraitError(methodName, 'isPartitionable', 'partitionable');
end
end