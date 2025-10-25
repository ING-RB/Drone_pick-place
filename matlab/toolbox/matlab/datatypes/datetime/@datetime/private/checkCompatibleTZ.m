function checkCompatibleTZ(tz,isUnzoned,isLeapSecs)
%CHECKCOMPATIBLETZ Check whether two time zones are compatible, including with respect to leap seconds.
%   CHECKCOMPATIBLETZ(TZ1,TZ2) errors if one of TZ1 or TZ2 is empty but the
%   other is not, or if one is "UTCLeapSeconds" but the other is not.
%
%   CHECKCOMPATIBLETZ(TZ,ISUNZONED,ISLEAPSECSTZ) errors if ISEMPTY(TZ) is not equal
%   to ISUNZONED, or if TZ=="UTCLeapSeconds" is not equal to ISLEAPSECSTZ.

%   Copyright 2022 The MathWorks, Inc.

if nargin == 2 % checkCompatibleTZ(tz1,tz2)
    tz2 = isUnzoned;
    isUnzoned = isempty(tz2);
end
if isempty(tz) ~= isUnzoned
    error(message("MATLAB:datetime:IncompatibleTZ"));

elseif ~isempty(tz)
    if nargin == 2 % only get this if needed
        isLeapSecs = (tz2 == datetime.UTCLeapSecsZoneID);
    end            
    if (tz == datetime.UTCLeapSecsZoneID) ~= isLeapSecs
        error(message("MATLAB:datetime:IncompatibleTZLeapSeconds"));
    end
end
