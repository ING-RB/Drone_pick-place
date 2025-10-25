function book = createWorkbook(fileFormat, filename, sheetType, sheet, ...
    sheetNamesOnly, range, writeOp)
%CREATEWORKBOOK Create a Workbook object
%
%   BOOK = CREATEWORKBOOK(FMT) creates a new book from the format
%   specified by FMT.
%
%   BOOK = CREATEWORKBOOK(FMT, FILENAME) creates a book from the file
%   specified by FILENAME.  FMT must match the format of the spreadsheet
%   specified by FILENAME.
%
%   BOOK = CREATEWORKBOOK(..., 0|1|2) an optional third input argument
%   specifies whether to use an interactive application to instantiate the
%   Workbook.
%
%   BOOK = CREATEWORKBOOK(..., sheet) an optional fourth input argument
%   specifies to sheet to read from the Workbook.
%
%   BOOK = CREATEWORKBOOK(..., sheet, [startRange, endRange]) optional
%   sixth input argument specify the sheet and range to read from the Workbook.
%
%   BOOK = CREATEWORKBOOK(..., sheetNames) an optional fifth logical input
%   argument that specifies that only the sheet names need to be returned.
%
%   BOOK = CREATEWORKBOOK(..., writeOp) an optional seventh logical input
%   argument that specifies that the Workbook is being instantiated for a
%   write operation.
%
%   Example interactive workbook:
%   book = matlab.io.spreadsheet.internal.Workbook('xlsx','airlinesmall_subset.xlsx', false, 1); 
%
% See also matlab.io.spreadsheet.internal.Book,
% matlab.io.spreadsheet.internal.Sheet
%

% Usage Guide for clients of matlab.io.spreadsheet.internal.createWorkbook:
% 1) Default "sheetType" is 0 indicating that 3p/LibXL will be used on all
% platforms.
% book = matlab.io.spreadsheet.internal.createWorkbook('xlsx',
% 'mySpreadsheet.xlsx', 0, 1);
% 2) On Windows with MS Excel installed, if 3p/LibXL fails to create the
% workbook, then we fall back to using COM. To use COM, "sheetType" must be
% set to 1.
% book = matlab.io.spreadsheet.internal.createWorkbook('xlsx',
% 'mySpreadsheet.xlsx', 1);
% 3) For Google Sheets, "sheetType" must be set to 2, the "fileFormat" must
% be set to 'gsheet', "filename" must be the spreadsheetId, and "sheet"
% must be set to 1. Any other values could result in a thrown exception.
% book = matlab.io.spreadsheet.internal.createWorkbook('gsheet',
% '<spreadsheetId>', 2, 1);
% 4) 3p/LibXL affords many performance optimizations -- preferably do not
% call matlab.io.spreadsheet.internal.createWorkbook with only the
% filename. The performance optimizations include:
% a) passing in the "sheet" of interest to only load that specific sheet
% book = matlab.io.spreadsheet.internal.createWorkbook('xlsx',
% 'mySpreadsheet.xlsx', 0, 1);
% b) passing in "sheetNamesOnly" as true to only get the names of the
% sheets
% book = matlab.io.spreadsheet.internal.createWorkbook('xlsx',
% 'mySpreadsheet.xlsx', 0, 1, 1);
% c) passing in a "range" within a sheet to only load that range
% book = matlab.io.spreadsheet.internal.createWorkbook('xlsx',
% 'mySpreadsheet.xlsx', 0, 1, 0, [1 20]);

% Copyright 2015-2024 The MathWorks, Inc.

    arguments
        fileFormat (1, :) char {mustBeTextScalar, mustBeNonzeroLengthText}
        filename (1, :) {mustBeText} = [];
        sheetType (1, 1) double = 0; % LibXL = 0, COM = 1, Google Sheet = 2
        sheet (1, :) {mustBeCharOrNumeric} = [];
        sheetNamesOnly (1, 1) logical = false;
        range (1, :) double = [];
        writeOp (1, 1) logical = false;
    end

    narginchk(1, 7);
    nargoutchk(0, 1);
    % convert filename to char, cannot do this in arguments block because
    % of implicit type conversion from double to ASCII equivalent
    filename = char(filename);

    initLibrary();

    isODSorXLSB = contains(fileFormat, {'ods', 'xlsb'}, 'IgnoreCase',true);
    % Use COM on Windows if UseExcel i.e. interop is true or input file format is ods / xlsb
    launchExcelInstance = ispc && (sheetType == 1 || isODSorXLSB);
    if sheetType == 1 && isWebServerCheck
        warning(message("MATLAB:spreadsheet:book:webserviceExcelWarn"));
    end

    if(sheetType == 1 && ~launchExcelInstance)
        oldState = warning('off','backtrace');
        % Warn on Non-Windows platforms if 'UseExcel' is set to true & silently switching to LibXL
        warning(message('MATLAB:spreadsheet:book:noExcel'));
        warning(oldState);
    end

    if sheetType > 0
        % This optimization is only applicable for LibXL
        writeOp = false;
    end

    % determine whether sheet should be set to empty - 
    %    1) if filename was not passed in
    %    2) if sheet was not passed in
    %    3) if sheet was passed in as a char/string
    %    4) if sheet was passed in as a numeric vector
    emptySheet = (nargin == 4 && isempty(sheet));
    emptyFile = isempty(filename);
    numericScalarCheck = ~emptySheet && isnumeric(sheet) && numel(sheet) > 1;
    stringCheck = ~emptySheet && (isstring(sheet) || ischar(sheet));
    comMode = launchExcelInstance == 1;

    % perform sheet name or index validation for Excel spreadsheets
    if ~isempty(sheet) && ~strcmpi(fileFormat, "gsheet")
        if SheetTypeFactory.makeSheetType(sheet) == SheetType.Invalid
            if isnumeric(sheet)
                error(message("MATLAB:spreadsheet:importoptions:BadSheet"));
            else
                error(message("MATLAB:spreadsheet:book:invalidSheetName"));
            end
        end
    end
    if emptyFile || emptySheet || numericScalarCheck || stringCheck || comMode
        range = [];
        if comMode
            sheet = [];
        end
    end 

    if isODSorXLSB
        % this optimization is not possible for Windows
        sheetNamesOnly = [];
        sheet = [];
    end

    if ~launchExcelInstance && sheetType == 1
        sheetType = 0;
    end

    if launchExcelInstance
        sheetType = 1;
    end

    import matlab.io.spreadsheet.internal.SheetTypeFactory;
    import matlab.io.spreadsheet.internal.SheetType;
    % g3286180: For gsheet format need to set sheetType as Google Sheet
    if strcmpi(fileFormat, "gsheet")
        if isempty(sheet)
            sheet = 1;
        elseif ~isnumeric(sheet) && strlength(sheet) > 100
            error(message("MATLAB:spreadsheet:book:invalidGoogleSheetName"));
        elseif isnumeric(sheet) && ~SheetTypeFactory.isValidSheetIndex(sheet)
            error(message("MATLAB:spreadsheet:gsheet:BadSheetIndex"));
        end
        if isempty(filename)
            error(message("MATLAB:spreadsheet:gsheet:FilenameCannotBeEmpty"));
        end
        % Do not retry in case of google sheets
        try
            book = constructWorkbook('gsheet', filename, sheetType, sheet, ...
                sheetNamesOnly, range, false);
            return;
        catch ME
            matlab.io.internal.spreadsheet.mimeTypeForGoogleSheet(filename);
            rethrow(ME);
        end
    end

    try %#ok<TRYNC>
        book = constructWorkbook(fileFormat, filename, sheetType, sheet, ...
            sheetNamesOnly, range, writeOp);
        return;
    end
    try
        if sheetType == 1
            % switch from COM to LibXL
            sheetType = 0;
        end
        book = constructWorkbook(fileFormat, filename, sheetType, sheet, ...
            sheetNamesOnly, range, writeOp);
        return;
    catch ME
        if ~launchExcelInstance
            if strcmp(ME.identifier, 'MATLAB:spreadsheet:book:unsupportedFormat')
                switch fileFormat
                    case {'ods', 'xlsb'}
                        error(message('MATLAB:spreadsheet:book:fileTypeUnsupported', fileFormat));
                    case {'csv'}
                        invalidFormatError(ispc);
                    otherwise
                        rethrow(ME);
                end
            elseif (~emptyFile) && (strcmp(ME.identifier, ...
                    'MATLAB:spreadsheet:book:invalidFormat'))
                % If file format and file extension do not match, let's try XLSX & XLS with LibXL
                sheetType = 0;
                try
                    book = constructWorkbook('XLSX', filename, sheetType, ...
                        sheet, sheetNamesOnly, range, writeOp);
                    return;
                catch
                    try
                        book = constructWorkbook('XLS', filename, sheetType, ...
                            sheet, sheetNamesOnly, range, writeOp);
                        return;
                    catch
                        invalidFormatError(ispc);
                    end
                end
            elseif (emptyFile) && (strcmp(ME.identifier, 'MATLAB:spreadsheet:book:invalidFormat'))
                invalidFormatError(ispc);
            end
        elseif (~emptyFile) && (strcmp(ME.identifier, 'MATLAB:spreadsheet:book:invalidFormat'))
            % If file format and file extension do not match, let's try XLSX & XLS with COM
            sheetType = 1;
            try
                book = constructWorkbook('XLSX', filename, sheetType, sheet, ...
                    sheetNamesOnly, range, false);
                return;
            catch
                try
                    book = constructWorkbook('XLS', filename, sheetType, ...
                        sheet, sheetNamesOnly, range, false);
                    return;
                catch
                    invalidFormatError(ispc);
                end
            end
        end
    end
    rethrow(ME);
end


function initLibrary
    persistent lib;
    if isempty(lib)
        % initialize the library resources
        matlab.io.spreadsheet.internal.initialize();

        % close on clear; function will re-init
        lib = onCleanup(@matlab.io.spreadsheet.internal.uninitialize);
    end
end

function invalidFormatError(ispc)
    if ispc
        error(message('MATLAB:spreadsheet:book:invalidFormat'));
    else
        error(message('MATLAB:spreadsheet:book:invalidFormatUnix'));
    end
end

function book = constructWorkbook(fileFormat, filename, sheetType, ...
    sheet, sheetNamesOnly, range, writeOp)
    arguments
        fileFormat (1, :) char
        filename (1, :) char
        sheetType (1, 1) double
        sheet (1, :)
        sheetNamesOnly (1, :)
        range (1, :) double
        writeOp (1, 1) logical
    end
    if sheetNamesOnly
        % only sheet names are needed from Book constructor
        % pass in isnumeric(sheet) as true
        book = matlab.io.spreadsheet.internal.Workbook(fileFormat, ...
            filename, sheetType, 0, true, true);
    elseif isempty(sheet)
        % this case will almost never be hit since we default
        % to sheet 1
        book = matlab.io.spreadsheet.internal.Workbook(fileFormat, ...
            filename, sheetType);
    elseif ~isempty(range)
        % passing in sheet and range to Book constructor
        book = matlab.io.spreadsheet.internal.Workbook(fileFormat, ...
            filename, sheetType, sheet, isnumeric(sheet), sheetNamesOnly, ...
            range(1), range(2), writeOp);
    else
        if writeOp
            book = matlab.io.spreadsheet.internal.Workbook(fileFormat, ...
                filename, sheetType, sheet, isnumeric(sheet), sheetNamesOnly, ...
                [], [], writeOp);
        else
            book = matlab.io.spreadsheet.internal.Workbook(fileFormat, ...
                filename, sheetType, sheet, isnumeric(sheet));
        end
        try
            % for chart sheets, SheetNames is not a property on the workbook
            if any(ismissing(book.SheetNames))
                % this could happen with hidden sheets in the workbook that
                % could cause only the hidden sheet to be loaded and all other
                % sheets are missing
                book = matlab.io.spreadsheet.internal.Workbook(...
                    fileFormat, filename, sheetType);
            end
        catch ME
            throw(ME);
        end
    end
end

function webAppStatus = isWebServerCheck()
    persistent WebSessionUseExcel
    if isempty(WebSessionUseExcel) && builtin('_is_web_app_server')
        WebSessionUseExcel = true;
        webAppStatus = WebSessionUseExcel;
    else
        webAppStatus = false;
    end
end


function tf = mustBeCharOrNumeric(sheet)
    tf = isnumeric(sheet) || ischar(sheet);
    if ~tf
        error(message("MATLAB:spreadsheet:importoptions:BadSheet"));
    end
end

function tf = mustBeText(filename)
    tf = isstring(filename) || ischar(filename) || iscellstr(filename) || isempty(filename);
    if ~tf
        error(message("MATLAB:spreadsheet:book:filenameArg"));
    end
end