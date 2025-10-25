% This method is used to construct JSON array with the given array like data.
% TODO: This JSON can be simplified to just send the value across as
% editValue/row/col info might not be necessary.

% Copyright 2015-2023 The MathWorks, Inc.

function [renderedData, renderedDims] = getJSONForArrayData(data, startRow, endRow, startColumn, endColumn)
    renderedData = cell(size(data));

    rowStrs = strtrim(cellstr(num2str((startRow-1:endRow-1)'))');
    colStrs = strtrim(cellstr(num2str((startColumn-1:endColumn-1)'))');

    for row=1:min(size(renderedData,1),size(data,1))
        for col=1:min(size(renderedData,2),size(data,2))
            jsonData = internal.matlab.datatoolsservices.FormatDataUtils.convertToJSON(struct('value',data{row,col},...
                'editValue',data{row,col},'row',rowStrs{row},'col',colStrs{col}));

            renderedData{row,col} = jsonData;
        end
    end
    renderedDims = size(renderedData);
end
