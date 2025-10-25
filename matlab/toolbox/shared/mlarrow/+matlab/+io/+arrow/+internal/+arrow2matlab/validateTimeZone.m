function tz = validateTimeZone(tz, opts)
%VALIDATETIMEZONE Validates the input timezone (tz) is known and returns the
% canonical version of the timezone. If tz is not a known timezone, a
% warning is issued and the timezone returned is UTC.

% Copyright 2022 The MathWorks, Inc.
    try
        tz = matlab.internal.datetime.getCanonicalTZ(tz, false);
    catch ME
         % Rethrow if the caught exception was not UnknownTimeZone
        if ME.identifier ~= "MATLAB:datetime:UnknownTimeZone"
            rethrow(ME);
        end

        % Otherwise issue a warning and return the timezone 'UTC'
        displayTimeZoneWarning(tz, opts);
        tz = 'UTC';
    end
end

function displayTimeZoneWarning(tz, opts)
    oldState = warning("off", "backtrace");
    cleanup = onCleanup(@()warning(oldState));
    if opts.IsTableVariable
        id = "MATLAB:io:arrow:arrow2matlab:UnknownTZTableVariable";
        warning(message(id, opts.TableVariableName, tz));
    else
        id = "MATLAB:io:arrow:arrow2matlab:UnknownTZ";
        warning(message(id, tz));
    end
end