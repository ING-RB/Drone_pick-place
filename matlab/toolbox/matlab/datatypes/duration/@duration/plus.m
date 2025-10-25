function c = plus(a,b)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.datenumToMillis
import matlab.internal.datatypes.throwInstead

% datetime and calendarDuration are superor, dispatch goes there

if isa(a,'duration')
    if isa(b,'duration')
        % Add one duration to another.
        c = a;
        c.millis = a.millis + b.millis;
    else
        % Add a number of standard days to a duration.
        try
            bmillis = datenumToMillis(b);
        catch ME
            throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:duration:AdditionNotDefined',class(a),class(b)));
        end
        c = a;
        c.millis = a.millis + bmillis;
    end
else % isa(b,'duration')
    % Add a number of standard days to a duration.
    try
        amillis = datenumToMillis(a);
    catch ME
        throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:duration:AdditionNotDefined',class(a),class(b)));
    end
    c = b;
    c.millis = amillis + b.millis;
end
