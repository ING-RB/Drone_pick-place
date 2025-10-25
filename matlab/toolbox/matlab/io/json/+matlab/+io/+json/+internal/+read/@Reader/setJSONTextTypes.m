function values = setJSONTextTypes(r, values, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    % Check for datetime/duration values in the strings.
    timeTypes = matlab.io.json.internal.detectTimeTypes(r.strings, opts.ValueImportOptions{"datetime"}.DatetimeLocale);
    textIndices = find(r.valueTypes == JSONType.String);
    stringIndices = textIndices(timeTypes == StringType.Text);
    datetimeIndices = textIndices(timeTypes == StringType.Datetime);
    durationIndices = textIndices(timeTypes == StringType.Duration);
    values(stringIndices) = num2cell(r.strings(timeTypes == StringType.Text));
    values(datetimeIndices) = convertStringToVarOptsTypeWithCellCoercion(r.strings(timeTypes == StringType.Datetime), opts.ValueImportOptions{"datetime"});
    values(durationIndices) = convertStringToVarOptsTypeWithCellCoercion(r.strings(timeTypes == StringType.Duration), opts.ValueImportOptions{"duration"});
end
