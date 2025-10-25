function ndsCopy = copyElement(nds)
%copyElement   Creates a deep copy of a NestedDatastore.
%
%   Some special behavior to be aware of:
%   - function_handles in MATLAB aren't truly deep copied. So its important
%     to keep InnerDatastoreFcn a "pure function" that doesn't cause any side-effects
%     or have mutable shared state. Or you could use a FunctionObject with
%     well-defined copy() behavior.
%   - Both the OuterDatastore and InnerDatastore are deep-copied in their
%     current state. So if OuterDatastore and InnerDatastore implement
%     copyElement properly, NestedDatastore/copyElement will also make a perfect
%     deep copy.
%   - Unlike partition(), copy() does not force a reset().
%
%   See also: matlab.io.datastore.internal.NestedDatastore

%   Copyright 2021 The MathWorks, Inc.

    % Call the default copyElement (which will make shallow copies of handle and value objects).
    ndsCopy = copyElement@matlab.mixin.Copyable(nds);

    % Manually deep-copy the handle objects.
    ndsCopy.OuterDatastore = copy(nds.OuterDatastore);
    ndsCopy.InnerDatastore = copy(nds.InnerDatastore);
    ndsCopy.InnerDatastoreFcn = copy(nds.InnerDatastoreFcn);
end
