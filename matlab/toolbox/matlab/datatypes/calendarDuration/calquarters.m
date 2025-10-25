function q = calquarters(n)
%

%   Copyright 2014-2024 The MathWorks, Inc.
import matlab.lang.correction.ReplaceIdentifierCorrection

if nargin < 1
    n = 1;
elseif isnumeric(n) || islogical(n)
    n = double(n); % so ints can be scaled below
elseif isa(n,'datetime')
    ME = MException(message('MATLAB:calendarDuration:DatetimeInputCalquarters'));
    ME = addCorrection(ME,ReplaceIdentifierCorrection('calquarters','quarter'));
    throw(ME);
else
    error(message('MATLAB:calendarDuration:InvalidCalDurationData'));
end

try
    q = calendarDuration(0,3*n,0,'Format','qmdt');
catch ME
    matlab.internal.datatypes.throwInstead(ME, ...
        "MATLAB:calendarDuration:MustBeInteger", ...
        "MATLAB:calendarDuration:NonintegerCalQuartersData");
end
