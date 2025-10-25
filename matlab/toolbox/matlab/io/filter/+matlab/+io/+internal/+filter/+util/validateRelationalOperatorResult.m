function validateRelationalOperatorResult(tf, variableName, operator, operand, numRows)
%validateRelationalOperatorResult   errors if TF is not a logical column vector.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        tf
        variableName (1, 1) string
        operator     (1, 1) matlab.io.internal.filter.operator.RelationalOperator
        operand
        numRows      (1, 1) double
    end

    import matlab.io.internal.filter.util.makeConstraintString
    function str = getConstraintString()
        str = makeConstraintString(variableName, operator, operand);
    end

    % Result needs to be a logical column vector for table parens indexing to work
    % correctly later.
    isCorrectType = islogical(tf);
    if ~isCorrectType
        % Filtering expression <X> returned data of type <Y> where a logical mask
        % was expected.
        msgid = "MATLAB:io:filter:filter:RelationalOperatorUnexpectedType";
        error(message(msgid, getConstraintString(), class(tf)));
    end

    isCorrectDimensions = iscolumn(tf) || isempty(tf);
    if ~isCorrectDimensions
        % Filtering expression <Y> returned a ND matrix where a logical column
        % vector was expected.
        msgid = "MATLAB:io:filter:filter:RelationalOperatorUnexpectedDimensions";
        dimString = join(string(size(tf)), "x");
        error(message(msgid, getConstraintString(), dimString));
    end

    isCorrectNumel = numel(tf) == numRows;
    if ~isCorrectNumel
        % Filtering expression <Y> returned N values while the table variable has M
        % rows.
        msgid = "MATLAB:io:filter:filter:RelationalOperatorUnexpectedHeight";
        error(message(msgid, getConstraintString(), numRows, numel(tf)));
    end
end