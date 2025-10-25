classdef TimetableTypeChecker < matlab.io.internal.arrow.list.TypeChecker
%TIMETABLETYPECHECKER Validates cell arrays containing timetables can be
% exported as Parquet LIST of Parquet STRUCT columns.
%
% Example:
%       import matlab.io.internal.arrow.list.*
%
%       % Create a TimetableTypeChecker from a timetable
%       tt = timetable(1, "A", RowTimes=seconds(1), VariableNames=["X", "Y"]);
%       ttTypeChecker = typeCheckerFactory(tt);
%
%       % Check if tt2's schema is consistent with the schema encoded by ttTypeChecker
%       tt2 = timetable(1, "B", RowTimes=datetime(2020, 1, 1), VariableNames=["X", "Y"]);
%
%       % tt2's RowTime variable is a datetime instead of a duration, so checkType errors
%       checkType(ttTypeChecker, tt2);
%
% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private, GetAccess = public)
        % RowTimesName      A string specifying the expected dimension name
        %                   for the RowTimes column.
        RowTimesName(1, 1) string

        % RowTimesChecker   A TypeChecker object used to verify the
        %                   RowTimes column of the timetables are
        %                   compatible, i.e. all durations or all
        %                   datetimes.
        RowTimesChecker(1, :) matlab.io.internal.arrow.list.ClassTypeChecker

        %TabularTypeChecker     A scalar TabularTypeChecker object that
        %                       verifies the variable names and variable
        %                       types of each timetable are consistent.
        TabularTypeChecker(1, 1) matlab.io.internal.arrow.list.TabularTypeChecker
    end

    methods
        function checkType(obj, data)
        % CHECKTYPE Validates the input DATA is a table with the
        % following properties:
        %
        %   1. The number of variables in DATA is equal to the size of the
        %      properties VariableNames and VariableTypeCheckers.
        %
        %   2. The names of the variables in DATA match the property
        %      VariableNames.
        %
        %   3. The schema of data is consistent with the schema encoded by
        %      the VariableTypeCheckers property. For example, if
        %      VariableTypeCheckers(1) is a DatetimeTypeChecker whose
        %      HasTimeZone property is true, then the first variable in
        %      data must be a timezone-aware datetime.
        %
        %   4. The RowTimes property of the timetable data is consistent
        %      with the schema encoded by RowTimesChecker. For example, if
        %      RowTimesChecker is a ClassTypeChecker whose
        %      ClassType="duration", then the RowTimes of data must be a
        %      duration array.
        %
        %   5. The name of the RowTimes variable in data must equal the
        %      property RowTimesName.
        %
        %   If any of the conditions above are not met, CHECKTYPE errors.

        % Verify data is a timetable.
            if ~istimetable(data)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.NonUniformCell;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, class(data), "timetable");
            end

            % Check the name of the RowTimes variable in data is equal to
            % the RowTimesName property. If not, error.
            if ~isequaln(obj.RowTimesName, data.Properties.DimensionNames{1})
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.RowTimesLabelMismatch;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, data.Properties.DimensionNames{1}, obj.RowTimesName);
            end

            % Check the type of the variable RowTimes variable is
            % consistent with the schema encoded by the RowTimesChecker
            % property. If not, this the checkType of RowTimesChecker wil
            % lerror.
            try
                obj.RowTimesChecker.checkType(data.Properties.RowTimes)
            catch ME
                matlab.io.internal.arrow.error.appendDotIndexOperation(ME, obj.RowTimesName);
            end
            % Invoke the checkType method of TabularTypeChecker. This will
            % make sure the variable names and variable types of the
            % timetable data are consistent with the expected schema.
            obj.TabularTypeChecker.checkType(data);
        end
    end

    methods(Static)
        function obj = build(tt)
            arguments
                tt timetable
            end

            import matlab.io.internal.arrow.list.typeCheckerFactory
            import matlab.io.internal.arrow.list.TimetableTypeChecker
            import matlab.io.internal.arrow.list.TabularTypeChecker

            % Create the TabularTypeChecker which will validate the
            % variable names and variable types of timetables are
            % consistent with its expected schema.
            tabularTypeChecker = TabularTypeChecker.build(tt);

            obj = TimetableTypeChecker;
            obj.RowTimesName = tt.Properties.DimensionNames{1};
            obj.RowTimesChecker = typeCheckerFactory(tt.Properties.RowTimes);
            obj.TabularTypeChecker = tabularTypeChecker;
        end
    end
end
