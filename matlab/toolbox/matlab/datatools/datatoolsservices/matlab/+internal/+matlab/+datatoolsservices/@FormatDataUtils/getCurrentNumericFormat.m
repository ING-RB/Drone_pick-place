% This method returns the current Numeric format in MATLAB. Additional param c
% would be a local function variable that would cause the formats to be restored
% when c goes out of scope. NOTE: The recommended way to learn the current
% format is from the settings object.

% Copyright 2015-2023 The MathWorks, Inc.

function [currentFormat, c] = getCurrentNumericFormat (shouldRestoreFormat)
    if nargin < 1
        shouldRestoreFormat = false;
    end
    c = [];
    s = settings;
    currentFormat = s.matlab.commandwindow.NumericFormat.ActiveValue;
    if (shouldRestoreFormat)
        hasTempFormat = s.matlab.commandwindow.NumericFormat.hasTemporaryValue;
        c = onCleanup(@() internal.matlab.datatoolsservices.FormatDataUtils.restoreNumericFormat(currentFormat, hasTempFormat));
    end
end
