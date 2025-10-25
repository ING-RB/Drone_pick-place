function methodCheck(iemethod, doInterp)
    % helper function for parseinterpextrap

    %   Copyright 2022 The MathWorks, Inc.
    
    %#codegen
    
    islinear = strcmp(iemethod,'linear');
    isnearest = strcmp(iemethod,'nearest');
    iscubic = strcmp(iemethod,'cubic');
    isspline = strcmp(iemethod,'spline');
    isnext = strcmp(iemethod,'next');
    isprevious = strcmp(iemethod,'previous');
    ispchip = strcmp(iemethod,'pchip');
    ismakima = strcmp(iemethod,'makima');
    isnone = strcmp(iemethod,'none');
    
    m = islinear || isnearest || iscubic || isspline || isnext || ...
        isprevious || ispchip || ismakima;
    if (doInterp)
        coder.internal.assert(m, ...
            'MATLAB:griddedInterpolant:BadInterpTypeErrId');
    else
        coder.internal.assert(m || isnone, ...
            'MATLAB:griddedInterpolant:ExtrapolationMethodInvalid');
    end
    
end
