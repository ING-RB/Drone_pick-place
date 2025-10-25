classdef TableTypeChecker < matlab.io.internal.arrow.list.TypeChecker
%TABLETYPECHECKER Validates cell arrays containing tables can be exported
% as Parquet LIST of Parquet STRUCT columns.
%
% Example:
%
%       import matlab.io.internal.arrow.list.*
%
%       % Create a TableTypeChecker from a table
%       t = table(1, "A", RowNames="Row1", VariableNames=["X", "Y"]);
%       tableChecker = typeCheckerFactory(t);
%
%       % Check if t2's schema is consistent with the schema encoded by tableChecker
%       t2 = table(2, "B", VariableNames=["X", "Y"]);
%
%       % t2 does not have any row names, so checkType errors.
%       checkType(tableChecker, t2);


% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private, GetAccess = public)
        % RowDimensionName      A string specifying the expected dimension
        %                       name for the RowNames column. If
        %                       RowDimensionName is <missing>, then the
        %                       RowNames' column of every table must be
        %                       empty. <missing> by default.
        RowDimensionName(1, 1) string = missing;

        % TabularTypeChecker    A scalar TabularTypeChecker object that
        %                       verifies the variable names and variable
        %                       types of each table are consistent.
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
        %   3. The schema of DATA is consistent with the schema encoded by
        %      the VariableTypeCheckers property. For example, if
        %      VariableTypeCheckers(1) is a DatetimeTypeChecker whose
        %      HasTimeZone property is true, then the first variable in
        %      DATA must be a timezone-aware datetime.
        %
        %   4. If the RowDimensionName property is not <missing>, then
        %      DATA must be a table with RowNames whose DimensionName is
        %      equal to the RowDimensionName property.
        %
        %   If any of the conditions above are not met, CHECKTYPE errors.

        % Verify data is a table.
            if ~istable(data)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.NonUniformCell;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, class(data), "table");
            end

            % Invoke the checkType method of TabularTypeChecker. This will
            % make sure the variable names and variable types of the table
            % data are consistent with the expected schema.
            obj.TabularTypeChecker.checkType(data);

            % If the RowDimensionName property is <missing>, then data must
            % not have any RowNames. Otherwise Error.
            if ismissing(obj.RowDimensionName)
                if ~isempty(data.Properties.RowNames)
                    exceptionType = matlab.io.internal.arrow.error.ExceptionType.RowNamesMismatch;
                    matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, false);
                end
            else
                % If the RowDimensionName property is not <missing>, then
                % all non-empty tables must have RowNames. However, if 
                % data is an empty table, it is ok for 
                % data.Properties.RowNames to be empty.                 
                if numel(data.Properties.RowNames) ~= height(data)
                    % data does not have RowNames. Error.
                    exceptionType = matlab.io.internal.arrow.error.ExceptionType.RowNamesMismatch;
                    matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                        exceptionType, true);
                elseif obj.RowDimensionName ~= data.Properties.DimensionNames{1}
                    % data has RowNames, but its dimension name does not
                    % match the expected value. Error.
                    exceptionType = matlab.io.internal.arrow.error.ExceptionType.RowNamesLabelMismatch;
                    matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                        exceptionType, data.Properties.DimensionNames{1}, obj.RowDimensionName);
                end
            end
        end
    end

    methods(Static)
        function obj = build(t)
            arguments
                t table
            end

            import matlab.io.internal.arrow.list.TableTypeChecker
            import matlab.io.internal.arrow.list.TabularTypeChecker

            % Create the TabularTypeChecker which will validate the
            % variable names and variable types of tables are consistent
            % with its expected schema.
            tabularTypeChecker = TabularTypeChecker.build(t);

            % The RowDimensionName property will be set to the <missing>
            % string if the input table t has no RowNames.
            rowDimensionName = missing;
            if ~isempty(t.Properties.RowNames)
                rowDimensionName = string(t.Properties.DimensionNames{1});
            end

            % Cannot convert tables with zero variables and zero row names
            % to arrow StructArrays.
            numVariables = numel(tabularTypeChecker.VariableTypeCheckers);
            if ismissing(rowDimensionName) && numVariables == 0
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.ZeroVariableTable;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(exceptionType);
            end

            obj = TableTypeChecker;
            obj.RowDimensionName = rowDimensionName;
            obj.TabularTypeChecker = tabularTypeChecker;
        end
    end
end
