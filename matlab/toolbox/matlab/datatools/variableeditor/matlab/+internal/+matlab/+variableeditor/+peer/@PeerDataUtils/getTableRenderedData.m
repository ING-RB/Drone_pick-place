% Returns the table rendered data

% Copyright 2017-2024 The MathWorks, Inc.

function [renderedData, renderedDims, metaData] = getTableRenderedData(currentData, startRow, endRow, startColumn, endColumn, nestedTableIndices, gColIndices, fullDTFormats)
    arguments
        currentData
        startRow
        endRow
        startColumn
        endColumn
        nestedTableIndices = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(currentData)
        gColIndices = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(currentData,1,endColumn)
        fullDTFormats = strings(1,endColumn);
    end
    import internal.matlab.variableeditor.peer.PeerDataUtils;

    if ~isempty(currentData)
        [renderedData, renderedDims, metaData] = ...
            PeerDataUtils.formatDataBlock(startRow, endRow, startColumn, endColumn, currentData, nestedTableIndices, gColIndices, fullDTFormats);
    else
        renderedDims = size(currentData);
        renderedData = cell(renderedDims);
        metaData = false(renderedDims);
    end
end
