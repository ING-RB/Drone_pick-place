function startDelay = fixStartDelayIfDatenumWithFormat(fmt, delayyear, assumeDelayMonth, assumeDelayDay, delayhour, delayminute, delaysec, compareAgainstCurrFiringTime)
% we only need to fixup , if a datenum with following call was passed in as
% the firing time
% DateNumber = datenum(DateString,formatIn)
% with formatIn specified as "m" and "d" as specified in following:
% https://www.mathworks.com/help/matlab/ref/datenum.html#btfl6he-1-formatIn

%   Copyright 2019 The MathWorks, Inc.

    delayday = assumeDelayDay;
    delaymonth = assumeDelayMonth;

    dt = datetime('today');

    if ~contains(fmt,'d')
        delayday = dt.Day;
    end

    if ~contains(fmt,'m')
        delaymonth = dt.Month;
    end

    startDelay = 86400 * (datenum([delayyear delaymonth delayday delayhour delayminute delaysec]) - compareAgainstCurrFiringTime);
end
