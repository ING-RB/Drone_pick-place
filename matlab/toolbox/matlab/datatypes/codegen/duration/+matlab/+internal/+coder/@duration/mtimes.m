function c = mtimes(a,b) %#codegen
%MTIMES Matrix multiplication for durations.

%   Copyright 2019 The MathWorks, Inc.

% Numeric input interpreted as a scale factor.
c = matlab.internal.coder.duration;
if isa(a,'duration')
    coder.internal.errorIf(isa(b,'duration'),'MATLAB:duration:DurationMultiplicationNotDefined');
    [b,validConversion] = matlab.internal.coder.timefun.validateScaleFactor(b);
    coder.internal.assert(validConversion,'MATLAB:duration:MultiplicationNotDefined',class(a),class(b));
    c.fmt = a.fmt;
    c.millis = a.millis * b;
elseif isa(b,'duration')
    [a,validConversion] = matlab.internal.coder.timefun.validateScaleFactor(a);
    coder.internal.assert(validConversion,'MATLAB:duration:MultiplicationNotDefined',class(a),class(b));
    c.fmt = b.fmt;
    c.millis = a * b.millis;
end

