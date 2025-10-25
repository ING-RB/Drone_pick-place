function tf = isSubsettable(ds)
%isSubsettable    returns true if this datastore is subsettable
%
%   All underlying datastores must be subsettable in order for a
%   SequentialDatastore to be subsettable.
%
%   See also: isPartitionable, subset, numobservations

%   Copyright 2022 The MathWorks, Inc.

tf = all(cellfun(@isSubsettable, ds.UnderlyingDatastores));
end