classdef TabularTypeChecker < matlab.io.internal.arrow.list.TypeChecker
%TABULARTYPECHECKER Validates cell arrays containing tabular data can be
% exported as Parquet LIST of Parquet STRUCT columns.
%
% Example:
%
%       import matlab.io.internal.arrow.list.*
%
%       % Create a TabularTypeChecker from a table with three variables
%       % (X, Y, and Z), whose types are double, string, and datetime.
%
%       t = table(1, "A", datetime("now"), VariableNames=["X", "Y", "Z"]);
%       tabularChecker = TabularTypeChecker.build(t)
%
%       % Check if t2's schema is consistent with the schema encoded by tabularChecker
%       t2 = table(true, "B", datetime("now"), VariableNames=["X", "Y", "Z"]);
%
%       % t2's first variable is a logical (not a double), so checkType errors.
%       checkType(tabularChecker, t2);
%
%       % Check if t3's schema is consistent with the schema encoded by tabularChecker
%       t3 = table(2, "B", datetime(2020, 1, 1), VariableNames=["X", "B", "Z"]);
%
%       % The name of the second variable in t3 is "B" instead of "Y", so checkType errors.
%       checkType(tabularChecker, t3);
%
%       % Check if t4's schema is consistent with the schema encoded by tabularChecker
%       t4 = table(3, "C", datetime(2021, 1, 1), VariableNames=["X", "Y", "Z"]);
%
%       % t4's schema is consistent with the schema encoded by tabularChecker, so checkType does NOT error.
%       checkType(tabularChecker, t4);

% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private)
        % VariableNames         A string array containing the expected
        %                       variables each tabular object must have.
        VariableNames(1, :) string

        % VariableTypeCheckers  An array of TypeChecker objects that encode
        %                       the schema each tabular object must have.
        VariableTypeCheckers(1, :) matlab.io.internal.arrow.list.TypeChecker
    end

    methods
        function checkType(obj, data)
        % CHECKTYPE Validates the input DATA is a tabular with the
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
        %   If any of the conditions above are not met, CHECKTYPE errors.

            if ~isequaln(obj.VariableNames, data.Properties.VariableNames)
                % DATA either doesn't have the same number of variable
                % names or its variable names do not exactly match the
                % property VariableNames. Error.
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.NonUniformVarNames;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(...
                    exceptionType, data.Properties.VariableNames, obj.VariableNames, class(data));
            end

            % Iterate over the VariableTypeCheckers array and call
            % checkType. If one of the variable's type is not
            % schema-consistent, then the checkType call will error.
            for ii = 1:numel(obj.VariableTypeCheckers)
                try
                    obj.VariableTypeCheckers(ii).checkType(data.(ii));
                catch ME
                    % Appends an IndexOperation whose Type=Dot if ME is
                    % an ArrowException. Then throws the exception again.
                    matlab.io.internal.arrow.error.appendDotIndexOperation(...
                        ME, obj.VariableNames(ii));
                end
            end
        end
    end

    methods(Static)
        function obj = build(t)
        % BUILD Builds a TabularTypeChecker object from a tabular data
        % structure.
            arguments
                t tabular
            end

            import matlab.io.internal.arrow.list.typeCheckerFactory
            import matlab.io.internal.arrow.list.ClassTypeChecker
            import matlab.io.internal.arrow.list.TabularTypeChecker
            import matlab.io.internal.arrow.error.appendDotIndexOperation

            obj = TabularTypeChecker;
            obj.VariableNames = t.Properties.VariableNames;

            numVars = width(t);
            if numVars > 0
                varTypeChecker(numVars) = ClassTypeChecker("double");

                for ii = 1:numVars
                    try
                        varTypeChecker(ii) = typeCheckerFactory(t.(ii));
                    catch ME
                        % Appends an IndexOperation whose Type=Dot if ME is
                        % an ArrowException. Then throws the exception again.
                        matlab.io.internal.arrow.error.appendDotIndexOperation(...
                            ME, obj.VariableNames(ii));
                    end
                end
                obj.VariableTypeCheckers = varTypeChecker;
            end
        end
    end
end
