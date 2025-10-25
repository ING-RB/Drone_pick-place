classdef OverloadBinaryOperators
%OverloadBinaryOperators   Helper class for overloading "and" and "or"
%   operators and returning a MultipleVariableRowFilter from these operations.
%
%   Also is the place where the "not" operator is overloaded.

%   Copyright 2021 The MathWorks, Inc.

    properties (Constant, Hidden)
        % Note: MissingRowFilter and UnconstrainedRowFilter are explicitly
        % disallowed from here.
        AllowedOperandTypes (1, :) string = ["matlab.io.internal.filter.SingleVariableRowFilter", ...
                                             "matlab.io.internal.filter.MultipleVariableRowFilter", ...
                                             "matlab.io.internal.filter.NegationRowFilter"];
    end

    methods (Hidden)
        function f = and(lhs, rhs)
            arguments
                lhs {validateOperand}
                rhs {validateOperand}
            end

            import matlab.io.internal.filter.operator.BinaryOperator;

            f = multipleVariableRowFilterFromProps(lhs, rhs, BinaryOperator.And);
        end

        function f = or(lhs, rhs)
            arguments
                lhs {validateOperand}
                rhs {validateOperand}
            end

            import matlab.io.internal.filter.operator.BinaryOperator;

            f = multipleVariableRowFilterFromProps(lhs, rhs, BinaryOperator.Or);
        end

        function f = not(filter)
            arguments
                filter (1, 1) matlab.io.internal.AbstractRowFilter {validateOperand}
            end

            import matlab.io.internal.filter.NegationRowFilter;
            import matlab.io.internal.filter.properties.NegationRowFilterProperties;

            props = NegationRowFilterProperties(filter);
            f = NegationRowFilter(props);
        end
    end
end

function validateOperand(operand)
    % Check that the operand is a rowfilter to start with.
    if ~isa(operand, "matlab.io.internal.AbstractRowFilter")
        error(message("MATLAB:io:filter:filter:InvalidBinaryOperatorInputs"));
    end

    % Only certain RowFilter subclasses are allowed to use the binary
    % operator overloads. Show a nice error if this RowFilter is
    % disallowed.
    allowedTypes = matlab.io.internal.filter.util.OverloadBinaryOperators.AllowedOperandTypes;
    isValidType = any(arrayfun(@(cls) isa(operand, cls), allowedTypes));

    if ~isValidType
        error(message("MATLAB:io:filter:filter:InvalidRowFilterForBinaryOperator"));
    end
end

function f = multipleVariableRowFilterFromProps(lhs, rhs, op)

    import matlab.io.internal.filter.MultipleVariableRowFilter;
    import matlab.io.internal.filter.properties.MultipleVariableRowFilterProperties;

    props = MultipleVariableRowFilterProperties(lhs, rhs, op);
    f = MultipleVariableRowFilter(props);
end
