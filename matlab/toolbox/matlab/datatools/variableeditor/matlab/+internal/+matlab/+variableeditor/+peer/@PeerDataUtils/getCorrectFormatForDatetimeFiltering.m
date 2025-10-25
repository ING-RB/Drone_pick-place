% This function gets the correct format for datetime filtering. If the user's
% format does not contain Year, Month and Day for dates and Hour, Minutes and
% Seconds for times, revert to MATLAB default formats.

% Copyright 2017-2023 The MathWorks, Inc.

function fmt = getCorrectFormatForDatetimeFiltering(userfmt)
    fmt = userfmt;
    dateFormat = matlab.internal.datetime.filterTimeIdentifiers(userfmt);

    if (strcmp(dateFormat, userfmt))
        useDefaultFmt = ~((contains(userfmt, 'y') || contains(userfmt, 'u')) && contains(userfmt, 'M') && ...
            (contains(userfmt, 'D') || contains(userfmt, 'd') || contains(userfmt, 'e')));
        defaultFmt = matlab.internal.datetime.defaultDateFormat();
        defaultFmt_I = 'yyyy-MM-dd';
    else
        useDefaultFmt = ~((contains(userfmt, 'y') || contains(userfmt, 'u')) && contains(userfmt, 'M') && ...
            (contains(userfmt, 'D') || contains(userfmt, 'd') || contains(userfmt, 'e')) && ...
            (contains(userfmt, 'h') || contains(userfmt, 'H')) && contains(userfmt, 'm') && contains(userfmt, 's'));
        defaultFmt = matlab.internal.datetime.defaultFormat();
        defaultFmt_I = 'yyyy-MM-dd HH:mm:ss';
    end

    % g2291599: If the user has changed the datetime display locale in perf.
    % dialog, switch to ISO 8601 numeric format for datetime filtering so that
    % MATLAB can parse the datetime irrespective of the locale.
    s = settings;
    usrDisplayLocale = s.matlab.datetime.DisplayLocale.ActiveValue;
    sysDisplayLocale = s.matlab.datetime.DisplayLocale.FactoryValue;

    if ~strcmp(usrDisplayLocale, sysDisplayLocale)
        fmt = defaultFmt_I;
    elseif (useDefaultFmt)
        fmt = defaultFmt;
    end
end
