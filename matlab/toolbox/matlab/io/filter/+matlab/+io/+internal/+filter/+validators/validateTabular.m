function validateTabular(T)
%validateTabular   throws if the input is not a table/timetable.
%
%   Intended to be used with funarg validation.

%   Copyright 2021 The MathWorks, Inc.

    if istable(T) || istimetable(T)
        return;
    end

    error(message("MATLAB:io:filter:filter:InvalidFilterInput"));
end