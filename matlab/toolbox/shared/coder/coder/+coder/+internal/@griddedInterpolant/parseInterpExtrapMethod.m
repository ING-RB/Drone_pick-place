function parseInterpExtrapMethod(A, doInterp)
    % checks if the methods supplied are valid

    %   Copyright 2022 The MathWorks, Inc.
    
    %#codegen

    if (doInterp)
        coder.internal.assert(coder.internal.isCharOrScalarString(A), ...
            'MATLAB:griddedInterpolant:BadInterpTypeErrId');
    else
        coder.internal.assert(coder.internal.isCharOrScalarString(A), ...
            'MATLAB:griddedInterpolant:ExtrapolationMethodInvalid');
    end

    coder.internal.griddedInterpolant.methodCheck(A, doInterp);

end
