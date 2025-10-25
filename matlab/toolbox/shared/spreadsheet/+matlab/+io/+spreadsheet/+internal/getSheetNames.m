function sheetNames = getSheetNames(filename)
%GETSHEETNAMES   Get the sheet names from a spreadsheet
%   SHEETNAMES = GETSHEETNAMES(FILENAME) is a string array of sheet names
%   for the input spreadsheet

%   Copyright 2019-2024 The MathWorks, Inc.

    import matlab.io.spreadsheet.internal.createWorkbook;
    fmt = matlab.io.spreadsheet.internal.getExtension(filename);
    if matlab.io.internal.common.validators.isGoogleSheet(filename)
        filename = matlab.io.internal.common.validators.extractGoogleSheetIDFromURL(filename);
        sheetType = 2;
        sheet = 1;
    else
        sheetType = 0;
        sheet = [];
    end
    % return the sheet names
    bookObj = createWorkbook(fmt, filename, sheetType, sheet, true);
    sheetNames = bookObj.SheetNames;
end
