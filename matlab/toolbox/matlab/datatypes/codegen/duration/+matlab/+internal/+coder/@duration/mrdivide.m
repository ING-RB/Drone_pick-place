function c = mrdivide(a,x) %#codegen
%MRDIVIDE Right matrix division for durations.

% This is a stub whose only purpose is to allow A / X for scalar numeric X
% without requiring a dot. Matrix division is not defined in general.

%   Copyright 2019 The MathWorks, Inc.

coder.internal.assert(isscalar(x) && isa(a,'duration'),'MATLAB:duration:MatrixDivisionNotDefined');

if isa(x,'duration')
    c = a.millis / x.millis; % unitless numeric result
else
    % Numeric input a is interpreted as a scale factor.
    [x,validConversion] = matlab.internal.coder.timefun.validateScaleFactor(x);
    coder.internal.assert(validConversion,'MATLAB:duration:MatrixDivisionNotDefined');
    c = matlab.internal.coder.duration;
    c.fmt = a.fmt;
    c.millis = a.millis / x;
end
