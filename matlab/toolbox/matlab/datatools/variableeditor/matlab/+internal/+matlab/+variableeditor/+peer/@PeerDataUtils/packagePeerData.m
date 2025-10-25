% Packages the peer data

% Copyright 2017-2024 The MathWorks, Inc.

function [renderedData, renderedDims] = packagePeerData(data, metaData, startRow, endRow, startColumn, endColumn)
    arguments
        data
        metaData
        startRow
        endRow
        startColumn
        endColumn
    end

    numRows = endRow - startRow + 1;
    totalColumnsRequested = endColumn - startColumn + 1;
    renderedData = strings(numRows,totalColumnsRequested);
    for row=1:endRow-startRow+1
        for col=1:(endColumn-startColumn+1)
            cellValue = data{row,col};
            if metaData(row,col)
                cellValue = jsonencode(struct('value', cellValue, 'isMetaData', '1'));
            end
            renderedData(row,col) = cellValue;
        end
    end
    renderedDims = size(renderedData);
end
