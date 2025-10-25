classdef PeerDataUtils < handle
    % Peer Data utility functions

    % Copyright 2017-2024 The MathWorks, Inc.

    properties(Constant)
        MAX_DISPLAY_ELEMENTS = 11;
        MAX_DISPLAY_DIMENSIONS = 2;
        CHAR_WIDTH = 7;		% Width of each character in the string
        HEADER_BUFFER = 10;	% The amount of room(leading and trailing space) the header should have after resizing to fit the header name
    end

    methods(Static)
        [renderedData, renderedDims] = getArrayRenderedData(data);
        [stringData] = getStringData(fullData, dataSubset, rows, cols, scalingFactor, displayFormat);
        summarString = makeNDSummaryString(size, numRows, class);
        [vals, metaData] = parseCharColumn(currentData);
        vals = parseCellColumn(strColumnData);
        vals = formatDatetime(strColumnData);
        [renderedData, renderedDims, metaData] = formatDataBlock(startRow, endRow, startColumn, endColumn, currentData, nestedTableIndices, gColIndices, fullDTFormats);
        editorValue = getNDEditorValue(name, varName, row, sz);
        [renderedData, renderedDims, formattedData] = getTableRenderedDataForPeer(rawData, startRow, endRow, startColumn, endColumn, nestedTableIndices, gColIndices, fullDTFormats);
        [renderedData, renderedDims, metaData] = getTableRenderedData(currentData, startRow, endRow, startColumn, endColumn, nestedTableIndices, gColIndices, fullDTFormats);
        [renderedData, renderedDims] = packagePeerData(data, metaData, startRow, endRow, startColumn, endColumn);
        [renderedData, renderedDims, scalingFactorString] = getFormattedNumericData(fullData, dataSubset, scalingFactorString, displayFormat, showMultipliedExponent);
        scalingFactorString = getScalingFactor(fullData);
        scalingFactor = getScalingFactorFromDataString(dataString);
        exponent = getScalingFactorExponent(scalingFactorString);
        [dispData, scalingFactor, convertSubsetToComplex] = getDisplayDataAsString(fullData, dataSubset, isScalarOutput, useFullData, displayFormat);
        precision = getDatetimePrecisionFromFormat(formatString);
        t_string = getTimeStringFromDatetime(dt);
        fmt = getCorrectFormatForDatetimeFiltering(userfmt);
        fmt = getCorrectFormatForDurationFiltering(userfmt);
    end
end
