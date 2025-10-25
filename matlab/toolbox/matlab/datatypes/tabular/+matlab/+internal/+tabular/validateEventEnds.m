function validateEventEnds(ends,rowTimesTemplate)
% VALIDATEEVENTENDS Validates that the event ends variable is compatible for the
% given row times template.

%   Copyright 2023 The MathWorks, Inc.

endsType = class(ends);
% Event ends must be a duration or datetime column vector.
if ~matches(endsType,["datetime","duration"]) || ~iscolumn(ends)
    error(message("MATLAB:eventtable:InvalidEndsVariable"))
end

% Event ends must be the same type as the row times.
if ~isequal(endsType,class(rowTimesTemplate))
    error(message("MATLAB:eventtable:IncompatibleEndsRowTimes"))
end

% Datetime event ends must have the same timezone as the row times.
if isdatetime(ends)
    if isempty(ends.TimeZone) ~= isempty(rowTimesTemplate.TimeZone)
        error(message("MATLAB:eventtable:IncompatibleEndsRowTimesTZ"))
    end
end