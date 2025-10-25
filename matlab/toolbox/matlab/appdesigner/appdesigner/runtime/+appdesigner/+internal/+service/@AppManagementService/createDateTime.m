function now = createDateTime(~)
    % Helper API, generates the current datetime to be recorded in performance telemetry

%   Copyright 2024 The MathWorks, Inc.

    now = string(datetime('now', 'TimeZone', 'GMT', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
end
