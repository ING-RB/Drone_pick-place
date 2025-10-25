function d = caldays(n)
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
    ME = MException(message('MATLAB:calendarDuration:DatetimeInputCaldays'));
    ME = addCorrection(ME,ReplaceIdentifierCorrection('caldays','day'));
    throw(ME);
elseif isa(n,'duration')
    ME = MException(message('MATLAB:calendarDuration:DurationInputCaldays'));
    ME = addCorrection(ME,ReplaceIdentifierCorrection('caldays','days'));
    throw(ME);
else
    error(message('MATLAB:calendarDuration:InvalidCalDurationData'));
end

try
    d = calendarDuration(0,0,n);
catch ME
    matlab.internal.datatypes.throwInstead(ME, ...
        "MATLAB:calendarDuration:MustBeInteger", ...
        "MATLAB:calendarDuration:NonintegerCalDaysData");
end
