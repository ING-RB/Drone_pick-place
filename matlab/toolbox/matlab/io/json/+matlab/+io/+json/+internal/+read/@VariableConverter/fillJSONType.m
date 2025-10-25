function values = fillJSONType(obj, values, JSONTypeID, fillValue)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    %TODO: refactor this out
    assert(JSONTypeID < 6, "Invalid JSONTypeID passed to setJSONType. JSON null, false, true, object, array, and string can be passed to this function.");
    values(obj.valueTypes == JSONTypeID) = fillValue;
end
