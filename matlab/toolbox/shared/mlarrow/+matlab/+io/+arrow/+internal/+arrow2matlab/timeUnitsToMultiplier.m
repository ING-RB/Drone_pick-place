function multiplier = timeUnitsToMultiplier(units)
%TIMEUNITSTOMULTIPLIER 
%   Helper function that returns a numeric multiplier for different
%   datetime types.
%
% UNITS must be one of the following values: 'seconds', 'milliseconds',
% 'microseconds', 'nanoseconds'.

%   Copyright 2021-2022 The MathWorks, Inc.

    switch units
        case 'seconds'
            multiplier = 1;
        case 'milliseconds'
            multiplier = 1e3;
        case 'microseconds'
            multiplier = 1e6;
        case 'nanoseconds'
            multiplier = 1e9;
        otherwise
            error(message("MATLAB:io:arrow:arrow2matlab:InvalidTimeUnit", units));
    end
end
