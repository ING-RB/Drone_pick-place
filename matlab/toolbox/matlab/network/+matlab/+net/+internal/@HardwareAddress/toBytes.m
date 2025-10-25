function b = toBytes(hw)
%

%   Copyright 2020 The MathWorks, Inc.

    b = {hw.Bytes};
    if isscalar(hw)
        b = b{1};
    end
end
