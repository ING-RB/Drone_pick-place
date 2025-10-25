function [inputFormat, displayFormat] = getDateTimeSettings()
% Get datetime related settings for the datepicker component to use
% dynamically for displaying the avatar on drag-drop and setting default
% displayFormat

% Copyright 2018 The MathWorks, Inc.

s = settings;
dateTimeSettings = s.matlab.datetime;

% Check & get custom date format if one exists
dateObject = datetime('today');
if dateTimeSettings.hasSetting('DefaultDateFormat')
    defaultDateFormat = s.matlab.datetime.DefaultDateFormat;
    customDateTimeFormat = defaultDateFormat.ActiveValue;
else
    % Additional check in case FactoryValue not present
    customDateTimeFormat = matlab.internal.datetime.filterTimeIdentifiers(...
        dateObject.Format);
end

% Check if the user set custom format is datepicker acceptable
% if not, return locale default.
% For eg: if user sets date & time default in preferences as: MMM
% This is not acceptable as the inputFormat, therefore a locale
% specific default is returned.
inputFormat = matlab.ui.control.internal.controller.DatePickerController.getInputFormatForView(customDateTimeFormat,dateObject);

% Check custom value is same as inputFormat, if not set as displayFormat
% This can happen in cases where the date & time default in preferences
% contain an alpha-numeric/alphabetic string - in such cases,
% inputFormat is locale specific and displayFormat is the
% user defined string
if ~strcmp(customDateTimeFormat,inputFormat)
    displayFormat = customDateTimeFormat;
else
    displayFormat = inputFormat;
end
end