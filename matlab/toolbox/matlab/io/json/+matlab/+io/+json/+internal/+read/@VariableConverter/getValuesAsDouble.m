function values = getValuesAsDouble(obj, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*
    import matlab.io.json.internal.JSONNodeType

    % Initialize values with NaN, the value for JSON null, JSON
    % objects, and JSON Arrays
    values = NaN(numel(obj.valueTypes), 1, "double");

    % JSON False
    values = obj.fillJSONType(values, JSONNodeType.False, double(false));

    % JSON True
    values = obj.fillJSONType(values, JSONNodeType.True, double(true));

    % JSON String
    parsedDoubles = convertStringToHomogeneousType(strings, opts);
    values = obj.fillJSONType(values, JSONNodeType.String, parsedDoubles);

    % JSON Numbers are set converted to double representations of each
    % numeric type
    [~, doubleUint64s, doubleInt64s] = obj.coerceNumericTypes(@double);
    values = obj.setJSONNumericTypes(values, obj.doubles, doubleUint64s, doubleInt64s);
end
