function values = getValuesAsString(obj, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*
    import matlab.io.json.internal.JSONNodeType

    % Initialize values with string(missing), the value for JSON
    % null, JSON objects, and JSON Arrays
    values = repmat(string(missing), numel(obj.valueTypes), 1);

    % JSON Falses are set to "false"
    values = obj.fillJSONType(values, JSONNodeType.False, "false");

    % JSON Trues are set to "true"
    values = obj.fillJSONType(values, JSONNodeType.True, "true");

    % JSON Strings are not coerced
    values(obj.valueTypes == JSONNodeType.String) = obj.strings;

    % JSON Numbers are set converted to string representations of each
    % numeric type
    [strDoubles, strUint64s, strInt64s] = obj.coerceNumericTypes(@string);
    values = obj.setJSONNumericTypes(values, strDoubles, strUint64s, strInt64s);

    % Convert strings using the variableImportOptions
    values = convertStringToHomogeneousType(values, opts);
end
