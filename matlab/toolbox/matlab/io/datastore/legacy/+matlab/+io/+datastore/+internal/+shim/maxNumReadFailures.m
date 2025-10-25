function n = maxNumReadFailures(ds)
%maxNumReadFailures Get the maximum number of read failures allowed by the
%given datastore.

%   Copyright 2018 The MathWorks, Inc.

% Unwrap various decorators/transform objects sitting on top of the source
% datastore.
if isa(ds, "matlab.io.datastore.internal.FrameworkDatastore")
    ds = ds.Datastore;
end
if isa(ds, "matlab.io.datastore.TransformedDatastore")
    ds = ds.UnderlyingDatastore;
end

if isa(ds, "matlab.io.datastore.FileBasedDatastore")
    n = ds.MaxFailures;
else
    n = Inf;
end
