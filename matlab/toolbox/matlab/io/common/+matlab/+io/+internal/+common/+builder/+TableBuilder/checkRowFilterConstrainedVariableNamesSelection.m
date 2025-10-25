function indices = checkRowFilterConstrainedVariableNamesSelection(opts, indices)
%checkRowFilterConstrainedVariableNamesSelection   Throws an error if all
%   constrained variable names on opts.RowFilter are not selected in INDICES.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        opts (1, 1) matlab.io.internal.common.builder.TableBuilderOptions
        indices
    end

    if opts.IsTrivialFilter || numel(constrainedVariableNames(opts.OriginalRowFilter)) == 0
       % Unconstrained, just return early.
       return;
    end

    % Original names are used here instead of normalized names since the
    % normalized names are generated using an injective mapping and may be
    % ambiguous.
    % The original names may be ambiguous too since they can hold duplicate
    % names, but that is less bad than "A+B" and "A*B" mapping to the same
    % normalized name.
    constrainedNames = constrainedVariableNames(opts.OriginalRowFilter);
    isSelectedVariableName = ismember(constrainedNames, opts.OriginalVariableNames(indices));

    if ~all(isSelectedVariableName)
        deselectedVariableNames = constrainedNames(~isSelectedVariableName);
        padding = newline + "    ";
        msgstr = newline + padding + join(deselectedVariableNames, padding);
        error(message("MATLAB:io:common:builder:SelectedVariableNamesDeselectsConstrainedVariableNames", msgstr));
    end
end