classdef UsesWorksheet < handle
    %
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    properties
        WorkbookObj
        SheetObj
        % Property to indicate if object is referring to a
        % COM (Component Object Model) based object on Windows.
        IsComObject = false;
    end
    
    methods
        function openBook(obj, filename, sheet, fmt, UseExcel, range, origFilename)
            import matlab.io.spreadsheet.internal.*;
            if nargin < 6
                range = [];
            end

            try
                % By default load only the first sheet
                if isempty(sheet)
                    sheet = 1;
                end
                % Use LibXL by default
                if isempty(UseExcel)
                    UseExcel = false;
                end

                % get start and end rows from range
                if ~isempty(range) && ~(UseExcel && ispc)
                    range = getStartAndEndRows(range);
                end
                if matlab.io.internal.common.validators.isGoogleSheet(filename)
                    % Getting the spreadsheetId from the Google Sheets URL
                    filename = matlab.io.internal.common.validators.extractGoogleSheetIDFromURL(filename);
                    sheetType = 2;
                else
                    sheetType = UseExcel;
                end
                obj.WorkbookObj = createWorkbook(fmt, filename, sheetType, ...
                    sheet, false, range);
            catch ME
                if any(ME.identifier == ["MATLAB:spreadsheet:book:chartsheetError", ...
                                         "MATLAB:spreadsheet:book:invalidFormatUnix", ...
                                         "MATLAB:spreadsheet:importoptions:BadSheet", ...
                                         "MATLAB:spreadsheet:book:openSheetName"]) || ...
                                         ~ispc || ...
                                         startsWith(ME.identifier, "MATLAB:spreadsheet:gsheet")
                    % All Google Sheet error messages should be rethrown, don't attempt to retry
                    rethrow(ME);
                else
                    if matlab.io.internal.vfs.validators.isIRI(origFilename)
                        % G3355545: Don't retry for HTTP/S URLs to avoid
                        % Excel keeping control over the file and thus
                        % preventing the deletion of temporary artifacts.
                        scheme = matlab.io.internal.vfs.validators.GetScheme(origFilename);
                        if any(lower(scheme) == ["http", "https"])
                            rethrow(ME);
                        end
                    end
                    if ~isempty(sheet)
                        sheet = '';
                    end
                    obj.WorkbookObj = createWorkbook(fmt, filename, true, sheet, false);
                end
            end
            % .ods and .xlsb files are interactive. Therefore, they require the use of an Excel COM server to be read properly.
            obj.IsComObject = obj.WorkbookObj.Interactive;
        end

        function openSheet(obj,sheetNameOrNum)
            % If no "Sheet" value was supplied, then default to reading the
            % first sheet.
            if ~isempty(sheetNameOrNum) && (isstring(sheetNameOrNum) || ischar(sheetNameOrNum))
                % If sheet name was supplied, use name to get sheet
                % Loading the first sheet can cause issues if the first sheet is a chart sheet
                obj.SheetObj = obj.WorkbookObj.getSheet(sheetNameOrNum);
            elseif isempty(sheetNameOrNum) || obj.WorkbookObj.isSheetLoaded()
                % If a valid "Sheet" value was supplied, then we should only
                % have loaded that specific sheet (i.e. isSheetLoaded() == true).
                % Therefore, we can just read the first sheet.
                obj.SheetObj = obj.WorkbookObj.getSheet(1);
            else
                try
                    obj.SheetObj = obj.WorkbookObj.getSheet(sheetNameOrNum);
                catch ME
                    if obj.WorkbookObj.Format == "GSHEET"
                        % GoogleSheet specific error handling
                        if isnumeric(sheetNameOrNum)
                            error(message("MATLAB:spreadsheet:gsheet:BadSheetIndex"));
                        else
                            error(message("MATLAB:spreadsheet:book:invalidGoogleSheetName"));
                        end
                    else
                        % LibXL/COM sheets error handling
                        if ME.identifier == "MATLAB:spreadsheet:book:openSheetIndex"
                            error(message("MATLAB:spreadsheet:importoptions:BadSheet"));
                        else
                            throwAsCaller(ME);
                        end
                    end
                end
            end
        end
        
        function clear(obj)
            obj.SheetObj = [];
            obj.WorkbookObj = [];
            obj.IsComObject = false;
        end
    end
end

function libxl_range = getStartAndEndRows(range)
    libxl_range = [];
    if contains(range, ":")
        % convert two-corner and row-only ranges to [startRange, endRange]
        startRange = extractBefore(range, ":");
        endRange = extractAfter(range, ":");
        startNumInRow = regexp(startRange, "[0-9]");
        startRow = str2double(startRange(min(startNumInRow):end));
        endNumInRow = regexp(endRange, "[0-9]");
        endRow = str2double(endRange(min(endNumInRow):end));
        if startRow > endRow
            % allow flipped postions for rows
            temp = startRow;
            startRow = endRow;
            endRow = temp;
        end

        if ~isnan(startRow) && ~isnan(endRow)
            % only return the correct row range if start and end rows are
            % numeric, otherwise return empty
            libxl_range = [startRow, endRow];
        end
    end
end
