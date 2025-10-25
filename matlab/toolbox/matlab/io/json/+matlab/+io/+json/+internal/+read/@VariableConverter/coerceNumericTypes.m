function [coercedDoubles, coercedUint64s, coercedInt64s] = coerceNumericTypes(obj, func)
%

%   Copyright 2024 The MathWorks, Inc.

    coercedDoubles = func(obj.doubles);
    coercedUint64s = func(obj.uint64s);
    coercedInt64s = func(obj.int64s);
end
