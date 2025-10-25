function tf = isgroupbins(gb,messageIdent)
% ISGROUPBINS Finds if gb is a groupbin specification
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2022 The MathWorks, Inc.

if isstring(gb)
    % Using cellstr instead of num2cell to avoid changing error IDs
    gb = cellstr(gb);
elseif ~iscell(gb)
    gb = {gb};
end

if isempty(gb) % Catch {} case
    error(message("MATLAB:"+messageIdent+":GroupBinsEmpty"));
elseif isnumeric(gb{1}) || isduration(gb{1}) || iscalendarduration(gb{1}) || isdatetime(gb{1})
    tf = true;
else
    if (ischar(gb{1}) && isrow(gb{1})) || isstring(gb{1})
        tf = any(startsWith(["none", "second", "minute", "hour", "day", "week", "month", "quarter", ...
            "year", "decade", "century", "secondofminute", "minuteofhour", ...
            "hourofday", "dayname","dayofweek", "dayofmonth", "dayofyear", "weekofmonth",...
            "weekofyear", "monthofyear", "monthname", "quarterofyear"],string(gb{1}),"IgnoreCase",true));
    else
        tf = false;
    end
end
