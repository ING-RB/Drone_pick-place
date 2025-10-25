function interp = getInterpolationMethod(continuity)  %#codegen
% returns interpolation method for a Continuity enumeration. In MATLAB, 
% the interpolation method is a Continuity property. In codegen, 
% enumerations cannot have properties. This function only supports scalar
% inputs.

% Copyright 2020 The MathWorks, Inc.
coder.internal.prefer_const(continuity);
assert(isscalar(continuity));  % scalar only
switch continuity
    case matlab.internal.coder.tabular.Continuity.unset
        interp = "fillwithmissing";
    case matlab.internal.coder.tabular.Continuity.continuous
        interp = "linear";
    case matlab.internal.coder.tabular.Continuity.step
        interp = "previous";
    case matlab.internal.coder.tabular.Continuity.event
        interp = "fillwithmissing";
end