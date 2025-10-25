function c = plus(a,b) %#codegen

%PLUS Addition for durations.

%   Copyright 2019-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;
% datetime and calendarDuration are superor, dispatch goes there
    c = matlab.internal.coder.duration;
if isa(a,'duration')
    c.fmt = a.fmt;
    if isa(b,'duration')
        % Add one duration to another.
        c.millis = a.millis + b.millis;
    else
        % Add a number of standard days to a duration.
        [bmillis,validConversion] = matlab.internal.coder.timefun.datenumToMillis(b);
        coder.internal.assert(validConversion,'MATLAB:duration:AdditionNotDefined',class(a),class(b));
        c.millis = a.millis + bmillis;
    end
else % isa(b,'duration')
    % Add a number of standard days to a duration.
    [amillis, validConversion] = matlab.internal.coder.timefun.datenumToMillis(a);
    coder.internal.assert(validConversion,'MATLAB:duration:AdditionNotDefined',class(a),class(b));
    c.fmt = b.fmt;
    c.millis = amillis + b.millis;
end

