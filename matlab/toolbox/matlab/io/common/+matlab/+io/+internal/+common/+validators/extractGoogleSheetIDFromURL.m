function googlesheetID = extractGoogleSheetIDFromURL(url)
%

%   Copyright 2024 The MathWorks, Inc.

if (~matlab.io.internal.common.validators.isGoogleSheet(url))
    return;
end

googleSheetsStartingURLPart = "https://docs.google.com/spreadsheets/d/";

if ~startsWith(url, googleSheetsStartingURLPart)
    error(message("MATLAB:spreadsheet:gsheet:SpreadsheetIdNotSupplied", url));
end

trailingURLParts = split(replace(url, googleSheetsStartingURLPart, ""), "/");

if isempty(trailingURLParts) || isempty(trailingURLParts{1})
    error(message("MATLAB:spreadsheet:gsheet:SpreadsheetIdNotSupplied", url));
end

% First part shall be spreadsheetID, ignore the rest
googlesheetID = trailingURLParts{1};
end
