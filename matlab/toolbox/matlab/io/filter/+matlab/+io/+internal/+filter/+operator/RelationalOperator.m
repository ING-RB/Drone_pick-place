classdef RelationalOperator
%RelationalOperator   Represents a filtering operation on a table/timetable variable.
%
%   See also: rowfilter

%   Copyright 2021-2022 The MathWorks, Inc.

    enumeration
        GreaterThan,
        LessThan,
        GreaterThanOrEqualTo,
        LessThanOrEqualTo,
        EqualTo,
        NotEqualTo,
        NoOp
    end

    methods
        function str = string(op)
            import matlab.io.internal.filter.operator.RelationalOperator;

            switch op
                case RelationalOperator.GreaterThan
                    str = ">";
                case RelationalOperator.LessThan
                    str = "<";
                case RelationalOperator.GreaterThanOrEqualTo
                    str = ">=";
                case RelationalOperator.LessThanOrEqualTo
                    str = "<=";
                case RelationalOperator.EqualTo
                    str = "==";
                case RelationalOperator.NotEqualTo
                    str = "~=";
                otherwise
                    error(message('MATLAB:io:filter:filter:OperatorNotSupported'));
            end
        end

        function tf = applyOperator(operator, data, operand, variableName)
            arguments
                operator (1, 1) matlab.io.internal.filter.operator.RelationalOperator
                data
                operand
                variableName (1, 1) string
            end

            import matlab.io.internal.filter.operator.RelationalOperator;
            import matlab.io.internal.filter.util.handleRelationalOperatorError;
            import matlab.io.internal.filter.util.handleCellstrCharRelationalOperation;

            % Store the data and operand before doing cellstr conversion so
            % that any error message shows the original types.
            originalData = data;
            originalOperand = operand;

            % Convert cellstr to string to help with cellstr-char
            % comparisons.
            [data, operand] = handleCellstrCharRelationalOperation(data, operand);

            try
                switch operator
                  case RelationalOperator.GreaterThan
                    tf = data >  operand;
                  case RelationalOperator.GreaterThanOrEqualTo
                    tf = data >= operand;
                  case RelationalOperator.LessThan
                    tf = data <  operand;
                  case RelationalOperator.LessThanOrEqualTo
                    tf = data <= operand;
                  case RelationalOperator.EqualTo
                    tf = data == operand;
                  case RelationalOperator.NotEqualTo
                    tf = data ~= operand;
                  otherwise
                    error(message('MATLAB:io:filter:filter:OperatorNotSupported'));
                end
            catch ME
                % if types mismatched then error accordingly
                varType = string(class(originalData));
                handleRelationalOperatorError(variableName, varType, operator, originalOperand, ME);
            end

            % Error early if the result is not supported for table row
            % indexing.
            import matlab.io.internal.filter.util.validateRelationalOperatorResult
            validateRelationalOperatorResult(tf, variableName, operator, originalOperand, size(data, 1));
        end
    end
end
