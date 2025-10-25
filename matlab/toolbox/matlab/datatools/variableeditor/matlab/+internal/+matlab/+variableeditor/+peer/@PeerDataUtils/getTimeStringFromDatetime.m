% This function returns the time component of a datetime as a string, provided
% that the user's data format allows the time values to be displayed.

% Copyright 2017-2023 The MathWorks, Inc.

function t_string = getTimeStringFromDatetime(dt)
    dfmt = matlab.internal.datetime.filterTimeIdentifiers(dt.Format);
    if isempty(dfmt)
        t_string = string(dt);
    else
        [y,m,d] = ymd(dt);
        dt_date = datetime(y,m,d);
        dt_date.Format = dfmt;
        dt_string = string(dt);
        dt_date_string = string(dt_date);
        t_string = replace(dt_string, dt_date_string, '');
        t_string = strtrim(t_string);
    end
end
