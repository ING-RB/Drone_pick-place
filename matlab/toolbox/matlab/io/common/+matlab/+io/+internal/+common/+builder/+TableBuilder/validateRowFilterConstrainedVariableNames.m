function rf = validateRowFilterConstrainedVariableNames(opts, ...
                                                        rf, ...
                                                        UseOriginalVariableNames)
%validateRowFilterConstrainedVariableNames   Verifies that all constrained
%   variables on RowFilter are selected names.
%
%   If UseOriginalVariableNames is set to true, then the supplied
%   RowFilter VariableNames are validated against OriginalVariableNames
%   If UseOriginalVariableNames is false, then they are validated against
%   VariableNames instead.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        opts                     (1, 1) matlab.io.internal.common.builder.TableBuilderOptions
        rf
        UseOriginalVariableNames (1, 1) logical
    end

    validateattributes(rf, "matlab.io.RowFilter", "scalar", string(missing), "RowFilter");

    constrainedNames = constrainedVariableNames(rf);

    if isempty(constrainedNames)
        % No constraints on RowFilter, just return early.
        return;
    end

    % Decide whether to use normalized or non-normalized variable
    % names for validation.
    if UseOriginalVariableNames
        varNames = opts.OriginalVariableNames;
    else
        varNames = opts.VariableNames;
    end
    selectedVarNames = varNames(opts.SelectedVariableIndices);

    % Constrained variable names must be a subset of SelectedVariableNames.
    isSelectedVariableName = ismember(constrainedNames, selectedVarNames);

    if ~all(isSelectedVariableName)
        isVariableName = ismember(constrainedNames, varNames);
        throwInvalidConstrainedVariableNamesError(constrainedNames, isSelectedVariableName, isVariableName);
    end
end

function throwInvalidConstrainedVariableNamesError(constrainedVariableNames, isSelectedVariableName, isVariableName)
    if all(isVariableName)
        % If all constrained variable names are valid variable names but just
        % deselected, then print a more targeted error message suggesting SelectedVariableNames.
        unselectedVariables = constrainedVariableNames(~isSelectedVariableName);
        padding = newline + "    ";
        msgstr = newline + padding + join(unselectedVariables, padding);
        error(message("MATLAB:io:common:builder:DeselectedConstrainedVariableNames", msgstr));
    else
        % Constrained variable names are not found in both the selected variable
        % names or the variable names list. Print a generic error in this case.
        unrecognizedVariables = constrainedVariableNames(~isVariableName);
        padding = newline + "    ";
        msgstr = newline + padding + join(unrecognizedVariables, padding);
        error(message("MATLAB:io:common:builder:UnrecognizedConstrainedVariableNames", msgstr));
    end
end
