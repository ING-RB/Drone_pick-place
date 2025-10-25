function str = makeConstraintString(varname, operator, operand)
%makeConstraintString   returns the string to use as the display for a
%   single-variable constraint.

% Copyright 2022 The MathWorks, Inc.
    arguments
        varname(1, 1) string
        operator(1, 1) matlab.io.internal.filter.operator.RelationalOperator
        operand
    end

    if isstring(operand) && isscalar(operand)
        % Add  double quotes around scalar string operands.
        operand = '"' + operand + '"';
    elseif ischar(operand) && isrow(operand) && ~isempty(operand)
        % Add single quotes around nonempty char row vectors operands.
        operand = strcat('''', operand, '''');
    end

    % Catch the possibility that a string cannot be constructed
    % from this datatype.
    try
        str = string(operand);
        if ismissing(str)
            % Replace with "missing".
            str = "missing";
        elseif isempty(str) || isequal(str, "") || ~isscalar(str)
            % Format empties and vectors as [2x3 MyObject]
            str = formatClassDisp(operand);
        end
    catch
        % Format as [2x3 MyObject]
        str = formatClassDisp(operand);
    end

    str = varname + " " + string(operator) + " " + str;
end

function str = formatClassDisp(operand)
    % Format as [2x3 MyObject]
    dims = size(operand);
    str = "[" + strjoin(string(dims), "x") + " " + class(operand) + "]";
end

