classdef DatetimeTypeChecker < matlab.io.internal.arrow.list.ClassTypeChecker
%CATEGORICALTYPECHECKER Validates cell arrays containing datetime vectors
% can be exported as Parquet LIST columns of timestamp arrays.
%
% Example:
%
%       import matlab.io.internal.arrow.list.*
%
%       datetimeChecker = DatetimeTypeChecker(HasTimeZone=true);
%
%       % date1 is timezone-naive, so checkType errors.
%       date1 = datetime(2020, 1, 1);
%       checkType(datetimeChecker, date1);
%
%       % date2 is ordinal, so checkType does NOT error.
%       date2 = datetime(2020, 1, 1, TimeZone="America/New_York");
%       checkType(datetimeChecker, date2);
%
% Copyright 2022 The MathWorks, Inc.

    properties
        % HasTimeZone       Logical indicating if every datetime vector
        %                   must be timezone-aware. False by default.
        HasTimeZone(1, 1) logical = false
    end

    methods
        function obj = DatetimeTypeChecker(nvargs)
            arguments
                nvargs.HasTimeZone = false;
            end
            obj = obj@matlab.io.internal.arrow.list.ClassTypeChecker("datetime");
            obj.HasTimeZone = nvargs.HasTimeZone;
        end

        function checkType(obj, array)
        % Verify the class of array is "datetime"
            checkType@matlab.io.internal.arrow.list.ClassTypeChecker(obj, array);

            hasTimeZone = ~isempty(array.TimeZone);

            % Verify the array is timezone-aware if obj.HasTimeZone is
            % true. Otherwise the array must be timezone-naive.
            if obj.HasTimeZone ~= hasTimeZone
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.IncompatibleTimeZone;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, obj.HasTimeZone);
            end
        end
    end
end
