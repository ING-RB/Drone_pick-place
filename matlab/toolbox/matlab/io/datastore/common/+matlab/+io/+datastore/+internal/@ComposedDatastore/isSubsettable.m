function tf = isSubsettable(ds)
%isSubsettable   Returns true if this datastore is subsettable.

%   Copyright 2021 The MathWorks, Inc.

    tf = ds.UnderlyingDatastore.isSubsettable();
end
