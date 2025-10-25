function bool = hasUniformNumberType(obj)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    bool = isscalar(unique(obj.numberTypes));
end
