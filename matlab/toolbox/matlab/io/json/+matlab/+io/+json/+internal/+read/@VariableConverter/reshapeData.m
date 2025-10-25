function reshapedData = reshapeData(obj, fillValue)
%

%   Copyright 2024 The MathWorks, Inc.

% Place char cell values in a cell
    if ischar(fillValue)
        fillValue = {fillValue};
    end

    specifiedType = obj.varOpts.Type;
    if specifiedType == "auto"
        detectedType = str2func(class(obj.convertedData));
        fillValue = detectedType(fillValue);
    end

    reshapedData = repmat(fillValue, obj.numRows, obj.numColumns);

    % Index to keep track of the first element for each row. This indexes
    % into obj.convertedData.
    rowStartIdx = 1;

    for rowNum = 1:obj.numRows
        % Calculate rowEndIdx given obj.counts value for this row
        rowEndIdx = rowStartIdx + obj.counts(rowNum) - 1;

        % Get current row of data and insert into reshapedData matrix
        rowData = obj.convertedData(rowStartIdx:rowEndIdx);
        reshapedData(rowNum, 1:obj.counts(rowNum)) = rowData;

        % Update rowStartIdx
        rowStartIdx = rowEndIdx + 1;
    end
end
