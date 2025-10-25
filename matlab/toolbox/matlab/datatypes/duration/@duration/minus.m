function c = minus(a,b)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.datenumToMillis
import matlab.internal.datatypes.throwInstead

% datetime and calendarDuration are superor, dispatch goes there

if isa(a,'duration')
    if isa(b,'duration')
        c = a;
        c.millis = a.millis - b.millis;
    else
        % Subtract a number of standard days from a duration.
        try
            bmillis = datenumToMillis(b);
        catch ME
            throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:duration:SubtractionNotDefined',class(a),class(b)));
        end
        c = a;
        c.millis = a.millis - bmillis;
    end
else % isa(b,'duration')
    % Subtract a duration from a number of standard days.
    try
        amillis = datenumToMillis(a);
    catch ME
        throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:duration:SubtractionNotDefined',class(a),class(b)));
    end
    c = b;
    c.millis = amillis - b.millis;
end
