function dsCopy = copyElement(ds)
%copyElement   Creates a deep copy of a datastore.
%
%   NOTE: Unlike partition() or subset(), copy() does not force a reset().
%
%   See also: matlab.io.Datastore

%   Copyright 2021 The MathWorks, Inc.

    % Call the default copyElement (which will make shallow copies of handle and value objects).
    dsCopy = copyElement@matlab.mixin.Copyable(ds);

    % Manually deep-copy the handle objects.
    dsCopy.UnderlyingDatastore = copy(ds.UnderlyingDatastore);
end
