function m = StringToMethodID(method)
% Convert input method string into an enumID.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

coder.internal.prefer_const(method);

if method(1) == 'l'
    m = uint8(coder.internal.interpolate.interpMethodsEnum.LINEAR);
elseif method(1) == 'c'
    m = uint8(coder.internal.interpolate.interpMethodsEnum.CUBIC);
elseif method(1) == 'm'
    m = uint8(coder.internal.interpolate.interpMethodsEnum.MAKIMA);
elseif method(1) == 's'
    m = uint8(coder.internal.interpolate.interpMethodsEnum.SPLINE);
elseif method(1) == 'n'
    if method(2) == 'o'
        m = uint8(coder.internal.interpolate.interpMethodsEnum.NONE);
    elseif method(2) == 'a'
        m = uint8(coder.internal.interpolate.interpMethodsEnum.NATURAL);
    elseif method(3) == 'x'
        m = uint8(coder.internal.interpolate.interpMethodsEnum.NEXT);
    else
        m = uint8(coder.internal.interpolate.interpMethodsEnum.NEAREST);
    end
elseif method(1) == 'p'
    if method(2) == 'c'
        m = uint8(coder.internal.interpolate.interpMethodsEnum.PCHIP);
    else
        m = uint8(coder.internal.interpolate.interpMethodsEnum.PREVIOUS);
    end
elseif method(1) == 'b'
    m = uint8(coder.internal.interpolate.interpMethodsEnum.BOUNDARY);
else
    coder.internal.error('MATLAB:mathcgeo_catalog:BadInterpTypeErrId');
end

end
