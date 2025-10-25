function rangeVal = getRangeToWrite(outputName, index)
%getRangeToWrite    Calculate the range to write within a spreadsheet

%   Copyright 2023-2024 The MathWorks, Inc.
    [~,~,ext] = fileparts(outputName);
    % create the workbook and get the sheet to get its used range
    book = matlab.io.spreadsheet.internal.createWorkbook(...
        convertStringsToChars(extractAfter(ext,".")), ...
        convertStringsToChars(outputName),0);
    sheetObj = book.getSheet(index);
    sheetWrittenRange = sheetObj.usedRange;

    % separate out the range to get where to begin writing next
    startRow = extractBefore(sheetWrittenRange,":");
    startNumInRow = strfind(startRow, digitsPattern);
    startRow = startRow(1 : startNumInRow(1) - 1);
    endCol = extractAfter(sheetWrittenRange,":");
    startNumInRow = strfind(endCol, digitsPattern);
    endCol = str2double(endCol(startNumInRow(1) : end)) + 1;
    rangeVal = sprintf("%s%d",startRow,endCol);
end