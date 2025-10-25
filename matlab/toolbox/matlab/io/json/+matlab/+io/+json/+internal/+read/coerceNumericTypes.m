function [coercedDoubles, coercedUint64s, coercedInt64s] = coerceNumericTypes(doubles, uint64s, int64s, func)
%

%   Copyright 2024 The MathWorks, Inc.


% TODO: Move this function to reader class, update call sites
    coercedDoubles = func(doubles);
    coercedUint64s = func(uint64s);
    coercedInt64s = func(int64s);
end
