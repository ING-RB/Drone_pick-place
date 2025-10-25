function c = minus(a,b)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.datenumToMillis
import matlab.internal.datatypes.throwInstead

try

    % datetime is superor, dispatch goes there
    
    if isa(a,'calendarDuration')
        c = a;
        c_components = c.components;
        if isa(b,'calendarDuration')
            % Subtract one calendarDuration from another.
            b_components = b.components;
            c_components.months = c_components.months - b_components.months;
            c_components.days   = c_components.days - b_components.days;
            c_components.millis = c_components.millis - b_components.millis;
            c.fmt = calendarDuration.combineFormats(a.fmt,b.fmt);
        elseif isa(b,'duration')
            % Subtract a duration from a calendarDuration.
            c_components.millis = c_components.millis - milliseconds(b);
        else
            % Subtract a multiple of 24 hours from a calendarDuration.
            try
                bmillis = datenumToMillis(b);
            catch ME
                throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:calendarDuration:SubtractionNotDefined',class(a),class(b)));
            end
            c_components.millis = c_components.millis - bmillis;
        end
    else % isa(b,'calendarDuration')
        c = b;
        c_components = c.components;
        c_components.months = -c_components.months;
        if isa(a,'duration')
            % Subtract a calendarDuration from a duration.
            c_components.days = -c_components.days;
            c_components.millis = milliseconds(a) - c_components.millis;
        else
            % Subtract a calendarDuration from a multiple of 24 hours.
            try
                amillis = datenumToMillis(a);
            catch ME
                throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:calendarDuration:SubtractionNotDefined',class(a),class(b)));
            end
            c_components.days = -c_components.days;
            c_components.millis = amillis - c_components.millis;
        end
    end
    
    % Any component that is now not a scalar zero must be expanded to the common
    % scalar/implicit expansion size, even if it becomes an array of a constant
    % (non-zero) value. Leave scalar zeros alone, as memory-saving placeholders.
    c_components = calendarDuration.expandFields(c_components);
    % Different components of the same element might contain different
    % non-finites, reconcile those and put the same non-finite in all three
    % components.
    c.components = calendarDuration.reconcileNonfinites(c_components);

catch ME
    throw(ME);
end
