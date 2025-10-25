function index = validateRowTimesVariableName(opts, ...
                                              RowTimes, ...
                                              UseOriginalVariableNames)
%validateRowTimesVariableName   Verifies that RowTimes is a
%   member of SelectedVariableNames.
%
%   If UseOriginalVariableNames is set to true, then the supplied
%   RowTimes are validated against OriginalSelectedVariableNames
%   If UseOriginalVariableNames is false, then they are validated against
%   SelectedVariableNames instead.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        opts                     (1, 1) matlab.io.internal.common.builder.TimetableBuilderOptions
        RowTimes                 (1, 1) string {mustBeNonmissing}
        UseOriginalVariableNames (1, 1) logical
    end

    % Decide whether to use normalized or non-normalized variable
    % names for validation.
    if UseOriginalVariableNames
        varNames = opts.TableBuilder.OriginalSelectedVariableNames;
    else
        varNames = opts.TableBuilder.SelectedVariableNames;
    end

    % RowTimes must be a subset of SelectedVariableNames.
    % TODO: watch out for duplicates and empties in OriginalSelectedVariableNames.
    index = find(RowTimes == varNames, 1);

    if isempty(index)
        error(message("MATLAB:io:common:builder:RowTimesVariableMustBeASelectedVariable"));
    end

    % Convert index back to a VariableNames-based index.
    index = opts.TableBuilder.SelectedVariableIndices(index);

    % Validate the RowTimes index too. It must be of the right type, if
    % type checking is enabled.
    import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableIndex
    index = validateRowTimesVariableIndex(opts, index);
end
