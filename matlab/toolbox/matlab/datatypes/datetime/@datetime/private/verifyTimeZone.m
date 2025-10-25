function tz = verifyTimeZone(tz,warn)
%VERIFYTIMEZONE Verify a datetime time zone.
%   TZ = VERIFYTIMEZONE(TZ,WARN) verifies time zone TZ. If WARN is true,
%   then the first time VERIFYTIMEZONE('local',true) is called, a warning
%   will be issued.

%   Copyright 2014-2023 The MathWorks, Inc.

import matlab.internal.datetime.getCanonicalTZ



% Keep track of whether this is the first time 'local' has been asked for,
% so any warning given about a non-standard system setting is only given once.
% If this function gets cleared, the warning may get thrown (once) again.
persistent warnedOnceForLocal
if isempty(warnedOnceForLocal)
    warnedOnceForLocal = false;
end

if nargin < 2, warn = true; end

try %#ok<ALIGN>

    if strcmpi(tz,'local')
        % Check for and warn about a non-standard system/session local time zone
        % setting, but only if asked to, and only if this is the first time 'local' has
        % been used. This isn't foolproof for contexts where datetime.setLocalTimeZone
        % is used: setLocalTimeZone should always be called at the start of a session,
        % but if 'local' is used before that, the new local time zone setting won't ever
        % be checked or warned about if non-standard.
        if warn && ~warnedOnceForLocal
            % Call getCanonicalTZ with 'local' so it will throw the "system" version
            % of its warnings. Give it the uncanonicalized value we already have, which
            % might be from the system, or the client override, or the UTC failsafe.
            % getCanonicalTZ won't error, because the uncanonicalized value is at worst
            % non-standard, datetime.getsetLocalTimeZone has already recognized it.
            tz = getCanonicalTZ(tz,true,datetime.getsetLocalTimeZone('uncanonical'));
            warnedOnceForLocal = true;
        else
            % datetime.getsetLocalTimeZone's output can always be assumed valid
            % (and in fact canonical). If we don't need to warn for a non-standard
            % local time zone, just return one of those.
            tz = datetime.getsetLocalTimeZone();
        end

    else
        if isduration(tz)
            if floor(tz) < tz
                error(message("MATLAB:datetime:InvalidDurationTZPrecision"));
            end
            tzStr = string(tz,"hh:mm:ss");
            if tz >= 0
                tzStr = "+" + tzStr;
            end
            tz = tzStr;
        end
        tz = getCanonicalTZ(tz,warn);
    end
catch ME, throwAsCaller(ME); end
