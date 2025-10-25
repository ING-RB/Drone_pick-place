function fdsCopy = copyElement(fds)
%copyElement   Creates a deep copy of a datastore.
%
%   NOTE: Unlike partition() or subset(), copy() does not force a reset().
%
%   See also: matlab.io.Datastore

%   Copyright 2022 The MathWorks, Inc.

    % Call the default copyElement (which will make shallow copies of handle and value objects).
    fdsCopy = copyElement@matlab.mixin.Copyable(fds);

    % Manually deep-copy the handle objects.
    fdsCopy.FileSet = copy(fds.FileSet);
    fdsCopy.ReadFcn = copy(fds.ReadFcn);
end
