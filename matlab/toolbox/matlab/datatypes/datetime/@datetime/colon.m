function c = colon(a,d,b)
%

%   Copyright 2014-2025 The MathWorks, Inc.

import matlab.internal.datetime.addToDateField
import matlab.internal.datetime.datetimeAdd
import matlab.internal.datetime.datetimeSubtract
import matlab.internal.datetime.datenumToMillis
import matlab.internal.datetime.diffDateFields
import matlab.internal.datatypes.throwInstead

try

    if nargin < 3
        b = d;
        d = caldays(1);
    else
        if isa(d,'duration')
            % Step by a duration.
            d = milliseconds(d);
        elseif isa(d,'calendarDuration')
            % Step by a calendarDuration.
        else
            % Numeric input interpreted as a number of fixed-length days.
            try
                d = datenumToMillis(d);
            catch ME
                throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:datetime:colon:NonNumericStep'));
            end
        end
    end

    try
        [a_data,b_data,c] = datetime.compareUtil(a,b);
    catch ME
        throwInstead(ME,'MATLAB:datetime:InvalidComparison',message('MATLAB:datetime:colon:InvalidColon'));
    end

    if ~isscalar(a_data) || ~isscalar(b_data) || ~isscalar(d)
        if numel(a_data)>1 || numel(b_data)>1 || numel(d)>1
            error(message('MATLAB:datetime:colon:NonScalarInputs'));
        end
        
        % Either a_data, b_data or d is empty at this point (non-empty ones
        % are scalar), colon returns 1x0 datetime consistent with builtin
        c.data = colon([],[]);
        return;
    end

    if isnumeric(d) % d was a duration, or numeric
        c_data = datetimeAdd(a_data,colon(0,d,datetimeSubtract(b_data,a_data)));
    else
        [dt(1),dt(2)] = split(d,{'month' 'day'}); dt(3) = milliseconds(time(d));
        ucal = datetime.dateFields;
        if sum(dt ~= 0) > 1 % mixed-calendar-units step size
            c_tz = c.tz;
            c_data = a_data;
            fieldIDs = [ucal.MONTH ucal.DAY_OF_MONTH ucal.MILLISECOND_OF_DAY];
            % Always take a step to determine which direction the step will go. Only then
            % do we know whether the stopping criterion is positive or negative.
            a_data = addToDateFields(a_data,{dt(1) dt(2) dt(3)},fieldIDs,c_tz);
            stepSign = sign(datetimeSubtract(a_data,c_data));
            while true
                d = stepSign*datetimeSubtract(a_data,b_data); % current step to endpoint, positive is "too far"
                c_data(end+1) = a_data; %#ok<AGROW>
                if d >= 0, break; end % at or past the endpoint
                % If b contains both days and months, a + b + ... + b is not necessarily the
                % same as a + i*b. This is the former.
                a_data = addToDateFields(a_data,{dt(1) dt(2) dt(3)},fieldIDs,c_tz);
            end
            if d > 0 % stepped past the endpoint
                c_data(end) = [];
            end
        elseif dt(1) ~= 0 % faster calculation for pure calendar months step size
            diffCalmonths = diffDateFields(a_data,b_data,ucal.MONTH,c.tz);
            if diffCalmonths == 0
                % b and a differ by less than 1 calmonth, so diffDateFields correctly
                % returned 0. But when their difference is opposite the step (or zero),
                % that leads to a scalar result rather than empty.
                if dt(1) * datetimeSubtract(b_data,a_data) < 0 % (a-1mo)<b<a and step>0 or a<b<(a+1mo) and step<0
                    diffCalmonths = [];
                end
            end
            c_data = addToDateField(a_data,colon(0,dt(1),diffCalmonths),ucal.MONTH,c.tz);
        elseif dt(2) ~= 0 % faster calculation for pure calendar days step size
            if isempty(c.tz)
                % For unzoned datetimes, days is equivalent to caldays but faster
                c_data = datetimeAdd(a_data,colon(0,datenumToMillis(dt(2)),datetimeSubtract(b_data,a_data)));
            else
                diffCaldays = diffDateFields(a_data,b_data,ucal.DAY_OF_MONTH,c.tz);
                if diffCaldays == 0
                    % b and a differ by less than 1 calday, so diffDateFields correctly
                    % returned 0. But when their difference is opposite the step (or zero),
                    % that leads to a scalar result rather than empty.
                    if dt(2) * datetimeSubtract(b_data,a_data) < 0 % (a-1d)<b<a and step>0 or a<b<(a+1d) and step<0
                        diffCaldays = [];
                    end
                end
                c_data = addToDateField(a_data,colon(0,dt(2),diffCaldays),ucal.DAY_OF_MONTH,c.tz);
            end
        else % dt(3) ~= 0,  faster calculation for pure time step size
            c_data = datetimeAdd(a_data,colon(0,dt(3),datetimeSubtract(b_data,a_data)));
        end
    end
    c.data = c_data;

catch ME
    throw(ME);
end
