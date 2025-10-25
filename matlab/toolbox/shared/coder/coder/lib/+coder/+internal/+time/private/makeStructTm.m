function structTm = makeStructTm()
%MATLAB Code Generation Private Function

% Returns a struct that matches the C struct tm with all fields set to 0.
%
% struct tm {
%     int tm_sec;         /* seconds */
%     int tm_min;         /* minutes */
%     int tm_hour;        /* hours */
%     int tm_mday;        /* day of the month */
%     int tm_mon;         /* month */
%     int tm_year;        /* year */
%     int tm_wday;        /* day of the week */
%     int tm_yday;        /* day in the year */
%     int tm_isdst;       /* daylight saving time */
% };

%   Copyright 2019-2022 The MathWorks, Inc.
%#codegen
ZERO = coder.internal.indexInt(0);
structTm.tm_sec = ZERO;
structTm.tm_min = ZERO;
structTm.tm_hour = ZERO;
structTm.tm_mday = ZERO;
structTm.tm_mon = ZERO;
structTm.tm_year = ZERO;
structTm.tm_wday = ZERO;
structTm.tm_yday = ZERO;
structTm.tm_isdst = ZERO;

cHeader = coder.internal.getCHeaderName('time');
cVarType = coder.internal.getCLibName('struct tm');
coder.cstructname(structTm,cVarType,'extern','HeaderFile',cHeader);

%--------------------------------------------------------------------------
