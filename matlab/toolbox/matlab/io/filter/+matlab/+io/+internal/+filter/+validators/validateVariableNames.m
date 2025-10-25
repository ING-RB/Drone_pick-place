function indices = validateVariableNames(filter, selectedVariableNames)
%validateVariableNames   validates that the input filter tree only
%   consists of the supplied variable names.
%
%   Will throw an error if any unexpected variable names are
%   present.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        filter (1, 1) matlab.io.RowFilter
        selectedVariableNames (1, :) string
    end

    % Get the list of constrained variable names (over which filtering
    % constraints are actually applied).
    filterVariableNames = constrainedVariableNames(filter);

    % Convert SelectedVariableNames to indices. The VariableNames in the
    % filter expression are expected to be a subset of the VariableNames in
    % the parquetinfo (i.e. pre-normalization/uniqueification).
    [validMemberMask, indices] = ismember(filterVariableNames, selectedVariableNames);

    if ~all(validMemberMask)
        % Filter expression contains a variable name that's not in the
        % Parquet file.
        invalidNames = filterVariableNames(~validMemberMask);
        if isempty(selectedVariableNames)
            selectedVariableNames = "";
        else
            selectedVariableNames = join(selectedVariableNames, ", ");
        end
        error(message("MATLAB:io:filter:filter:InvalidVariableName", ...
                      invalidNames(1), selectedVariableNames));
    end
end