classdef AcceptsSheetNameOrNumber < matlab.io.internal.FunctionInterface
    %
    
    %   Copyright 2018-2024 The MathWorks, Inc.

    properties (Parameter)
        %SHEET the sheet from which to read
        %   Sheet can be a character vector containing the name of a sheet, or a
        %   positive scalar integer value, or an empty character array.
        %
        %   If specified as a name, the used sheet will match the name, regardless
        %   of sheet order. The sheet must appear in any file being read.
        %
        %   If specified as an integer, then the sheet in that position will be
        %   read, regardless of the sheet name.
        %
        %   If empty, no sheet is specified and the importing function will read
        %   from the appropriate sheet(s).
        %
        %   See also matlab.io.spreadsheet.SpreadsheetImportOptions
        Sheet = '';
    end

    methods
        function func = set.Sheet(func,rhs)
            [sh,func] = func.setSheet(rhs);
            func.Sheet = convertStringsToChars(sh);
        end

        function val = get.Sheet(func)
            containsOpts = any(strcmp(fieldnames(func),"Options"));
            try
                if containsOpts && any(strcmp(fieldnames(func.Options),"Sheet")) ...
                        && strcmp(func.Sheet,'')
                    % if the Options object is well-formed and Sheet has
                    % been initialized properly
                    val = func.Options.Sheet;
                else
                    % if the Sheet was supplied via NV pairs
                    val = func.Sheet;
                end
            catch
                % If the Options object is not well-formed
                val = func.Sheet;
            end
        end
    end
    methods (Hidden)
        function [S, func] = executeImplCatch(func)
            import matlab.io.internal.common.validators.isGoogleSheet;
            import matlab.io.internal.common.validators.extractGoogleSheetIDFromURL;
            ext = extractAfter(func.Extension,'.');
            if ~(strlength(ext)>0)
                ext = matlab.io.spreadsheet.internal.getExtension(func.Filename);
            end

            if isGoogleSheet(func.Filename)
                if isfield(func, "Options") && ...
                        (func.Options.MergedCellColumnRule ~= "placeleft" || ...
                        func.Options.MergedCellRowRule ~= "placetop")
                    error(message("MATLAB:spreadsheet:sheet:FeatureOffInUseExcelMode"));
                end
                % Getting the spreadsheetId from the Google Sheets URL
                filename = extractGoogleSheetIDFromURL(func.Filename);
                sheetType = 2;
                if isempty(func.Sheet)
                    func.Sheet = 1;
                end
            else
                filename = func.LocalFileName;
                sheetType = func.UseExcel;
            end
            book = matlab.io.spreadsheet.internal.createWorkbook(ext, ...
                filename, sheetType, func.Sheet);
            
            % .ods and .xlsb files are interactive. Therefore, they require
            % the use of an Excel COM server to be read properly.
            if(book.Interactive)
                func.UseExcel = true;
            end
            
            % If no "Sheet" value is supplied or an empty string/char is supplied,
            % then always default to reading the first sheet.
            if isempty(func.Sheet) || book.isSheetLoaded()
                sheet = book.getSheet(1);
            else
                try
                    sheet = book.getSheet(func.Sheet);
                catch ME
                    if ME.identifier == "MATLAB:spreadsheet:book:openSheetIndex"
                        error(message("MATLAB:spreadsheet:importoptions:BadSheet"));
                    else
                        throwAsCaller(ME);
                    end
                end
            end
            
            S = struct("Book",book, "Sheet", sheet);
        end
    end

    methods (Access='protected', Abstract)
        [val,func] = setSheet(func,val);
    end
end
