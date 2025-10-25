function [datetimeStruct, validStruct] = buildDatetimeStruct(datetimeArray)
%BUILDDATETIMESTRUCT 
%   Builds the struct array used to datetime arrays in the C++
%   layer.
%
% NOTE: Datetime arrays are converted to the POSIX time (relative to the
% UNIX epoch, ignoring leap seconds). Arrow has two separate
% datatypes for Date and Timestamp. Since the Parquet library seems to
% truncate the arrow::Date types to 32-bit integers, we will just convert
% all datetime arrays to 64-bit arrow::Timestamp arrays for now.
%
% DATETIMESTRUCT is a scalar struct.
%
% DATETIMESTRUCT contains the following fields:
%
% Field Name    Class      Description
% ----------    ------     ----------------------------------------------
% Values        int64      Posix values of the datetimes (in microseconds).
% Units         char       Always set to 'microseconds'.
% TimeZone      char       Time zone used to interpret the dates.
%
% VALIDSTRUCT is a scalar struct that represents DATETIMEARRAY'S valid
% elements as a bit-packed logical array.
% 
% See matlab.io.arrow.internal.matlab2arrow.bitPackLogical for details
% about VALIDSTRUCT'S schema.

%   Copyright 2021 The MathWorks, Inc.

    import matlab.io.internal.arrow.error.ExceptionType
    import matlab.io.internal.arrow.error.ExceptionFactory
    import matlab.io.arrow.internal.matlab2arrow.bitPackLogical

    % Use microseconds (1e6) as the time unit for balance between
    % precision and range.
    ticksPerSecond = 1e6;

    natIndices = isnat(datetimeArray);
    validTimeIndices = ~natIndices;
    values = zeros(size(datetimeArray), "int64");
    try
        % The default epoch used by convertTo is Jan-1-1970 or Jan-1-1970
        % UTC, depending on whether the input datetime is timezone-aware.
        values(validTimeIndices) = convertTo(datetimeArray(validTimeIndices),...
            "epochtime", TicksPerSecond=ticksPerSecond);
    catch ME
        if ME.identifier == "MATLAB:datetime:EpochTimeConversionOutOfRange"
            % Provided a datetime that is more than 2^63-1 ticks before or
            % after the epoch. Cannot accurately convert to an int64 array.
            ExceptionFactory.throw(ExceptionType.DatetimeOutOfRange);
        end
        % Encountered an unexpected error.
        rethrow(ME);
    end

    datetimeStruct.Values = values;
    datetimeStruct.TimeZone = datetimeArray.TimeZone;
    datetimeStruct.Units = 'microseconds'; 

    % Call bitPackLogical instead of buildValidStruct to avoid
    % recomputing the natIndices/validTimeIndices vectors.
    if any(natIndices)
        validStruct = bitPackLogical(validTimeIndices);
    else
        validStruct = bitPackLogical(false(0, 0));
    end
end
