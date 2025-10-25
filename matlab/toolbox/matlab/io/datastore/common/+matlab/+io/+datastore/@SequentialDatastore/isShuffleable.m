function tf = isShuffleable(ds)
%isShuffleable   returns true if this datastore is shuffleable
%
%   A SequentialDatastore is only shuffleable when all
%   of its underlying datastores are shuffleable.
%
%   See also: isPartitionable, shuffle, subset

%   Copyright 2022 The MathWorks, Inc.

tf = all(cellfun(@isShuffleable, ds.UnderlyingDatastores));
end