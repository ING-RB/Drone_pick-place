function [filter, operator, operand] = validateSingleFilterInputForOperator(lhs, rhs, lhsOp, rhsOp)
%validateSingleFilterInputForOperator   validates inputs for relational
%   operator overloading on UnconstrainedRowFilter and
%   SingleVariableRowFilter.

%   Copyright 2021-2022 The MathWorks, Inc.

    import matlab.io.internal.filter.util.makeRelationalOperatorEnum;
    import matlab.io.internal.filter.validators.validateSupportedOperand;

    if isa(lhs, "matlab.io.internal.AbstractRowFilter")
        filter = lhs;
        operand = rhs;
        operator = lhsOp;
    elseif isa(rhs, "matlab.io.internal.AbstractRowFilter")
        filter = rhs;
        operand = lhs;
        operator = rhsOp;
    else
        % Should be unreachable during normal operation since operator
        % dispatch should always ensure at least one RowFilter on either
        % LHS or RHS.
        error(message("MATLAB:io:filter:filter:InvalidRelationalOperatorInputs"));
    end

    % Error if the operand is also a RowFilter during relational
    % operator application.
    if isa(operand, "matlab.io.internal.AbstractRowFilter")
        error(message("MATLAB:io:filter:filter:InvalidRelationalOperationOperand"));
    end

    operator = makeRelationalOperatorEnum(operator);
end
