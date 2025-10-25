function c = minus(a,b) %#codegen
%MINUS Subtraction for durations.

%   Copyright 2019-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;
% datetime and calendarDuration are superor, dispatch goes there
c = matlab.internal.coder.duration;
if isa(a,'duration')
    c.fmt = a.fmt;
    if isa(b,'duration')
        c.millis = a.millis - b.millis;
    else
        % Subtract a number of standard days from a duration.
        [bmillis,validConversion] = matlab.internal.coder.timefun.datenumToMillis(b);
        coder.internal.assert(validConversion,'MATLAB:duration:SubtractionNotDefined',class(a),class(b));
        c.millis = a.millis - bmillis;
    end
else % isa(b,'duration')
    % Subtract a duration from a number of standard days.
    [amillis,validConversion] = matlab.internal.coder.timefun.datenumToMillis(a);
    coder.internal.assert(validConversion,'MATLAB:duration:SubtractionNotDefined',class(a),class(b));
    c.fmt = b.fmt;
    c.millis = amillis - b.millis;
end
