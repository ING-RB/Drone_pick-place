function validateEventLengths(lengths,rowTimesType)
% VALIDATEEVENTENDS Validates that the event lengths variable is compatible for the
% given row times type.

%   Copyright 2023 The MathWorks, Inc.

lengthsType = class(lengths);
% Event lengths must be a duration or calendarDuration column vector.
if ~matches(lengthsType,["duration" "calendarDuration"]) || ~iscolumn(lengths)
    error(message("MATLAB:eventtable:InvalidLengthsVariable"))
end

% Event lengths cannot be calendarDurations if the row times are durations.
if strcmp(rowTimesType,"duration") && strcmp(lengthsType,"calendarDuration")
    error(message("MATLAB:eventtable:IncompatibleLengthsRowTimes"))
end