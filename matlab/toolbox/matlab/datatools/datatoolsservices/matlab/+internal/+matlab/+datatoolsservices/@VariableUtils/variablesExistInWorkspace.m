% Returns true if any of the variable names in varNames exist in the user's
% current workspace.

% Copyright 2025 The MathWorks, Inc.

function b = variablesExistInWorkspace(varNames)
    arguments
        varNames string
    end
    currVars = evalin("debug", "who");
    b = any(ismember(varNames, currVars));
end