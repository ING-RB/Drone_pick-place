function values = getIntegerDictionaryValues(r, opts, func)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    % Initialize values with 0, the value for JSON null, JSON
    % false, JSON objects, and JSON Arrays
    typeName = func2str(func);
    values = zeros(r.numValues, 1, typeName);

    % JSON True
    values = r.fillJSONType(values, JSONType.True, func(true));

    % JSON Strings
    parsedInts = convertStringToHomogeneousType(strings, opts.ValueImportOptions{typeName});
    values = r.fillJSONType(values, JSONType.String, parsedInts);

    % JSON Numbers are converted to the provided integer representation
    [intDoubles, intUint68s, intInt64s] = coerceNumericTypes(r.doubles, ...
                                                             r.uint64s, r.int64s, func);
    values = r.setJSONNumericTypes(values, intDoubles, intUint68s, intInt64s);
end
