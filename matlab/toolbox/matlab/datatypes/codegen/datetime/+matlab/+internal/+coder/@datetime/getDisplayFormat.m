function fmt = getDisplayFormat(obj) %#codegen
% GETDISPLAYFORMAT returns the display format for a datetime array. If the
% datetime has a format set explicitly, GETDISPLAYFORMAT returns that.
% Otherwise, GETDISPLAYFORMAT returns the "date only" or the "date+time" display
% format from the preferences, depending on the data in the array.

% Copyright 2014-2019 The MathWorks, Inc.

coder.extrinsic('matlab.internal.coder.datetime.getDatetimeSettings'); 

% Here we use coder.const on the extrinsic function getDatetimeSettings to ensure that
% we can get the default formats from MATLAB at compile time
dfltDateFormat = coder.const(matlab.internal.coder.datetime.getDatetimeSettings('defaultdateformat'));
dfltFormat = coder.const(matlab.internal.coder.datetime.getDatetimeSettings('defaultformat'));

[~,~,~,h,m,s] = matlab.internal.coder.datetime.getDateVec(obj.data);
hasTime = any((h+m+s) > 0,'all');

if ~isempty(obj.fmt)
    fmt = obj.fmt;
else
    if hasTime
        fmt = dfltFormat;
    else
        fmt = dfltDateFormat;
    end
end