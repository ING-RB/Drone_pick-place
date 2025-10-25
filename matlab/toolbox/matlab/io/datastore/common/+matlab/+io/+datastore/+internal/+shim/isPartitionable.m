function tf = isPartitionable(ds)
%isPartitionable Compatibility layer for checking for Partitionable support

%   Copyright 2017-2019 The MathWorks, Inc.

if matlab.io.datastore.internal.shim.isV1ApiDatastore(ds)
    tf = isa(ds, 'matlab.io.datastore.SplittableDatastore');
elseif isa(ds, 'matlab.io.datastore.internal.FrameworkDatastore')
    tf = ds.IsPartitionable;
elseif isa(ds,'matlab.io.datastore.TransformedDatastore')
    tf = matlab.io.datastore.internal.shim.isPartitionable(ds.UnderlyingDatastore);
else
    tf = ds.isPartitionable();
end
