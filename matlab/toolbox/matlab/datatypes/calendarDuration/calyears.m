function y = calyears(n)
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
    ME = MException(message('MATLAB:calendarDuration:DatetimeInputCalyears'));
    ME = addCorrection(ME,ReplaceIdentifierCorrection('calyears','year'));
    throw(ME);
elseif isa(n,'duration')
    ME = MException(message('MATLAB:calendarDuration:DurationInputCalyears'));
    ME = addCorrection(ME,ReplaceIdentifierCorrection('calyears','years'));
    throw(ME);
else
    error(message('MATLAB:calendarDuration:InvalidCalDurationData'));
end

try
    y = calendarDuration(n,0,0);
catch ME
    matlab.internal.datatypes.throwInstead(ME,...
        "MATLAB:calendarDuration:MustBeInteger", ...
        "MATLAB:calendarDuration:NonintegerCalYearsData");
end
