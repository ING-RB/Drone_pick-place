function nested = containsNestedValues(obj)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    nestedTypeIDs = [JSONType.Object, JSONType.Array];
    nested = any(ismember(nestedTypeIDs, obj.valueTypes));
end
