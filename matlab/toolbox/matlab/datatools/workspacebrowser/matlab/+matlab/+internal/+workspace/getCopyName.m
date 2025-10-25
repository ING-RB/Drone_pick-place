function new = getCopyName(orig, who_output)
    
    % Create a new unique variable name given the existing workspace variables.
    % The new variable name will have 'Copy' appended to the end.  If the new
    % variable name is too long, characters will be stripped off the end prior
    % to 'Copy' being appended so it is less than namelengthmax and is unique.
    % This logic was extracted from workspacefunc, but was changed to support
    % strings.
    
    % Copyright 2020 The MathWorks, Inc.

    new = internal.matlab.datatoolsservices.VariableUtils.getVarNameForCopy(orig, who_output);
end