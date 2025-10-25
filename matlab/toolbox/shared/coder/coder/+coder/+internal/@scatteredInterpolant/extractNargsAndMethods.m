function [narg, interpID, extrapID] = extractNargsAndMethods(varargin)
% Return the number of data arguments, the interpolation method, and
% whether or not to extrapolate.

%   Copyright 2024 The MathWorks, Inc.

%#codegen
coder.inline('always');
coder.internal.prefer_const(varargin);

if nargin >= 2 && coder.internal.isCharOrScalarString(varargin{end - 1})
    coder.internal.assert(coder.internal.isCharOrScalarString(varargin{end}), ...
                          'MATLAB:mathcgeo_catalog:NonDblInpPtsErrId');
    coder.internal.assert(coder.internal.isConst(varargin{end}), ...
                          'Coder:toolbox:MethodMustBeConstant');
    coder.internal.assert(coder.internal.isConst(varargin{end - 1}), ...
                          'Coder:toolbox:MethodMustBeConstant');
    narg = coder.internal.indexInt(nargin - 2);
    [interpID, extrapID] = ...
        coder.internal.scatteredInterpolant.validateInterpExtrapMethod( ...
        convertStringsToChars(varargin{end - 1}), ...
        convertStringsToChars(varargin{end}));

elseif coder.internal.isCharOrScalarString(varargin{end})
    coder.internal.assert(coder.internal.isConst(varargin{end}), ...
                          'Coder:toolbox:MethodMustBeConstant');
    narg = coder.internal.indexInt(nargin - 1);
    [interpID, extrapID] = ...
        coder.internal.scatteredInterpolant.validateInterpExtrapMethod( ...
        convertStringsToChars(varargin{end}));

else
    narg = coder.internal.indexInt(nargin);
    [interpID, extrapID] = coder.internal.scatteredInterpolant.validateInterpExtrapMethod();
end
