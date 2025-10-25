function [numFailures, locations] = getReadFailures(ds)
%getReadFailures Return the number of read failures and a list of
% locations where those failures occurred.

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
    failures = resolve(ds.ReadFailures);
    locations = failures.FileName;
    numFailures = numel(locations);
else
    locations = string.empty(0, 1);
    numFailures = 0;
end
