function c = mldivide(x,a) %#codegen
%MLDIVIDE Left matrix division for durations.

%   Copyright 2019 The MathWorks, Inc.

coder.internal.assert(isscalar(x) && isa(a,'duration'),'MATLAB:duration:MatrixDivisionNotDefined');

if isa(x,'duration')
    c = x.millis \ a.millis; % unitless numeric result
else
    % Numeric input x is interpreted as a scale factor.
    [x,validConversion] = matlab.internal.coder.timefun.validateScaleFactor(x);
    coder.internal.assert(validConversion,'MATLAB:duration:MatrixDivisionNotDefined');
    c = matlab.internal.coder.duration;
    c.fmt = a.fmt;
    c.millis = x \ a.millis;
end
