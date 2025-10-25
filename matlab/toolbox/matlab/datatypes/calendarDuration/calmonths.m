function m = calmonths(n)
%

%   Copyright 2014-2024 The MathWorks, Inc.
import matlab.lang.correction.ReplaceIdentifierCorrection

if nargin < 1
    n = 1;
elseif isnumeric(n)
    % OK
elseif islogical(n)
    n = double(n);
elseif isa(n,'datetime')
    ME = MException(message('MATLAB:calendarDuration:DatetimeInputCalmonths'));
    ME = addCorrection(ME,ReplaceIdentifierCorrection('calmonths','month'));
    throw(ME);
else
    error(message('MATLAB:calendarDuration:InvalidCalDurationData'));
end

try
    m = calendarDuration(0,n,0);
catch ME
    matlab.internal.datatypes.throwInstead(ME, ...
        "MATLAB:calendarDuration:MustBeInteger", ...
        "MATLAB:calendarDuration:NonintegerCalMonthsData");
end
