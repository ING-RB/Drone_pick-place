function values = getValuesAsInt(obj, opts, func)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*
    import matlab.io.json.internal.JSONNodeType

    % Initialize values with 0, the value for JSON null, JSON
    % false, JSON objects, and JSON Arrays
    typeName = func2str(func);
    values = zeros(obj.numValues, 1, typeName);

    % JSON True
    values = obj.fillJSONType(values, JSONNodeType.True, func(true));

    % JSON Strings
    parsedInts = convertStringToHomogeneousType(strings, opts);
    values = obj.fillJSONType(values, JSONNodeType.String, parsedInts);

    % JSON Numbers are converted to the provided integer representation
    [intDoubles, intUint68s, intInt64s] = obj.coerceNumericTypes(func);
    values = obj.setJSONNumericTypes(values, intDoubles, intUint68s, intInt64s);
end
