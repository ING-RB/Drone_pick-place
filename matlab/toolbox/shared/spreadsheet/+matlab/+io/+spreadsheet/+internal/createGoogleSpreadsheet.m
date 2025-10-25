function [url, spreadsheetID] = createGoogleSpreadsheet(spreadsheetName, args)
%CREATEGOOGLESPREADSHEET Create a new Google Spreadsheet.
%
%  Provide an optional "spreadsheetName" for the title of the spreadsheet
%  to be created. If no "spreadsheetName" is provided, Google uses
%  "Untitled spreadsheet" as the default spreadsheet name.
%  Provide an optional "SheetTitles" NV argument specifying the titles of
%  the sheets to be populated in the newly constructed Google Spreadsheet.
%  If no "SheetTitles" are provided, by default "Sheet1" is present in the
%  Google Spreadsheet.
%  The URL of the spreadsheet created is returned as the first output argument.
%  An optional second output argument returns the spreadsheetID.
%

% Copyright 2024 The MathWorks, Inc.

arguments (Input)
    spreadsheetName (1, 1) string {mustNotExceedMaxChars} = missing
    args.SheetTitles (1, :) string {mustNotExceedMaxSheetsAndMustBeUniqueTitles, mustNotExceedMaxSheetChars} = missing
end

arguments (Output)
    url (1, 1) string {mustBeTextScalar,mustBeNonzeroLengthText}
    spreadsheetID (1, 1) string {mustBeTextScalar,mustBeNonzeroLengthText}
end

if nargin == 0
    % nargin only checks positional arguments therefore spreadsheetName is
    % guaranteed to be empty in this case
    if ismissing(args.SheetTitles)
        response =  matlab.io.internal.spreadsheet.createGoogleWorkbookBuiltin;
    else
        response = matlab.io.internal.spreadsheet.createGoogleWorkbookBuiltin(...
            "Untitled spreadsheet", args.SheetTitles);
    end
else
    mustBeNonzeroLengthText(spreadsheetName);
    if ismissing(args.SheetTitles)
        response = matlab.io.internal.spreadsheet.createGoogleWorkbookBuiltin(...
            spreadsheetName);
    else
        response = matlab.io.internal.spreadsheet.createGoogleWorkbookBuiltin(...
            spreadsheetName, args.SheetTitles);
    end
end

result = jsondecode(response);

url = result.spreadsheetUrl;

if nargout == 2
    spreadsheetID = result.spreadsheetId;
end

end

function mustNotExceedMaxChars(spreadsheetName)
    if strlength(spreadsheetName) > 10000
        throwAsCaller(MException(message("MATLAB:spreadsheet:gsheet:SpreadsheetNameTooLong")));
    end
end

function mustNotExceedMaxSheetsAndMustBeUniqueTitles(sheetTitles)
    % Only 10000000 cells are allowed in a Google Spreadsheet and since by
    % default each sheet contains 26000 cells, the maximum number of
    % allowed sheets is 384.
    if numel(sheetTitles) > 384
        throwAsCaller(MException(message("MATLAB:spreadsheet:gsheet:TooManySheets")));
    end
    % Google Spreadsheet cannot contain multiple sheets with the same title
    if numel(unique(sheetTitles)) ~= numel(sheetTitles)
        throwAsCaller(MException(message("MATLAB:spreadsheet:gsheet:SheetTitlesMustBeUnique")));
    end
end

function mustNotExceedMaxSheetChars(sheetTitles)
    lengths = strlength(sheetTitles);
    % Sheet names cannot exceed 100 characters
    exceedsLimit = lengths > 100;
    if any(exceedsLimit)
        throwAsCaller(MException(message("MATLAB:spreadsheet:book:invalidGoogleSheetName")));
    end
end