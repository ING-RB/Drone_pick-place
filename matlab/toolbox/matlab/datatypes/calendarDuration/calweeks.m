function w = calweeks(n)
%

%   Copyright 2014-2024 The MathWorks, Inc.
import matlab.lang.correction.ReplaceIdentifierCorrection

if nargin < 1
    n = 1;
elseif isnumeric(n) || islogical(n)
    n = double(n); % so ints can be scaled below
elseif isa(n,'datetime')
    ME = MException(message('MATLAB:calendarDuration:DatetimeInputCalweeks'));
    ME = addCorrection(ME,ReplaceIdentifierCorrection('calweeks','week'));
    throw(ME);
else
    error(message('MATLAB:calendarDuration:InvalidCalDurationData'));
end

try
    w = calendarDuration(0,0,7*n,'Format','ymwdt');
catch ME
    matlab.internal.datatypes.throwInstead(ME,...
        "MATLAB:calendarDuration:MustBeInteger", ...
        "MATLAB:calendarDuration:NonintegerCalWeeksData");
end
