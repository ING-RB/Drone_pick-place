function values = setJSONNumericTypes(obj, values, doubles, uint64s, int64s)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    numberIndices = find(obj.valueTypes == JSONType.Number);
    doubleIndices = numberIndices(obj.numberTypes == NumericType.Double);
    uint64Indices = numberIndices(obj.numberTypes == NumericType.UInt64);
    int64Indices  = numberIndices(obj.numberTypes == NumericType.Int64);
    values(doubleIndices) = doubles;
    values(uint64Indices) = uint64s;
    values(int64Indices) = int64s;
end
