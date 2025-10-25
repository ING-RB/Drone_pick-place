function op = makeRelationalOperatorEnum(str)
%makeRelationalOperatorEnum   returns the RelationalOperator enum value
%   corresponding to the input string.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        str(1, 1) string
    end

    import matlab.io.internal.filter.operator.RelationalOperator;

    if ismissing(str)
        op = RelationalOperator.NoOp;
        return;
    end

    switch str
        case "<"
            op = RelationalOperator.LessThan;
        case "<="
            op = RelationalOperator.LessThanOrEqualTo;
        case ">"
            op = RelationalOperator.GreaterThan;
        case ">="
            op = RelationalOperator.GreaterThanOrEqualTo;
        case "=="
            op = RelationalOperator.EqualTo;
        case "~="
            op = RelationalOperator.NotEqualTo;
        otherwise
            error(message('MATLAB:io:filter:filter:OperatorNotSupported'));
    end
end
