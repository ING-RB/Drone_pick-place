function d = getGPSWeekRolloverDates(refT)
%This function is for internal use only. It may be removed in the future.

%getGPSWeekRolloverDates Get the dates when GPS week rolls over in SEM or
%   YUMA almanacs. All dates that occur at or before current time or time
%   specified by the users, refT, will be returned.
%   These values will be used for validating inputs to almanac readers and
%   for tab completion.

%   Copyright 2022-2023 The MathWorks, Inc.

% Initialize cell array to store the date strings
d = {};

if nargin ~= 0
    t = refT;
else
    t = datetime;
end
t.TimeZone = 'utcleapseconds';

% Number of days between each rollover
mod1024Weeks = 1024*7;

% GPS reference time
refTime = matlabshared.internal.gnss.GNSSTime.getLocalTime(0,0,'UTCLeapSeconds');

% Keep adding mod1024Weeks to t. These are the dates when the rollover
% occurs. If these dates occur at or before the scenario start time, add
% them to d.
count = 0;
while refTime <= t
    count = count + 1;
    d{count} = datestr(refTime, 'dd-mmm-yyyy');
    refTime = refTime + days(mod1024Weeks);
end

% d must be a column vector for tab completion to work.
d = d';
end
