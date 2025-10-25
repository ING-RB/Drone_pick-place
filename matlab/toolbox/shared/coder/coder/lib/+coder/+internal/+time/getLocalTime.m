function t = getLocalTime
%MATLAB Code Generation Private Function

% Returns a MATLAB struct emulating the output of the C localtime function
% with an added nanoseconds field for better precision:
%
%   structTm.tm_nsec
%   structTm.tm_sec
%   structTm.tm_min
%   structTm.tm_hour
%   structTm.tm_mday
%   structTm.tm_mon
%   structTm.tm_year
%   structTm.tm_isdst

% tm_year and tm_mon are offset from C by 1900 and 1 respectively to
% give real-world values for the year and month.

%   Copyright 2019-2021 The MathWorks, Inc.
%#codegen
coder.inline("never");
t = coder.internal.time.CoderTimeAPI.getLocalTime();
