function values = getDoubleDictionaryValues(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    % Initialize values with NaN, the value for JSON null, JSON
    % objects, and JSON Arrays
    values = NaN(numel(r.valueTypes), 1, "double");

    % JSON False
    values = r.fillJSONType(values, JSONType.False, double(false));

    % JSON True
    values = r.fillJSONType(values, JSONType.True, double(true));

    % JSON String
    parsedDoubles = convertStringToHomogeneousType(strings, opts.ValueImportOptions{"double"});
    values = r.fillJSONType(values, JSONType.String, parsedDoubles);

    % JSON Numbers are set converted to double representations of each
    % numeric type
    [~, doubleUint64s, doubleInt64s] = coerceNumericTypes(r.doubles, ...
                                                          r.uint64s, r.int64s, @double);
    values = r.setJSONNumericTypes(values, r.doubles, doubleUint64s, doubleInt64s);
end
