% Returns true if this is a custom char workspace

% Copyright 2020-2022 The MathWorks, Inc.

function result = isCustomCharWorkspace(ws)
    result = ischar(ws) && ~matches(ws, internal.matlab.datatoolsservices.VariableUtils.PREDEFINED_WORKSPACE_NAMES, 'IgnoreCase', false);
end