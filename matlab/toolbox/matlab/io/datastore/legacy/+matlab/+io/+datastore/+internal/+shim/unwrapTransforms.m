function outds = unwrapTransforms(ds)
% Unwrap TransformedDatastore to get the underlying datastore.

%   Copyright 2019 The MathWorks, Inc.

% If the underlying datastore is invalid, we don't want to modify it prior
% to an operation that will issue a useful error message.
outds = ds;

isWrappedByFrameworkDatastore = isa(ds, "matlab.io.datastore.internal.FrameworkDatastore");
if isWrappedByFrameworkDatastore
    ds = ds.Datastore;
end

if isa(ds, "matlab.io.datastore.TransformedDatastore")
    ds = ds.UnderlyingDatastore;
end

% Underlying datastore is invalid.
if isempty(ds)
    return;
end

% Need to rewrap the underlying datastore in FrameworkDatastore to ensure
% nice errors are issued if the underlying datastore is incorrectly
% implemented.
if isWrappedByFrameworkDatastore ...
        && matlab.io.datastore.internal.shim.isV2ApiDatastore(ds)
    ds = matlab.io.datastore.internal.FrameworkDatastore(ds);
end

outds = ds;

end
