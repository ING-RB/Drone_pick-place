function values = getValuesAsLogical(obj, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*
    import matlab.io.json.internal.JSONNodeType

    % Initialize values with false, the value for JSON null, JSON
    % false, JSON objects, and JSON Arrays
    values = false(obj.numValues, 1);

    % JSON True
    values = obj.fillJSONType(values, JSONNodeType.True, true);

    % JSON Strings are converted to logical "true" if the text is "true"
    parsedLogicals = convertStringToHomogeneousType(strings, opts);
    values = obj.fillJSONType(values, JSONNodeType.String, parsedLogicals);

    % JSON Numbers are set converted to single representation of each
    % numeric type
    [singleDoubles, singleUint64s, singleInt64s] = obj.coerceNumericTypes(@logical);
    values = obj.setJSONNumericTypes(values, singleDoubles, singleUint64s, singleInt64s);
end
