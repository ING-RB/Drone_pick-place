function tf = isShuffleable(ds)
%isShuffleable   Returns true if this datastore is shuffleable.

%   Copyright 2021 The MathWorks, Inc.

    tf = ds.UnderlyingDatastore.isShuffleable();
end
