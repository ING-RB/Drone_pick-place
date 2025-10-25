function values = setJSONNumericTypes(r, values, doubles, uint64s, int64s)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    numberIndices = find(r.valueTypes == JSONType.Number);
    doubleIndices = numberIndices(r.numberTypes == NumericType.Double);
    uint64Indices = numberIndices(r.numberTypes == NumericType.UInt64);
    int64Indices  = numberIndices(r.numberTypes == NumericType.Int64);
    values(doubleIndices) = doubles;
    values(uint64Indices) = uint64s;
    values(int64Indices) = int64s;
end
