function rptdsCopy = copyElement(rptds)
%copyElement   Creates a deep copy of a RepeatedDatastore.
%
%   Some special behavior to be aware of:
%   - function_handles in MATLAB aren't truly deep copied. So its important
%     to keep RepeatFcn a "pure function" that doesn't cause any side-effects
%     or have mutable shared state.
%   - Unlike partition() or subset(), copy() does not force a reset().
%   - If the repeated data or info is a Copyable handle object, a deep copy
%     is made.
%
%   See also: matlab.io.datastore.internal.RepeatedDatastore

%   Copyright 2021-2022 The MathWorks, Inc.

    % Call the default copyElement (which will make shallow copies of handle and value objects).
    rptdsCopy = copyElement@matlab.mixin.Copyable(rptds);

    % Manually deep-copy the handle objects.
    rptdsCopy.UnderlyingDatastore      = copy(rptds.UnderlyingDatastore);
    rptdsCopy.UnderlyingDatastoreIndex = copy(rptds.UnderlyingDatastoreIndex);
    rptdsCopy.InnerDatastore           = copy(rptds.InnerDatastore);
    rptdsCopy.RepeatFcn                = copy(rptds.RepeatFcn);
    rptdsCopy.RepeatAllFcn             = copy(rptds.RepeatAllFcn);

    % Deep copy the data and info if they are copyable handle objects.
    rptdsCopy.CurrentReadData = deepCopyIfCopyable(rptds.CurrentReadData);
    rptdsCopy.CurrentReadInfo = deepCopyIfCopyable(rptds.CurrentReadInfo);
end

function x = deepCopyIfCopyable(x)
    if isa(x, "matlab.mixin.Copyable")
        x = copy(x);
    end
end