% Entry point fn called directly by InteractiveTablesPackager for packaging
% table data

% Copyright 2017-2024 The MathWorks, Inc.

function [renderedData, renderedDims, formattedData] = getTableRenderedDataForPeer(rawData, startRow, endRow, startColumn, endColumn, nestedTableIndices, gColIndices, fullDTFormats)
    arguments
        rawData
        startRow = 1
        endRow = size(rawData, 1)
        startColumn = 1
        endColumn = size(rawData, 2)
        nestedTableIndices = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(rawData)
        gColIndices = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(rawData,1,endColumn)
        fullDTFormats string = strings(1,endColumn);
    end

    import internal.matlab.variableeditor.peer.PeerDataUtils;

    [data, ~, metaData] = PeerDataUtils.getTableRenderedData(rawData, startRow, endRow, startColumn, endColumn, nestedTableIndices, gColIndices, fullDTFormats);
    [renderedData, renderedDims] = PeerDataUtils.packagePeerData(data, metaData, startRow, endRow, startColumn, endColumn);
    formattedData = data;
end
