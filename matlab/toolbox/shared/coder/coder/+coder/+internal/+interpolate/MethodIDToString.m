function method = MethodIDToString(m)
    % Convert methodID to char vector, used in getter functions.

    %   Copyright 2024 The MathWorks, Inc.

    %#codegen

    if m == coder.internal.interpolate.interpMethodsEnum.LINEAR
        method = 'linear';
    elseif m == coder.internal.interpolate.interpMethodsEnum.CUBIC
        method = 'cubic';
    elseif m == coder.internal.interpolate.interpMethodsEnum.MAKIMA
        method = 'makima';
    elseif m == coder.internal.interpolate.interpMethodsEnum.SPLINE
        method = 'spline';
    elseif m == coder.internal.interpolate.interpMethodsEnum.NONE
        method = 'none';
    elseif m == coder.internal.interpolate.interpMethodsEnum.NEXT
        method = 'next';
    elseif m == coder.internal.interpolate.interpMethodsEnum.NEAREST
        method = 'nearest';
    elseif m == coder.internal.interpolate.interpMethodsEnum.PCHIP
        method = 'pchip';
    elseif m == coder.internal.interpolate.interpMethodsEnum.PREVIOUS
        method = 'previous';
    elseif m == coder.internal.interpolate.interpMethodsEnum.BOUNDARY
        method = 'boundary';
    else 
        method = 'natural';
    end

end
