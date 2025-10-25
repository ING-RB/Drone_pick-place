function tf = isEmptyDatastore(schds)
%isEmptyDatastore   Returns true if no reads are possible from this datastore.

%   Copyright 2022 The MathWorks, Inc.

    % We need to make a copy of the underlying datastore
    % and reset it to be fully sure that this is the empty state.
    copyds = schds.UnderlyingDatastore.copy();
    copyds.reset();
    tf = ~copyds.hasdata();
end
