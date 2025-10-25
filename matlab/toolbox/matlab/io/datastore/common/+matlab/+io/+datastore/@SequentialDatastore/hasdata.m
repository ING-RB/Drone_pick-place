function tf = hasdata(ds)
%HASDATA   Returns true if more data is available to read
%
%   Return a logical scalar indicating availability of data. This
%   method should be called before calling read.
%
%   This method only returns true if at least one of the underlying
%   datastore in the SequentialDatastore has data available
%   for reading.
%
%   See also: reset, read

%   Copyright 2022 The MathWorks, Inc.

% Default for Empty SequentialDatastore.
tf = false;

idx = ds.CurrentDatastoreIndex;
while ~tf && idx <= numel(ds.UnderlyingDatastores)
    % No more data in current datastore. Return if any subsequent
    % datastores has data.
    tf = hasdata(ds.UnderlyingDatastores{idx});
    idx = idx + 1;
end
end