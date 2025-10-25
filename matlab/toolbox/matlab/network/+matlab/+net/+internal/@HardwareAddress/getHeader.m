function hdr = getHeader(hw)
%

%   Copyright 2020 The MathWorks, Inc.

    if isscalar(hw)
        hdr = sprintf('%s - %s\n', matlab.mixin.CustomDisplay.getClassNameForHeader(hw), string(hw));
    else
        hdr = matlab.mixin.CustomDisplay.getSimpleHeader(hw);
    end
end
