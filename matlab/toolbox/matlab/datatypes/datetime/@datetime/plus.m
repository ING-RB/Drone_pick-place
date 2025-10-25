function c = plus(a,b)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.datetimeAdd
import matlab.internal.datetime.datenumToMillis
import matlab.internal.datatypes.throwInstead

try
    try
        [a,b] = datetime.arithUtil(a,b); % durations become numeric, in days
    catch ME
        throwInstead(ME,{'MATLAB:datetime:AutoConvertString','MATLAB:datetime:AutoConvertStrings'},...
            message('MATLAB:datetime:AutoConvertStringAdd'));
    end
    if isa(a,'datetime')
        if isa(b,'datetime')
            error(message('MATLAB:datetime:DatetimeAdditionNotDefined'));
        end
        c = a;
        op = b;
    else %isa(b,'datetime')
        c = b;
        op = a;
    end
    
    if isa(op,'duration')
        c.data = datetimeAdd(c.data,milliseconds(op));
    elseif isa(op,'calendarDuration')
        ucal = datetime.dateFields;
        [op_fields{1:3}] = split(op,{'month' 'day' 'time'});
        op_fields{3} = milliseconds(op_fields{3});
        fieldIDs = [ucal.MONTH ucal.DAY_OF_MONTH ucal.MILLISECOND_OF_DAY];
        c.data = addToDateFields(c.data,op_fields,fieldIDs,c.tz);
    else
        try
            ms = datenumToMillis(op);
        catch ME
            throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:datetime:AdditionNotDefined',class(c),class(op)));
        end
        % Add a multiple of 24 hours
        c.data = datetimeAdd(c.data,ms);
    end

catch ME
    throw(ME);
end
