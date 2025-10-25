classdef OverloadRelationalOperators
%OverloadRelationalOperators   Helper class for overloading relational operators.

%   Copyright 2021 The MathWorks, Inc.

    properties (Constant, Hidden)
        AllowedFilterTypes (1, :) string = ["matlab.io.internal.filter.UnconstrainedRowFilter", ...
                                            "matlab.io.internal.filter.SingleVariableRowFilter"];
    end

    methods (Abstract, Hidden)
        %applyRelationalOperator   must be implemented by subclasses to
        %   return a new RowFilter object from the inputs.
        newFilter = applyRelationalOperator(filter, operator, operand)
    end

    methods (Hidden)
        function f = lt(lhs, rhs)
            f = makeFilterFromRelationalOperator(lhs, rhs, "<", ">");
        end

        function f = le(lhs, rhs)
            f = makeFilterFromRelationalOperator(lhs, rhs, "<=", ">=");
        end

        function f = gt(lhs, rhs)
            f = makeFilterFromRelationalOperator(lhs, rhs, ">", "<");
        end

        function f = ge(lhs, rhs)
            f = makeFilterFromRelationalOperator(lhs, rhs, ">=", "<=");
        end

        function f = eq(lhs, rhs)
            f = makeFilterFromRelationalOperator(lhs, rhs, "==", "==");
        end

        function f = ne(lhs, rhs)
            f = makeFilterFromRelationalOperator(lhs, rhs, "~=", "~=");
        end
    end

    methods (Access = private)
        function newFilter = makeFilterFromRelationalOperator(lhs, rhs, lhsOperator, rhsOperator)
            % Validate inputs
            import matlab.io.internal.filter.validators.validateSingleFilterInputForOperator;
            [filter, operator, operand] = validateSingleFilterInputForOperator(lhs, rhs, lhsOperator, rhsOperator);

            % Call into the subclasses to generate a new filter object.
            newFilter = applyRelationalOperator(filter, operator, operand);
        end
    end
end