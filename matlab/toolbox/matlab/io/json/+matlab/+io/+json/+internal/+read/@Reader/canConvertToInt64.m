function bool = canConvertToInt64(r)
%

%   Copyright 2024 The MathWorks, Inc.

    bool = all(r.uint64s < (2^63)) ...
           && all(isfinite(r.doubles) & (floor(r.doubles) == r.doubles) & (r.doubles < (2^63)) & (r.doubles >= (-2^63)));
end
