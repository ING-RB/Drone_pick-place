function values = getStringDictionaryValues(r)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    % Initialize values with string(missing), the value for JSON
    % null, JSON objects, and JSON Arrays
    values = repmat(string(missing), numel(r.valueTypes), 1);

    % JSON Falses are set to "false"
    values = r.fillJSONType(values, JSONType.False, "false");

    % JSON Trues are set to "true"
    values = r.fillJSONType(values, JSONType.True, "true");

    % JSON Strings are not coerced
    values(r.valueTypes == JSONType.String) = r.strings;

    % JSON Numbers are set converted to string representations of each
    % numeric type
    [strDoubles, strUint64s, strInt64s] = matlab.io.json.internal.read.coerceNumericTypes(r.doubles, ...
                                                                                          r.uint64s, r.int64s, @string);
    values = r.setJSONNumericTypes(values, strDoubles, strUint64s, strInt64s);
end
