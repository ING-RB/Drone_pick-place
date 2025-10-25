function [validVariableNames, dimensionNames, variableDescriptions] = ...
    makeUniqueVariableNames(variableNames, dimensionNames, preserveVariableNames)
%MAKEUNIQUEVARIABLENAMES Helper function that generates unique valid table
% variable names and dimension names.

% Copyright 2022 The MathWorks, Inc.

    % Maintain a logical array of modified variable names. This will help with
    % setting the VariableDescriptions property if any VariableNames were
    % changed.
    modified = false(1, numel(variableNames));
    
    % The table constructor doesn't support empty variable names, so fix this
    % up by filling in a default table variable name.
    validVariableNames = variableNames;
    emptyVariableNameIndices = variableNames == "";
    defaultVariableNames = "Var" + (1:numel(variableNames));
    validVariableNames(emptyVariableNameIndices) = defaultVariableNames(emptyVariableNameIndices);
    
    % Since MATLAB tables now support arbitrary variable names, convert the
    % Arrow column names to valid MATLAB identifiers only when necessary.
    if ~preserveVariableNames
        % Normalize to a valid MATLAB variable name.
        [validVariableNames, modified] = matlab.lang.makeValidName(validVariableNames);
    end
    
    % Make the variable names unique. Also ensure that there are no conflicts
    % with reserved table variable names.
    reservedTableIdentifiers = {'Properties', ':'};
    [validVariableNames, modifiedUnique] = matlab.lang.makeUniqueStrings(...
        validVariableNames, reservedTableIdentifiers, namelengthmax);
    modified = modified | modifiedUnique;
    
    % Make sure that the variable names do not conflict with the
    % default table dimension names.
    if any(ismember(validVariableNames, dimensionNames))
        dimensionNames = matlab.lang.makeUniqueStrings(dimensionNames, ...
            validVariableNames, namelengthmax);
    end
    
    % Return an empty cell array if the VariableDescriptions have not been
    % modified.
    variableDescriptions = {};
    if any(modified)
        % Set VariableDescriptions to be an empty char array if the variable name
        % has not been modified.
        variableDescriptions = cellstr(strings(1, numel(variableNames)));
    
        % Provide an informative description message if the variable name has 
        % been modified.
        infomationStrings = "Original variable name: '" + variableNames(modified) + "'";
        variableDescriptions(modified) = cellstr(infomationStrings);
    end
end