function values = getValuesAsDatetime(obj, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*
    import matlab.io.json.internal.JSONNodeType

    values = repmat(NaT, numel(obj.valueTypes), 1);
    values(obj.valueTypes == JSONNodeType.String) = convertStringToHomogeneousType(obj.strings, opts);
end
