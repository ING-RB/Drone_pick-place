function c = ldivide(a,b) %#codegen
%LDIVIDE Left division for durations.

%   Copyright 2019-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;
if isa(a,'duration')
    coder.internal.assert(isa(b,'duration'),'MATLAB:duration:DurationDivisionNotDefined',class(b));
    c = a.millis .\ b.millis; % unitless numeric result
else % isa(b,'duration')
    % Numeric input a is interpreted as a scale factor.
    [a,validConversion] = matlab.internal.coder.timefun.validateScaleFactor(a);
    coder.internal.assert(validConversion,'MATLAB:duration:DivisionNotDefined',class(a),class(b));
    c = matlab.internal.coder.duration;
    c.fmt = b.fmt;
    c.millis = a .\ b.millis;
end
