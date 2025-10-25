function errorRows = getErrorRows(obj)
%

%   Copyright 2024 The MathWorks, Inc.

% Traverse through each "row" of data and mark whether it contained a
% value that errored on conversion.
    errorRows = false(obj.numRows, 1);

    % Index to keep track of the first element for each row. This indexes
    % into obj.errorredConversions.
    rowStartIdx = 1;

    for rowNum = 1:obj.numRows
        % Calculate rowEndIdx given obj.counts value for this row
        rowEndIdx = rowStartIdx + obj.counts(rowNum) - 1;

        % Get current row of error data and set the row to "true" if any
        % conversion errored.
        rowErrors = obj.erroredConversions(rowStartIdx:rowEndIdx);
        errorRows(rowNum) = any(rowErrors);

    end
end
