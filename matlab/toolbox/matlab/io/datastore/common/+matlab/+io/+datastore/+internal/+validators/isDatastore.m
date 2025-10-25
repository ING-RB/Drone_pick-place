function tf = isDatastore(ds)
%ISDATASTORE Validate a datastore input.
%   This function returns true if ds is a datastore instance and false
%   otherwise.

%   Copyright 2022 The MathWorks, Inc.

tf = isa(ds, 'matlab.io.Datastore') || isa(ds, 'matlab.io.datastore.Datastore');
end