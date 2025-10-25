function isCompat = checkCompatibleTZ(tz1,arg2,arg3) %#codegen
%CHECKCOMPATIBLETZ Check whether two time zones are compatible, including with respect to leap seconds.
%   CHECKCOMPATIBLETZ(TZ1,TZ2) errors if one of TZ1 or TZ2 is empty but the
%   other is not, or if one is "UTCLeapSeconds" but the other is not.
%
%   CHECKCOMPATIBLETZ(TZ,ISUNZONED,ISLEAPSECSTZ) errors if ISEMPTY(TZ) is not equal
%   to ISUNZONED, or if TZ=="UTCLeapSeconds" is not equal to ISLEAPSECSTZ.
%
%   ISCOMPATIBLE = CHECKCOMPATIBLETZ(...) returns FALSE instead of erroring.

%   Copyright 2022 The MathWorks, Inc.

isCompat = true;
if nargin == 2 % checkCompatibleTZ(tz1,tz2)
    isUnzoned = isempty(arg2);
else
    isUnzoned = arg2;
end
if isempty(tz1) ~= isUnzoned
    coder.internal.errorIf(nargout == 0,'MATLAB:datetime:IncompatibleTZ');
    isCompat = false;

elseif ~isempty(tz1)
    if nargin == 2 % only get this if needed
        isLeapSecs = (arg2 == datetime.UTCLeapSecsZoneID);
    else
        isLeapSecs = arg3;
    end            
    if (tz1 == datetime.UTCLeapSecsZoneID) ~= isLeapSecs
        coder.internal.errorIf(nargout == 0,'MATLAB:datetime:IncompatibleTZLeapSeconds');
        isCompat = false;
    end
end
