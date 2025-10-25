function variableNames = parseVariableNames(args, T)
    arguments
        args cell
        T(:, :) tabular
    end

    persistent parser;

    if isempty(parser)
        parser = inputParser;
        parser.FunctionName = "parquetwrite";
        parser.KeepUnmatched = true;
        parser.addParameter("VariableNames", missing);
    end

    parser.parse(args{:});

    if istimetable(T) || ~isempty(T.Properties.RowNames)
        % Prepend the row variable name to originalVariableNames if T is a
        % timetable or table with row names.
        originalVariableNames = [T.Properties.DimensionNames(1) T.Properties.VariableNames];
    else
        originalVariableNames = T.Properties.VariableNames;
    end

    originalVariableNames = convertCharsToStrings(originalVariableNames);

    if ismember("VariableNames", string(parser.UsingDefaults))
        variableNames = originalVariableNames;
    else
        variableNames = parser.Results.VariableNames;

        % Verify variableNames is convertible to a string array
        if ~iscellstr(variableNames) && ~isstring(variableNames)
            errid = "MATLAB:io:common:arguments:MustBeStringOrCellstr";
            error(message(errid, "VariableNames"));
        end

        % Verify the number of elements in variableNames
        if numel(variableNames) ~= numel(originalVariableNames)
            throwErrorWrongNumberVariableNames(variableNames, originalVariableNames, T);
        end

        variableNames = convertCharsToStrings(variableNames);
        variableNames = reshape(variableNames, 1, []);

        % string <missing> values are not supported.
        missingIdx = ismissing(variableNames);
        if any(missingIdx)
            idx = find(missingIdx, 1);
            errid = "MATLAB:io:common:arguments:MissingStringValue";
            error(message(errid, "VariableNames", idx));
        end
    end
end

function throwErrorWrongNumberVariableNames(variableNames, originalVariableNames, T)
    if numel(variableNames) + 1 == numel(originalVariableNames)
        % Throw a more specific error message if T is a timetable or table
        % with row names AND a variable name was not supplied for the
        % RowTimes/RowNames variable.
        if istimetable(T) || ~isempty(T.Properties.RowNames)
            errid = "MATLAB:io:common:write:VariableNamesMissingRowDimensionName";
            rowvariableName = T.Properties.DimensionNames{1};
            error(message(errid, rowvariableName));
        end
    end
    errid = "MATLAB:io:common:write:VariableNamesWrongSize";
    error(message(errid, numel(variableNames), numel(originalVariableNames), class(T)));
end

% Copyright 2024 The MathWorks, Inc.
