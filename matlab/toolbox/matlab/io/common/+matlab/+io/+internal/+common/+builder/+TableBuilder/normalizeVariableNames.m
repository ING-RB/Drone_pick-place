function opts = normalizeVariableNames(opts, NewVariableNames)
%normalizeVariableNames   Use matlab.internal.tabular.makeValidVariableNames() to
%   make the original variable names valid while also respecting the
%   VariableNamingRule and warning state on the TableBuilderOptions object.
%
%   Input must be a matlab.io.internal.common.builder.TableBuilderOptions object.
%
%   This function updates VariableNames, OriginalVariableNames, DimensionNames, 
%   RowFilter, and OriginalRowFilter based on the VariableNames passed in as input.

%   Copyright 2022 The MathWorks, Inc.

    OldOriginalSelectedVariableNames = opts.OriginalVariableNames(opts.SelectedVariableIndices);
    opts.OriginalVariableNames = NewVariableNames;

    modeString = getNameValidationMode(opts);

    % Normalize variable names. Will print a warning if normalization occurred.
    import matlab.internal.tabular.makeValidVariableNames
    opts.VariableNames = makeValidVariableNames(opts.OriginalVariableNames, modeString);

    % Normalize dimension names too.
    hasChangedFromDefault = any(opts.DimensionNames ~= opts.DefaultDimensionNames);
    hasConflictWithVariableNames = any(opts.VariableNames == opts.DimensionNames', "all");
    import matlab.io.internal.common.builder.TableBuilder.normalizeDimensionNames;
    if hasChangedFromDefault || hasConflictWithVariableNames
        opts.DimensionNames = normalizeDimensionNames(opts);
    end

    % Only normalize RowFilter VariableNames if necessary.
    if ~opts.IsTrivialFilter
        % Normalize RowFilter VariableNames too.
        NewOriginalSelectedVariableNames = opts.OriginalVariableNames(opts.SelectedVariableIndices);
        opts.OriginalRowFilter = replaceVariableNames(opts.OriginalRowFilter, OldOriginalSelectedVariableNames, NewOriginalSelectedVariableNames);
    end
end

function modeString = getNameValidationMode(opts)
    % Returns a mode string for use by the
    % matlab.internal.tabular.makeValidVariableNames() utility.

    preserve = opts.VariableNamingRule == "preserve";
    silent = ~opts.WarnOnNormalizationDuringSet;

    if silent
        if preserve
            % TODO: is this really the right mode? It might do something
            % weird for strlength=0 inputs.
            modeString = "resolveConflict";
        else
            modeString = "silent";
        end
    else % Not silent, show a warning.
        if preserve
            modeString = "warnLength";
        else
            modeString = "warn";
        end
    end
end
