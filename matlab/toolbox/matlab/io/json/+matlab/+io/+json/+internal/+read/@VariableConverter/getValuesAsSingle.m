function values = getValuesAsSingle(obj, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*
    import matlab.io.json.internal.JSONNodeType

    % Initialize values with NaN, the value for JSON null, JSON
    % objects, and JSON Arrays
    values = NaN(numel(obj.valueTypes), 1, "single");

    % JSON False
    values = obj.fillJSONType(values, JSONNodeType.False, single(false));

    % JSON True
    values = obj.fillJSONType(values, JSONNodeType.True, single(true));

    % JSON Strings are converted to double, then single, as there
    % isn't a built in way to convert text to singles.
    parsedSingles = convertStringToHomogeneousType(strings, opts);
    values = obj.fillJSONType(values, JSONNodeType.String, parsedSingles);

    % JSON Numbers are set converted to single representation of each
    % numeric type
    [singleDoubles, singleUint64s, singleInt64s] = obj.coerceNumericTypes(@single);
    values = obj.setJSONNumericTypes(values, singleDoubles, singleUint64s, singleInt64s);
end
