function values = getSingleDictionaryValues(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    % Initialize values with NaN, the value for JSON null, JSON
    % objects, and JSON Arrays
    values = NaN(numel(r.valueTypes), 1, "single");

    % JSON False
    values = r.fillJSONType(values, JSONType.False, single(false));

    % JSON True
    values = r.fillJSONType(values, JSONType.True, single(true));

    % JSON Strings are converted to double, then single, as there
    % isn't a built in way to convert text to singles.
    parsedSingles = convertStringToHomogeneousType(strings, opts.ValueImportOptions{"single"});
    values = r.fillJSONType(values, JSONType.String, parsedSingles);

    % JSON Numbers are set converted to single representation of each
    % numeric type
    [singleDoubles, singleUint64s, singleInt64s] = coerceNumericTypes(r.doubles, ...
                                                                      r.uint64s, r.int64s, @single);
    values = r.setJSONNumericTypes(values, singleDoubles, singleUint64s, singleInt64s);
end
