function [NARG,METHOD,EXTRAPp] = methodAndExtrapP(varargin)
    % Return the number of grid/data arguments, the interpolation method, and
    % whether or not to extrapolate.

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    coder.inline('always');
    coder.internal.prefer_const(varargin);
    if nargin >= 2 && coder.internal.isCharOrScalarString(varargin{end - 1})
        coder.internal.assert(coder.internal.isCharOrScalarString(varargin{end}), ...
            'MATLAB:griddedInterpolant:NonFloatValuesErrId');
        coder.internal.assert(coder.internal.isConst(varargin{end}), ...
            'Coder:toolbox:MethodMustBeConstant');
        coder.internal.assert(coder.internal.isConst(varargin{end - 1}), ...
            'Coder:toolbox:MethodMustBeConstant');
        NARG = coder.internal.indexInt(nargin - 2);
        Method = varargin{end - 1};
        ExtrapMethod = varargin{end};
    elseif coder.internal.isCharOrScalarString(varargin{end})
        coder.internal.assert(coder.internal.isConst(varargin{end}), ...
            'Coder:toolbox:MethodMustBeConstant');
        NARG = coder.internal.indexInt(nargin - 1);
        Method = varargin{end};
        ExtrapMethod = Method;
    else
        NARG = coder.internal.indexInt(nargin);
        Method = 'linear';
        ExtrapMethod = 'linear';
    end
    IMethod = convertStringsToChars(Method);
    EMethod = convertStringsToChars(ExtrapMethod);
    coder.internal.griddedInterpolant.parseInterpExtrapMethod(IMethod, true);
    coder.internal.griddedInterpolant.parseInterpExtrapMethod(EMethod, false);
    METHOD = coder.internal.interpolate.StringToMethodID(IMethod);
    EXTRAPp = coder.internal.interpolate.StringToMethodID(EMethod);            
end
