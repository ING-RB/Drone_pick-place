function datetimeArray = buildDatetime(datetimeStruct, nullIndices, opts)
%BUILDDATETIME 
%   Reads an arrow::Date or an arrow::Timestamp into a MATLAB datetime.
%
% DATA is a scalar struct.
% 
% DATA contains the following field:
%
% Field Name    Class      Description
% ----------    ------     -------------------------------------
% Values        numeric    Required. Array of posix time values.
% DateType      char       Required. Timestamp or Date. 
% Units         char       Species the unit of time.
% TimeZone      char       Required if Units is present.
%
%   Copyright 2021-2022 The MathWorks, Inc.
    
    arguments
        datetimeStruct (1, 1) struct {mustBeDatetimeStruct}
        nullIndices logical
        opts(1, 1) Arrow2MatlabOptions = Arrow2MatlabOptions 
    end
    import matlab.io.arrow.internal.Arrow2MatlabOptions
    import matlab.io.arrow.internal.arrow2matlab.validateTimeZone
    import matlab.io.arrow.internal.arrow2matlab.timeUnitsToMultiplier

    epoch = datetime(1970, 1, 1, TimeZone="UTC");

    date_type = datetimeStruct.DateType;
    if date_type == "Timestamp"
        tz = validateTimeZone(datetimeStruct.TimeZone, opts);
        ticksPerSec = timeUnitsToMultiplier(datetimeStruct.Units);
        datetimeArray = datetime(datetimeStruct.Values, TimeZone=tz,...
            ConvertFrom="epochtime", Epoch=epoch, TicksPerSecond=ticksPerSec);
    else % date_type == 'Date'
        % Convert Arrow Date to datetime.
        % Check if date is in 32-bit days or 64-bit milliseconds.
        if class(datetimeStruct.Values) == "int32"
            datetimeArray = datetime(int64(datetimeStruct.Values) * 24 * 60 * 60, ...
                ConvertFrom="posixtime");
        else
            % not hittable from parquetread.
            datetimeArray = datetime(datetimeStruct.Values, ConvertFrom="epochtime",...
                Epoch=epoch, TicksPerSecond=1e3);
        end
    end
    datetimeArray(nullIndices) = NaT;
end

function mustBeDatetimeStruct(datetimeStruct)
    import matlab.io.arrow.internal.validateStructFields

    validateStructFields(datetimeStruct, ["DateType", "Values"]);    
    dateType = string(datetimeStruct.DateType);
    if dateType == "Timestamp"
        % Validate struct also has a Units field and a TimeZone field if
        % the dateType is equal to 'Timestamp'.
        validateStructFields(datetimeStruct, ["Units", "TimeZone"]);
    elseif dateType ~= "Date"
        id = "MATLAB:io:arrow:arrow2matlab:UnknownDatetimeType";
        error(message(id, dateType)); 
    end
end
