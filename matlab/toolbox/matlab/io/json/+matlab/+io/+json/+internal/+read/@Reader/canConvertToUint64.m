function bool = canConvertToUint64(obj)
%

%   Copyright 2024 The MathWorks, Inc.

    bool = isempty(obj.int64s) ... % JSON Number values that are detected as int64 in the C++ layer cannot be represented by uint64.
           && all(isfinite(obj.doubles) & (floor(obj.doubles) == obj.doubles) & (obj.doubles >= 0) & (obj.doubles < (2^64)));
end
