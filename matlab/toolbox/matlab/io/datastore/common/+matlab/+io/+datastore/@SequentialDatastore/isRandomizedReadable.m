function tf = isRandomizedReadable(ds)
%isRandomizedReadable    returns true if this datastore is known to
%   reorder data at random after calling reset or read.
%
%   A SequentialDatastore is considered to be reading randomized
%   data if any underlying datastore returns isRandomizedReadable
%   true.
%
%   See also: isPartitionable, partition, read

%   Copyright 2022 The MathWorks, Inc.

% Check if any underlying datastores are RandomizedReadable or not.
tf = any(cellfun(@isRandomizedReadable, ds.UnderlyingDatastores));
end