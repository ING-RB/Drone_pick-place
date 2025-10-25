function combinedRange = combinedDataRangeForGoogleSheet(dataRanges, numRanges)
    %COMBINEDDATARANGEFORGOOGLESHEET combine multiple ranges into one range
    %   dataRanges - an array of four element range vectors [startRow
    %   startColumn numRow numColumns]
    %   numRanges - number of individual ranges
    %
    %   Returns a four element combined range.
    
    % Copyright 2024 The MathWorks, Inc.

    firstRow = dataRanges(1, 1);
    lastRow = dataRanges(numRanges, 1);
    rowIncrement = lastRow + dataRanges(numRanges, 3) - 1;
    firstCol = dataRanges(1, 2);
    lastCol = dataRanges(numRanges, 2);
    colIncrement = lastCol + dataRanges(numRanges, 4) - 1;
    combinedRange = [firstRow firstCol rowIncrement colIncrement];
end