function fmt = getDisplayFormat(obj)
%

% GETDISPLAYFORMAT returns the display format for a datetime array. If the
% datetime has a format set explicitly, GETDISPLAYFORMAT returns that.
% Otherwise, GETDISPLAYFORMAT returns the "date only" or the "date+time" display
% format from the preferences, depending on the data in the array.

% Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.getDatetimeSettings

if ~isempty(obj.fmt)
    fmt = obj.fmt; % leave an explicitly-set format alone
else
    hasTime = getDisplayResolution(obj);
    if hasTime
        fmt = getDatetimeSettings('defaultformat');
    else
        fmt = getDatetimeSettings('defaultdateformat');
    end
end
