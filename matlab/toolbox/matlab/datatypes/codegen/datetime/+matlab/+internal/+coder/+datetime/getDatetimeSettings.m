function formatSetting = getDatetimeSettings(displayFormat)
%GETDATETIMESETTINGS Retrieve datetime Command Window settings.
%   FORMATSETTING = GETDATETIMESETTINGS returns a SettingsGroup of the
%   current datetime settings.
%
%   FORMATSETTING = GETDATETIMESETTINGS(DISPLAYFORMAT) returns the current
%   datetime setting corresponding to DISPLAYFORMAT as follows:
%   - DISPLAYFORMAT = 'defaultformat'     - Return the default date-only format setting.
%   - DISPLAYFORMAT = 'defaultdateformat' - Return the default date and time format setting.
%   - DISPLAYFORMAT = 'locale'            - Return the locale setting.

%   Copyright 2014-2020 The MathWorks, Inc.

% For performance, store the settings in a persistent variable
persistent datetimeSettings; 
if isempty(datetimeSettings)
    s = settings;
    datetimeSettings = s.matlab.datetime;
end

if nargin < 1
    formatSetting = datetimeSettings;
else
    switch lower(displayFormat)
        case 'defaultformat'
            formatSetting = datetimeSettings.DefaultFormat.ActiveValue;
        case 'defaultdateformat'
            formatSetting = datetimeSettings.DefaultDateFormat.ActiveValue;         
        case 'locale'      
            formatSetting = datetimeSettings.DisplayLocale.ActiveValue;         
         
    end
end
end
