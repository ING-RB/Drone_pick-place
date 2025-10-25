function c = minus(a,b)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.datetimeSubtract
import matlab.internal.datetime.datenumToMillis
import matlab.internal.datatypes.throwInstead

try

    [a,b] = datetime.arithUtil(a,b);
    
    if isa(a,'datetime')
        if isa(b,'datetime')
            % Return the duration between two datetimes
            ms = datetimeSubtract(a.data,b.data);
            c = duration.fromMillis(ms);
        else
            c = a;
            if isa(b,'duration')
                c.data = datetimeSubtract(c.data,milliseconds(b),true);
            elseif isa(b,'calendarDuration')
                [b_fields{1:3}] = split(b,{'month' 'day' 'time'});
                b_fields{3} = milliseconds(b_fields{3});
                ucal = datetime.dateFields;
                fieldIDs = [ucal.MONTH ucal.DAY_OF_MONTH ucal.MILLISECOND_OF_DAY];
                c.data = subtractFromDateFields(c.data,b_fields,fieldIDs,c.tz);
            else
                try
                    ms = datenumToMillis(b);
                catch ME
                    throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:datetime:SubtractionNotDefined',class(b),class(a)));
                end
                % Subtract a multiple of 24 hours
                c.data = datetimeSubtract(c.data,ms,true);
            end
        end
    else % isa(b,'datetime')
        error(message('MATLAB:datetime:SubtractionNotDefined',class(b),class(a)));
    end
catch ME
    throw(ME);
end
