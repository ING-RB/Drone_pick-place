function values = getLogicalDictionaryValues(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    % Initialize values with false, the value for JSON null, JSON
    % false, JSON objects, and JSON Arrays
    values = false(r.numValues, 1);

    % JSON True
    values = r.fillJSONType(values, JSONType.True, true);

    % JSON Strings are converted to logical "true" if the text is "true"
    parsedLogicals = convertStringToHomogeneousType(strings, opts.ValueImportOptions{"logical"});
    values = r.fillJSONType(values, JSONType.String, parsedLogicals);

    % JSON Numbers are set converted to single representation of each
    % numeric type
    [singleDoubles, singleUint64s, singleInt64s] = matlab.io.json.internal.read.coerceNumericTypes(r.doubles, ...
                                                                                                   r.uint64s, r.int64s, @logical);
    values = r.setJSONNumericTypes(values, singleDoubles, singleUint64s, singleInt64s);
end
