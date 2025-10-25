function values = getValuesAsDuration(obj, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*
    import matlab.io.json.internal.JSONNodeType

    values = repmat(duration(missing), numel(obj.valueTypes), 1);
    values(obj.valueTypes == JSONNodeType.String) = convertStringToHomogeneousType(obj.strings, opts);
end
