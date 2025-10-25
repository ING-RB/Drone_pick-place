function RowTimes = validateRowTimesVariableIndex(opts, RowTimes)
%validateRowTimesVariableIndex   Verifies that RowTimes is in the right range for opts.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        opts (1, 1) matlab.io.internal.common.builder.TimetableBuilderOptions
        RowTimes
    end

    validateattributes(RowTimes, ["double" "string"], ["scalar" "nonnan" "real" "integer" "positive"], string(missing), "RowTimes");

    % Check that RowTimesVariableIndex is less than the max index.
    maxExpected = numel(opts.TableBuilder.VariableNames);
    if RowTimes > maxExpected
        error(message("MATLAB:io:common:builder:RowTimesVariableIndexTooLarge", maxExpected));
    end

    % Make sure that RowTimesVariableIndex points to a selected variable.
    if ~ismember(RowTimes, opts.TableBuilder.SelectedVariableIndices)
        error(message("MATLAB:io:common:builder:RowTimesVariableMustBeASelectedVariable"));
    end

    % Make sure that RowTimesVariableIndex points to an untyped variable or
    % a datetime/duration variable if a type constraint is specified.
    actualType = opts.TableBuilder.VariableTypes(RowTimes);
    if ismissing(actualType)
        return;
    end

    expectedTypes = ["datetime" "duration"];
    if ~ismember(actualType, expectedTypes)
        varName = opts.TableBuilder.VariableNames(RowTimes);
        msgid = "MATLAB:io:common:builder:RowTimesTypeMismatch";
        error(message(msgid, varName, actualType));
    end
end
