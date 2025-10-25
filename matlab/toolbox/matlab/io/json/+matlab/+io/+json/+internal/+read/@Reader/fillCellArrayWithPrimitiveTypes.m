function values = fillCellArrayWithPrimitiveTypes(r, values, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    numMissings = sum(r.valueTypes == JSONType.Null);
    values(r.valueTypes == JSONType.Null) = num2cell(repmat(missing, numMissings, 1));

    numFalse = sum(r.valueTypes == JSONType.False);
    values(r.valueTypes == JSONType.False) = num2cell(false(numFalse, 1));

    numTrue = sum(r.valueTypes == JSONType.True);
    values(r.valueTypes == JSONType.True) = num2cell(true(numTrue, 1));

    values = r.setJSONTextTypes(values, opts);

    [cellDoubles, cellUint64s, cellInt64s] = matlab.io.json.internal.read.coerceNumericTypes(r.doubles, r.uint64s, r.int64s, @num2cell);
    values = r.setJSONNumericTypes(values, cellDoubles, cellUint64s, cellInt64s);
end
