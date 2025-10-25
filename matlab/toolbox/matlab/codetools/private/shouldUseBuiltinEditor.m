function result = shouldUseBuiltinEditor()
% For a remote client, the function always returns true.
% For a local client, retrieves the preference value
% and returns true if 's.matlab.editor.UseMATLABEditor' setting is true, false otherwise.

%   Copyright 2020-2023 The MathWorks, Inc.

import matlab.internal.capability.Capability;
isLocalClient = Capability.isSupported(Capability.LocalClient);
if ~isLocalClient
    % if we are not running on a local client (i.e. remote client),
    % always open files in built-in editor.
    result = true;
    return;
end
% g1609199 - Retrieve the preference value using the Settings API.
s = settings;
result = s.matlab.editor.UseMATLABEditor.ActiveValue;
end
