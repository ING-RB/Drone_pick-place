function OutputType = validateOutputType(OutputType)
%validateOutputType   Verifies that OutputType is either "table" or
%    "timetable".

%   Copyright 2022 The MathWorks, Inc.

    arguments
        OutputType (1, 1) string
    end

    if ~ismember(OutputType, ["table" "timetable"])
        error(message("MATLAB:io:common:builder:InvalidOutputType"));
    end
end