function c = rdivide(a,b) %#codegen
%RDIVIDE Right division for durations.

%   Copyright 2019-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;
if isa(a,'duration')
    if isa(b,'duration')
        c = a.millis ./ b.millis; % unitless numeric result
    else
        % Numeric input b is interpreted as a scale factor.
        [b,validConversion] = matlab.internal.coder.timefun.validateScaleFactor(b);
        coder.internal.assert(validConversion,'MATLAB:duration:DivisionNotDefined',class(a),class(b));
        c = matlab.internal.coder.duration;
        c.fmt = a.fmt;
        c.millis = a.millis ./ b;
    end
else % isa(b,'duration')
    coder.internal.errorIf(isa(b,'duration'),'MATLAB:duration:DurationDivisionNotDefined',class(a));
end


