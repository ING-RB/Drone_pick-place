function handleRelationalOperatorError(variableName, varType, operator, operand, ME)
%handleRelationalOperatorError   throws the appropriate exception based on 
%   the exception caught when executing a relational operator (>, >=, <, 
%   <=, ==, ~=).
% 
% If the relational operator is not >, >=, <, <=, ==, or ~=, the ID of the
% thrown exception is MATLAB:io:filter:filter:OperatorNotSupported.
%
% If the operand's and constrained variable's variable type differ, the ID
% of the thrown exception is MATLAB:io:filter:filter:InvalidVariableType.
%
% Otherwise, MATLAB:io:filter:filter:RelationalOperationFailed is the ID
% of the thrown exception.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        variableName(1, 1) string
        varType(1, 1) string
        operator(1, 1) matlab.io.internal.filter.operator.RelationalOperator
        operand
        ME
    end

    import  matlab.io.internal.filter.util.makeConstraintString

    if ME.identifier == "MATLAB:io:filter:filter:OperatorNotSupported"
        throwAsCaller(ME);
    end

    if varType ~= string(class(operand))
        % Use InvalidVariableType as the exception identifier if the
        % datatype of the variable and operand differ.
        msgid = "MATLAB:io:filter:filter:InvalidVariableType";
    else
        msgid = "MATLAB:io:filter:filter:RelationalOperationFailed";
    end

    % Display the same message no matter which identifier is used.
    constraint = makeConstraintString(variableName, operator, operand);
    msgtext = message("MATLAB:io:filter:filter:RelationalOperationFailed", constraint);
    except = MException(msgid, msgtext);

    % Add the original exception as the cause to indicate why the 
    % constraint failed.
    except = addCause(except, ME);
    throwAsCaller(except);
end
