function tf = isGoogleSheet(location)
%

%   Copyright 2024 The MathWorks, Inc.

if isa(location, "matlab.io.datastore.FileSet")
    location = location.FileInfo.Filename;
elseif isa(location, "matlab.io.datastore.DsFileSet")
    location = resolve(location);
    location = location.FileName;
end

tf = false;
googleSheetStr = "https://docs.google.com/spreadsheets/";
googleSheetStrPublished = "https://docs.google.com/spreadsheets/d/e/";

if ~isempty(location) && matlab.internal.feature("GOOGLESHEETS")
    startsWithGoogleSpreadsheetURL = startsWith(location, googleSheetStr) | startsWith(location, googleSheetStrPublished);
    containsSpreadsheetId = strlength(location) > strlength(googleSheetStr);
    containsSpreadsheetIdPublished = strlength(location) > strlength(googleSheetStrPublished);

    if any(startsWithGoogleSpreadsheetURL) && ~any(containsSpreadsheetId)
        error(message("MATLAB:spreadsheet:gsheet:SpreadsheetIdNotSupplied", location));
    end

    if any(startsWith(location, googleSheetStrPublished)) && any(containsSpreadsheetIdPublished)
        error(message("MATLAB:spreadsheet:gsheet:PublishToTheWebGsheetNotSupported", location));
    end

    tf = startsWith(location, googleSheetStr) & containsSpreadsheetId;
end
end
