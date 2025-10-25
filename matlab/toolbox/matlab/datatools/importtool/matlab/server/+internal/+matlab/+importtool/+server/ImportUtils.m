%   This class is unsupported and might change or be removed without
%   notice in a future version.

% Copyright 2018-2024 The MathWorks, Inc.

classdef ImportUtils
    properties (Constant)
        DEFAULT_TEXT_TYPE = 'string';
        EXCEL_SPREADSHEET_TYPES = ["xlsb", "ods"];

        % Pattern to match letters followed by numbers
        ALPHA_NUMERIC_PATTERN = lettersPattern + digitsPattern;

        % Pattern to match letters followed by numbers, then a colon
        ALPHA_NUMERIC_COLON_PATTERN = lettersPattern + digitsPattern + ":";
    end

    methods (Static)
        function excelRange = toExcelRange(startRow, endRow, startCol, endCol)
            % Converts rows/columns to an excel range.  For example,
            % Rows 1:10, Columns 4:50 converts to:  'D1:AX10'
            import internal.matlab.importtool.server.ImportUtils;

            excelRange = ImportUtils.intToColumnString(startCol);
            excelRange = excelRange + string(startRow) + ":";
            excelRange = excelRange + ImportUtils.intToColumnString(endCol);
            excelRange = excelRange + string(endRow);
            excelRange = char(excelRange);
        end

        function excelRange = getExcelRangeArray(rows, cols)
            % Converts a row and column array to excel range.  For example:
            % rows = [1,10], cols = [2,3] converts to:  "B1:C10"
            startRows = rows(:, 1);
            endRows = rows(:, 2);

            startCols = cols(:, 1);
            endCols = cols(:, 2);

            excelRange = strings(0);
            for r = 1:length(startRows)
                for c = 1:length(startCols)
                    excelRange(end+1) = internal.matlab.importtool.server.ImportUtils.toExcelRange(...
                        startRows(r), endRows(r), startCols(c), endCols(c));
                end
            end

            excelRange = strjoin(excelRange, ",");
        end

        function [rows, cols] = excelRangeToMatlab(range, startEndOnly)
            arguments
                % Excel range, like "A2:Q14"
                range

                % Whether to return the start/end values only.  For example, for
                % rows 1 to 20, if this is true the value returned would be
                % [1,20], while if it is false, it will be [1:20]
                startEndOnly (1,1) logical = false;
            end

            persistent fullRangeMap;
            persistent startEndOnlyRangeMap;
            if isempty(fullRangeMap) || isempty(range)
                fullRangeMap = dictionary(string.empty, struct.empty);
                startEndOnlyRangeMap = dictionary(string.empty, struct.empty);
            end

            if startEndOnly && isKey(startEndOnlyRangeMap, range)
                s = startEndOnlyRangeMap(range);
                rows = s.rows;
                cols = s.cols;
                return;
            elseif ~startEndOnly && isKey(fullRangeMap, range)
                s = fullRangeMap(range);
                rows = s.rows;
                cols = s.cols;
                return;
            end

            % Converts an Excel range to Matlab rows and columns.  For example,
            % A2:Q14 converts to:  rows = [2:14], cols = [1:17].  Multiple
            % ranges can be in comma-separated text.  For example:
            % "B3:B5, D3:D5" returns rows = [3:5], cols = [2,4]
            %
            % Note - this differs from getRowsColsFromExcel in that method
            % returns only start/end values, for example it would return [3,5]
            % for the rows in the previous example.  It also always returns
            % start/end values.  For example, this method will return 1 for a
            % single column, while getRowsColsFromExcel will return [1,1].
            import internal.matlab.importtool.server.ImportUtils;

            function rowCols = getResolvedValues(rowCols, rc1, rc2)
                % Internal function used to resovle row or column values
                if isempty(rowCols)
                    if startEndOnly
                        if rc1 > rc2
                            % This is invalid
                            rowCols = [];
                        else
                            rowCols = [rc1, rc2];
                        end
                    else
                        rowCols = rc1:rc2;
                    end
                else
                    if startEndOnly
                        % Keep just the min/max values of the combined range
                        combined = [rowCols, rc1, rc2];
                        rowCols = [min(combined), max(combined)];
                    else
                        % This is costly, so only do it when necessary
                        rowCols = unique([rowCols, rc1:rc2]);
                    end
                end
            end

            ranges = split(range, ",");
            rows = [];
            cols = [];
            dp = digitsPattern;
            lp = lettersPattern;
            for idx = 1:length(ranges)

                currRange = ImportUtils.makeValidSingleCellRange(...
                    convertStringsToChars(ranges{idx}));
                colon = strfind(currRange,':');
                if ~isempty(colon) && ~isequal(colon, 1)
                    % Valid ranges should contain a colon, and it can't be the first character
                    block1 = string(currRange(1:colon-1));
                    block2 = string(currRange(colon+1:end));

                    r1 = double(extract(block1, dp));
                    r2 = double(extract(block2, dp));
                    rows = getResolvedValues(rows, r1, r2);

                    c1 = ImportUtils.base27dec(char(extract(block1, lp)));
                    c2 = ImportUtils.base27dec(char(extract(block2, lp)));
                    cols = getResolvedValues(cols, c1, c2);
                end
            end

            if isempty(rows) && isempty(cols)
                % Maintain existing behavior where invalid ranges return 0 for rows/cols
                rows = 0;
                cols = 0;
            end
            
            if startEndOnly
                startEndOnlyRangeMap(range) = struct("rows", rows, "cols", cols);
            else
                fullRangeMap(range) = struct("rows", rows, "cols", cols);
            end
        end

        function [rows, cols] = getRowsColsFromExcel(excelRange)
            % Converts an excel range to row/column arrays with start/end
            % row/column blocks.  For example:
            % "A2:C10, A15:C20, F2:G10, F15:G20" returns:
            % rows = [2 10; 15 20]
            % cols = [1 3; 6 7]
            %
            % Note - this differs from excelRangeToMatlab in that method returns
            % all values, for example it would return [1,2,3,6,7] for the colums
            % in the previous example.  It also returns only unique values.  For
            % example, this method will return [1,1] for a single column, while
            % excelRangeToMatlab will return just 1.

            [r, c] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(excelRange);

            rows = getArray(r);
            cols = getArray(c);

            function arr = getArray(inputArray)
                inputDiffs = diff(inputArray);
                if all(inputDiffs == 1)
                    % There's just one block of rows or columns
                    arr = [inputArray(1) inputArray(end)];
                else
                    % Create an array with start/end rows for each of the blocks
                    % of rows or columns
                    rangeBreaks = find(inputDiffs ~= 1);
                    arr = [inputArray(1) inputArray(rangeBreaks(1))];
                    for idx = 1:length(rangeBreaks)
                        arr(idx + 1, 1) = inputArray(rangeBreaks(idx) + 1);
                        if idx < length(rangeBreaks)
                            arr(idx + 1, 2) = inputArray(rangeBreaks(idx + 1));
                        else
                            arr(idx + 1, 2) = inputArray(end);
                        end
                    end
                end
            end
        end

        function validExcelRange = makeValidSingleCellRange(excelRange)
            import internal.matlab.importtool.server.ImportUtils;

            % if its a single column .i.e. 'A1' then convert to 'A1:A1'
            validExcelRange = excelRange;

            if ~contains(excelRange, ":") && matches(excelRange, ImportUtils.ALPHA_NUMERIC_PATTERN)
                % If excelRange is a single cell, double it up.  For example,
                % 'A1' becomes 'A1:A1'
                validExcelRange = [excelRange ':' excelRange];
            elseif matches(excelRange, ImportUtils.ALPHA_NUMERIC_COLON_PATTERN)
                % If excelRange is 'A1:' then make it 'A1:A1'
                validExcelRange = [excelRange excelRange(1:end-1)];
            end
        end

        function val = intToColumnString(x)
            import internal.matlab.importtool.server.ImportUtils;

            if isempty(x)
                val = '';
                return
            end

            % Returns the column string value for the given numeric column
            % number.  For example, 1 returns 'A', 22 returns 'V', 50 returns
            % 'AX'.

            val = '';
            if (x <= 26)
                val = char('A' + x - 1);
            else
                remainder = mod(x, 26);
                m = floor(x/26);

                if (remainder == 0)
                    val = [val ImportUtils.intToColumnString(m - 1)];
                    val = [val 'Z'];
                else
                    val = [val ImportUtils.intToColumnString(m)];
                    val = [val char(remainder + 'A' - 1)];
                end
            end
        end

        function s = getImportToolMsgFromTag(msg, varargin)
            % Returns the message catalog string from a tag, that is in the
            % codetools/importtool.xml file.
            fullmsg = "MATLAB:codetools:importtool:" + msg;
            if nargin == 1
                s = getString(message(fullmsg));
            else
                s = getString(message(fullmsg, varargin{:}));
            end
        end

        function sheetNames = getSheetNames(fileName)
            if nargin < 1 || isempty(fileName)
                error(message('MATLAB:codetools:FilenameMustBeSpecified'));
            end
            if ~ischar(fileName) && ~isStringScalar(fileName)
                error(message('MATLAB:codetools:FilenameMustBeAString'));
            end
            if any(strfind(fileName, "*"))
                error(message('MATLAB:codetools:FilenameMustNotContainAsterisk'));
            end

            swf = internal.matlab.importtool.server.SpreadsheetWorkbookFactory.getInstance;
            workbook = swf.getWorkbookForFile(fileName);

            % Initialize worksheets object.
            worksheets = workbook.SheetNames;
            indexes = true(1, length(worksheets));
            sheetNames = strings(1, length(worksheets));
            for i = 1:length(worksheets)
                if ismissing(worksheets(i))
                    indexes(i) = false;
                else
                    sheet = workbook.getSheet(worksheets{i});
                    if isprop(sheet, 'Type')
                        sheetNames(i) = sheet.Name;
                    end

                    if isempty(sheet.usedRange)
                        indexes(i) = false;
                    end
                end
            end
            sheetNames = sheetNames(indexes);
        end

        % Returns the requested number of lines of sample content from a given
        % text file.
        function s = getTextFileSampleContent(filename, numlines)
            arguments
                filename string {mustBeFile}
                numlines double = 10
            end

            fid = fopen(filename, "r");
            s = strings(0);
            try
                for idx = 1:numlines
                    ln = fgetl(fid);
                    if ~isequal(ln, -1)
                        s(idx) = ln;
                    end
                end
            catch
            end

            s = s';
            if fid > 0
                fclose(fid);
            end

            if all(strlength(s) == 0)
                s = strings(0);
            end
        end

        % returns the index of the specified sheet in the file
        function sheetID = getSheetID(fileName, sheetName)
            sheetNames = internal.matlab.importtool.server.ImportUtils.getSheetNames(fileName);
            sheetID = [];
            for i = 1:length(sheetNames)
                if strcmp(sheetNames(i), sheetName)
                    sheetID = i;
                    break;
                end
            end
        end

        % validates the excel range provided by validating the syntax and
        % the selection range
        function validExcelRange = makeValidExcelRange(excelRange, sheetDimensions)
            import internal.matlab.importtool.server.ImportUtils;

            ranges = strtrim(split(excelRange, ","));
            validExcelRange = strings(0);
            for idx = 1:length(ranges)
                r = strtrim(ranges{idx});
                % check if the regex is valid, if not return null
                validRange = ImportUtils.makeValidSelectionRangeFormat(r);

                % check if the selection range is within the data range, if not
                % set to valid limits
                if ~isempty(validRange)
                    range = ImportUtils.makeValidSelectionRangeDimensions(validRange, sheetDimensions);
                    if ~isempty(range)
                        validExcelRange(end+1) = range; %#ok<*AGROW>
                    end
                end
            end

            if isempty(validExcelRange)
                validExcelRange = [];
            else
                validExcelRange = strjoin(validExcelRange, ", ");
            end
        end

        % validates the excel range provided by validating the syntax,
        % letter casing
        function validExcelRange = makeValidSelectionRangeFormat(excelRange)
            % check that range starts with letters followed by numbers
            % it should be one of formats- 'A1', 'A1:', 'A1:A1'
            if isempty(regexp(excelRange, "^[a-zA-Z]+\d+$", 'match')) && ...
                    isempty(regexp(excelRange, "^[a-zA-Z]+\d+:$", 'match')) && ...
                    isempty(regexp(excelRange, "^[a-zA-Z]+\d+:[a-zA-Z]+\d+$", 'match'))
                validExcelRange = [];
                return;
            end

            % if letters are lower case, then convert to upper case
            validExcelRange = upper(excelRange);
            % if single cell range, then convert to valid format with ':'
            validExcelRange = internal.matlab.importtool.server.ImportUtils.makeValidSingleCellRange(validExcelRange);
        end

        % Function expects excel range in correct format (A1:A2). Will not
        % check for invalid formats
        % checks if the rowlimits/columnlimits are specified in the correct order, if not swaps them
        % checks if the row and column limits are within the data bounds,
        % if not sets them to within the data bounds
        function validExcelRange = makeValidSelectionRangeDimensions(excelRange, sheetDimensions)
            % check if start row is greater than end row, start column is greater
            % than end column
            validExcelRange = [];
            excelRange = internal.matlab.importtool.server.ImportUtils.makeValidRowLimitsOrderInExcelRange(excelRange);
            if isempty(excelRange)
                return;
            end

            excelRange = internal.matlab.importtool.server.ImportUtils.makeValidColumnLimitsOrderInExcelRange(excelRange);
            if isempty(excelRange)
                return;
            end

            % get the matlab selection range
            [dataRangeRows, dataRangeCols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(excelRange, true);

            if isempty(dataRangeRows) || isempty(dataRangeCols)
                return;
            end

            % get valid Row range
            rowStart = internal.matlab.importtool.server.ImportUtils.getValidRowSelectionRange(dataRangeRows(1), sheetDimensions);
            rowEnd = internal.matlab.importtool.server.ImportUtils.getValidRowSelectionRange(dataRangeRows(end), sheetDimensions);

            % get valid Column range
            columnStart = internal.matlab.importtool.server.ImportUtils.getValidColumnSelectionRange(dataRangeCols(1), sheetDimensions);
            columnEnd = internal.matlab.importtool.server.ImportUtils.getValidColumnSelectionRange(dataRangeCols(end), sheetDimensions);

            % convert back to excel range
            validExcelRange = internal.matlab.importtool.server.ImportUtils.toExcelRange(rowStart, rowEnd, columnStart, columnEnd);
        end

        % function takes in excel range in format A1:A2 (will not validate for single cells like A1, A1:)
        % if the startRow in the excel range is greater than the end row,
        % order is swapped
        function excelRange = makeValidRowLimitsOrderInExcelRange(excelRange)
            % split by ':'
            [~, ranges]  = regexp(excelRange, ':', 'match', 'split');

            if isempty(ranges) || ~isequal(length(ranges), 2)
                excelRange = [];
                return;
            end

            % get row from range1
            startRow = regexp(ranges{1}, '\d+', 'match');
            % get row from range2
            endRow = regexp(ranges{2}, '\d+', 'match');

            if str2double(startRow{1}) > str2double(endRow{1})
                % replace startRow in range1 with endRow
                ranges{1} = regexprep(ranges{1}, startRow{1}, endRow{1});
                % replace endRow in range2 with startRow
                ranges{2} = regexprep(ranges{2}, endRow{1}, startRow{1});
                excelRange = [ranges{1} ':' ranges{2}];
            end
        end

        % function takes in excel range in format A1:A2 (will not validate for single cells like A1, A1:)
        % if the start column in the excel range is greater than the end
        % column then the order is swapped
        function excelRange = makeValidColumnLimitsOrderInExcelRange(excelRange)
            % split by ':'
            [~, ranges]  = regexp(excelRange, ':', 'match', 'split');

            if isempty(ranges) || ~isequal(length(ranges), 2)
                excelRange = [];
                return;
            end

            % get the row from range1
            startColumn = regexp(ranges{1}, '[a-zA-Z]+', 'match');
            % get row from range2
            endColumn = regexp(ranges{2}, '[a-zA-Z]+', 'match');

            if double(startColumn{1}) > double(endColumn{1})
                % replace startRow in range1 with endRow
                ranges{1} = regexprep(ranges{1}, startColumn{1}, endColumn{1});
                % replace endRow in range2 with startRow
                ranges{2} = regexprep(ranges{2}, endColumn{1}, startColumn{1});
                excelRange = [ranges{1} ':' ranges{2}];
            end
        end

        % if the row limits in the excel range are outside the bounds, that
        % is start is less than 0 or end is greater than the row count then
        % it sets the row to the valid bounds.
        function validRow = getValidRowSelectionRange(row, sheetDimensions)
            % if sheet dimensions are not provided in the expected format
            % then just return the column
            if length(sheetDimensions) < 2
                validRow = row;
                return;
            end
            rowEnd = sheetDimensions(2);

            % if row is less than 0 then set it to 1
            if row <= 0
                row = 1;
            else
                if row > rowEnd
                    row = rowEnd;
                end
            end

            validRow = row;
        end

        % if the column limits in the excel range are outside the bounds,
        % that is the start column is less than 0 or the end column is
        % greater than the column count then it sets the column to the
        % valid bounds.
        function validColumn = getValidColumnSelectionRange(column, sheetDimensions)
            % if sheet dimensions are not provided in the expected format
            % then just return the column
            if length(sheetDimensions) < 4
                validColumn = column;
                return;
            end

            columnEnd = sheetDimensions(4);

            % if row is less than 0 then set it to 1
            if column <= 0
                column = 1;
            else
                if column > columnEnd
                    column = columnEnd;
                end
            end

            validColumn = column;
        end

        function columnNames = getDefaultColumnNames(wsVarNames, data, ncols, avoidShadow, useLegacyVariableNames)
            if nargin<=2 || ncols==-1
                ncols = size(data,2);
            end

            if ~isstring(data)
                data = string(data);
            end

            % initialize columnNames to be a row vector - that's what
            % callers expect us to return
            columnNames = string([]);

            % reshape wsVarNames to be a row vector to line up with
            % columnNames being a row vector
            wsVarNames = reshape(wsVarNames, 1, numel(wsVarNames));

            for col=1:ncols
                if col <= size(data, 2) && ~ismissing(data(1,col)) && ~strcmp(data(1,col), '')
                    % In the future, we may want to converge on using the same
                    % exact names that readtable produces, in which case we can
                    % change this code to:
                    % cellData = matlab.lang.makeValidName(data(1,col), "ReplacementStyle", "delete");
                    % But this will cause a lot of churn, so for now just try to
                    % incrementally bring the two closer by handling the camel
                    % case issue.

                    % Try to extract a valid variable name from the column
                    % header.  This is done by replacing any beginning
                    % characters which are not alphabetic with '', and any
                    % non-alphanumeric or underscore characters in the rest
                    % of the name with ''.  For example, a header name like
                    % '1_BadVar#1_Name' will become BadVar1_Name.

                    % But first, replace any spaces by concatentating together,
                    % and making it CamelCase.

                    name = data(1,col);
                    if (useLegacyVariableNames)
                        name = regexprep(name, '(?<=\S)\s+([a-z])', '${upper($1)}');
                        cellData = regexprep(name, ...
                            '^[^a-zA-Z]*|[^a-zA-Z0-9_]', '');
                    else
                        % g1769966: Bring parity to the JS Import Tool and
                        % the readtable function by using the makeValidName
                        % API with "underscore" as the replacement strategy
                        cellData = matlab.lang.makeValidName(name);
                    end
                else
                    cellData = '';
                end
                if ~(strcmp(cellData, ''))
                    colName = cellData;
                else
                    if (useLegacyVariableNames)
                        colName = "VarName" + col;
                    else
                        % g1769966: Bring parity to the JS Import Tool and
                        % the readtable function
                        colName = "Var" + col;
                    end
                end

                varName = colName;
                if (useLegacyVariableNames)
                    if strlength(colName) > namelengthmax
                        varName = colName.extractBefore(namelengthmax+1);
                    end
                end

                % This if condition should only pass if the output type is
                % NOT a table.
                if needsNewName(varName, wsVarNames, columnNames, avoidShadow)
                    varName = getNewVarName(varName, wsVarNames, columnNames, avoidShadow);
                end

                % add the new var name to the end of the row
                columnNames(1, end+1) = varName;
            end

            if ~(useLegacyVariableNames)
                % We need this because the makeUniqueStrings API should
                % handle this edge case for parity with readtable.
                columnNames = matlab.lang.makeUniqueStrings(columnNames,{},namelengthmax);
            end
        end

        function columnNames = getArbitraryColumnNames(data, stripSpaces, useLegacyVariableNames)
            % Use the data as column names, but replace any empty text with
            % Varname#, and make sure they are unique.

            % Only strip spaces if the flag is set
            if stripSpaces
                columnNames = strtrim(string(data));
            else
                columnNames = string(data);
            end

            % But always strip spaces to check for empty column names.  (Both ""
            % and " ", for example, are considered empty).
            emptyCells = strtrim(columnNames) == "";
            if any(emptyCells)
                if (useLegacyVariableNames)
                    generatedNames = "VarName" + (1:length(data));
                else
                    % g1769966: Bring parity to the JS Import Tool and
                    % the readtable function
                    generatedNames = "Var" + (1:length(data));
                end
                columnNames(emptyCells) = generatedNames(emptyCells);
            end

            % Make sure the column names aren't too long
            longColNames = strlength(columnNames) > namelengthmax;
            if any(longColNames)
                columnNames(longColNames) = columnNames(longColNames).extractBefore(namelengthmax + 1);
            end

            % And make the text unique, assuring that all names are less than
            % the max length.  (The true argument makes sure all names are
            % considiered for the uniqueness).
            columnNames = matlab.lang.makeUniqueStrings(columnNames, ...
                true(size(columnNames)), namelengthmax);
        end

        function b = isStringTextType()
            b = strcmp(internal.matlab.importtool.server.ImportUtils.getSetTextType, 'string');
        end

        function b = getSetTextType(varargin)
            s = settings;
            st = s.matlab.importtool.ImportToolTextType;
            if nargin == 1
                newTextType = varargin{1};
                if strcmp(newTextType, 'char') || ...
                        strcmp(newTextType, 'string')
                    st.PersonalValue = newTextType;
                end
            else
                b = st.ActiveValue;
            end
        end

        function formats = getFormatsForCol(col, sampleSize, formatFunc)
            if ~isstring(col)
                col = string(col);
            end
            half = min(10, ceil(sampleSize/2));
            col = [col(1:half); col(floor(median([1,length(col)]))); col(length(col)-half+1:end)];
            formats = arrayfun(formatFunc, col, 'UniformOutput', false);
        end

        function dateFormat = getDateFormat(str)
            currentLocale = internal.matlab.datatoolsservices.LocaleUtils.getCurrLocale();
            dateFormat = '';

            w = warning('off', 'MATLAB:datetime:AmbiguousDateString');
            L = lasterror; %#ok<*LERR>
            try
                dt = datetime(str, "Format", "preserveinput", ...
                    "Locale", currentLocale);
                if ~isnat(dt)
                    dateFormat = dt.Format;
                    dateFormat = replace(dateFormat, "uu", "yy");
                    if contains(dateFormat, "yyyy") && dt.Year < 100
                        dateFormat = replace(dateFormat, "yyyy", "yy");
                    end
                end
            catch
                % Ignore errors from trying to convert to datetime
            end

            % Reset warning and lasterror state
            warning(w);
            lasterror(L);
        end

        function [dateFormat, formatIndex] = getDateFormatWithLocale(str, formatstr, englishLocale)

            dateFormat = '';
            formatIndex = -1;

            % disable any warnings coming from the datetime constructor.
            % It will try to warn for ambiguous formats which we may not
            % care about, and capture lasterror to reset it afterwards, so
            % format errors won't show up in lasterror after Import.
            s = warning('off', 'all');
            cl1 = onCleanup(@() warning(s));
            L = lasterror; %#ok<*LERR>
            cl2 = onCleanup(@() lasterror(L));

            for k=1:length(formatstr)
                try %#ok<TRYNC>
                    % Attempt to guess the best matching format for the
                    % given date/time string.  The datetime constructor
                    % will guess many formats, but it sets the Format
                    % property of the resulting datetime array to the
                    % format passed in, so its best if we can guess what
                    % the best matching format is.
                    format_slashdates = false;
                    format_dashdates = false;

                    if str.contains('-')
                        format_dashdates = ~isempty(regexp(str,'^\w{1,2}\-{1}\w{3}\-{1}\w{2,4}.*','once')); %ww-www-ww(ww)*
                        if ~format_dashdates
                            % try with year first
                            format_dashdates = ~isempty(regexp(str,'^\w{2,4}\-{1}\w{2}\-{1}\w{1,2}.*','once')); %ww(ww)-w(w)-w(2)*
                        end
                    end
                    if ~format_dashdates && str.contains('/')
                        format_slashdates = ~isempty(regexp(str,'^\w{1,2}\/{1}\w{1,2}\/{0,1}\w{0,4}.*','once'));
                    end
                    format_times = str.contains(':') && ~isempty(regexp(str,'\w{1,2}\:{1}\w{2}\:{0,1}\w{0,2}.*','once'));

                    if format_dashdates || format_slashdates || format_times

                        if format_slashdates && ...
                                isempty(regexp(formatstr{k},'^\w{1,2}\/{1}\w{1,2}\/{0,1}\w{0,4}.*','once'))
                            % date string has slashes but format doesn't,
                            % so skip it
                            continue;
                        end

                        if format_dashdates && ...
                                isempty(regexp(formatstr{k},'^\w{1,2}\-{1}\w{3}\-{1}\w{2,4}.*','once')) && ...
                                isempty(regexp(formatstr{k},'^\w{2,4}\-{1}\w{2}\-{1}\w{1,2}.*','once'))
                            % date string has slashes but format doesn't,
                            % so skip it
                            continue;
                        end

                        if ~format_times && ...
                                ~isempty(regexp(formatstr{k},'\w{2}\:{1}\w{2}\:{0,1}\w{0,2}.*','once'))
                            % date string doesn't have times but format
                            % does, so skip it
                            continue
                        end

                        % Attempt to create a datetime object with the
                        % specified format.
                        dt = [];
                        try
                            dt = datetime(str, 'InputFormat', formatstr{k});
                        catch
                            if ~englishLocale
                                % Try using English locale as well
                                try
                                    dt = datetime(str, 'InputFormat', ...
                                        formatstr{k}, 'Locale', 'en_US');
                                catch
                                end
                            end
                        end

                        % If the format doesn't work, the datetime
                        % properties will be NaN.  Check an arbitrary one
                        % (hour) to see whether it worked.  Also avoid
                        % years less than 100 (so we don't choose a year
                        % format of yyyy for 2 digit years)
                        if ~isempty(dt) && ~isnan(dt.Hour) && dt.Year > 100
                            dateFormat = formatstr{k};
                            formatIndex = k;
                            return
                        end
                    end
                end
            end
        end

        % Returns the list of all date formats which the import tool will
        % attempt to match.
        function dateFormats = getAllDateFormats
            dateFormats = strings(16, 1);
            dateFormats(1) = "dd-MMM-yyyy HH:mm:ss";
            dateFormats(2) = "dd-MMM-yyyy";

            currentLocale = internal.matlab.datatoolsservices.LocaleUtils.getCurrLocale;
            englishLocale = strcmpi(currentLocale,'en_US');

            if englishLocale
                dateFormats(3) = "MM/dd/yy HH:mm:ss";
                dateFormats(4) = "MM/dd/yyyy HH:mm:ss";
                dateFormats(5) = "MM/dd/yyyy hh:mm:ss a";
                dateFormats(6) = "MM/dd/yyyy";
                dateFormats(7) = "MM/dd/yy";
                dateFormats(8) = "MM/dd";
            else
                dateFormats(3) = "dd/MM/yy HH:mm:ss";
                dateFormats(4) = "dd/MM/yyyy HH:mm:ss";
                dateFormats(5) = "dd/MM/yyyy hh:mm:ss a";
                dateFormats(6) = "dd/MM/yyyy";
                dateFormats(7) = "dd/MM/yy";
                dateFormats(8) = "dd/MM";
            end

            dateFormats(9) = "HH:mm:ss";
            dateFormats(10) = "hh:mm:ss a";
            dateFormats(11) = "HH:mm";
            dateFormats(12) = "hh:mm a";
            dateFormats(13) = "dd-MMM-yyyy HH:mm";  %used by finance
            dateFormats(14) = "dd-MMM-yy";  %used by finance
            dateFormats(15) = "MM/dd/yyyy HH:mm";
            dateFormats(16) = "yyyy-MM-dd"; % ISO 8601 standard
        end

        function durationFormat = getDurationFormat(str)
            % detectImportOptions can recognize dd:hh:mm:ss(.S*) and hh:mm:ss(.S*)
            if (isstring(str) || ischar(str)) && any(regexp(str, '^\d+(:\d{1,2}){2,3}(\.\d*)?$', 'once'))
                if count(str, ':') == 3
                    durationFormat = 'dd:hh:mm:ss.S';
                else
                    durationFormat = 'hh:mm:ss.S';
                end
            else
                durationFormat = '';
            end
        end

        function val = variableExists(varName)
            % variableExists is used to ensure that default variable names do
            % not conflict with MATLAB functions, classes, builtins etc. Note,
            % that we do not care about exist(varName)==1 because conflicts
            % with variables in this function's workspace are not important.

            %TODO: convert to char for exist and which functions
            if isstring(varName)
                varName = char(varName);
            end

            val = 0;
            if exist(varName, 'var') % Check for variables
                val = 1;
            else
                whichVarName = which(varName);

                if ~isempty(whichVarName)
                    if ~isempty(regexp(whichVarName, ...
                            ['(.*[\\/]' varName '\.m)'], 'match'))
                        val = 2;
                    elseif ~isempty(regexp(whichVarName, ...
                            ['(.*[\\/]' varName '\))'], 'match'))
                        val = 3;
                    end

                    if (val > 0) && ...
                            contains(whichVarName, '@') && ...
                            (exist(varName, 'builtin') == 0)
                        % The varName only exists as a function within a
                        % Matlab class folder.  Don't consider this as an
                        % existing variable, since it can't be called
                        % directly on the command line.
                        val = 0;
                    end
                end
            end
        end

        % Used as unique name for text import tool
        function name = getValidNameFromTextFile(dataSource)
            [~, filename, ~] = fileparts(dataSource);
            name = matlab.lang.makeValidName(filename);
        end

        function progressMessage = showImportProgressWindow(position, progressText)
            % Show a progress window for the Import Tool opening
            import matlab.internal.capability.Capability;

            if Capability.isSupported(Capability.LocalClient)
                % In MATLAB Online, the Import Tool is shown docked, so we
                % should show the message.  In the JSD, it opens undocked
                % in a browser window, which shows its own message.
                progressMessage = [];
                return;
            end

            progressWindows = internal.matlab.importtool.server.ImportUtils.findImportProgressWindow;
            if ~isempty(progressWindows)
                for idx = 1:length(progressWindows)
                    progressWindow = progressWindows(idx);
                    isVisible = (progressWindow.Visible == "on");
                    if isVisible
                        % Don't show multiple progress windows, return if any
                        % are open
                        return;
                    elseif strcmp(progressWindow.Children.String, progressText)
                        % show the progress window
                        progressWindow.Visible = "on";
                        return;
                    end
                end
            end

            title = getString(message(...
                'MATLAB:codetools:importtool:ProgressMessageTitle'));

            centerDialog = false;
            if isempty(position)
                position =  [300, 300, 250, 70];
                centerDialog = true;
            end

            try
                progressMessage = dialog(...
                    'Position', position, ...
                    'WindowStyle', 'normal', ...
                    'Name', title, ...
                    'Tag', 'ImportToolProgress', ...
                    'Visible','off');

                uicontrol('Parent', progressMessage, ...
                    'Style', 'text', ...
                    'Position', [0.5 0.5 210 40], ...
                    'String', progressText, ...
                    'Units', 'normalized');

                if centerDialog
                    movegui(progressMessage, 'center');
                end

                progressMessage.Visible = 'on';
            catch
                % Tests can make these messages come and go quickly, ignore any
                % errors if it happened to be deleted
            end
            drawnow;
        end

        function h = findImportProgressWindow()
            % Return the progress window for the Import Tool opening
            h = findall(groot, 'Tag', 'ImportToolProgress');
        end

        function h = findVisibleImportProgressWindow()
            % Return the progress window for the Import Tool opening
            h = [];
            progressWindows = internal.matlab.importtool.server.ImportUtils.findImportProgressWindow;
            for idx = 1:length(progressWindows)
                progressWindow = progressWindows(idx);
                if progressWindow.Visible
                    h = progressWindow;
                    break;
                end
            end
        end

        function h = closeImportProgressWindow()
            % Close the progress window for the Import Tool opening
            h = internal.matlab.importtool.server.ImportUtils.findImportProgressWindow;
            if ~isempty(h)
                set(h, "Visible", "off");
                delete(h);
            end
        end

        function b = requiresExcelForImport(extension)
            % Excel formats of xlsb and ods require the use of Excel.
            b = contains(extension, ...
                internal.matlab.importtool.server.ImportUtils.EXCEL_SPREADSHEET_TYPES, ...
                'IgnoreCase', true);
        end

        function importType = getImportType(filename)
            spreadsheetFileExtensions = matlab.io.internal.FileExtensions.SpreadsheetExtensions;
            currentFormat = ['.' finfo(convertStringsToChars(filename))];

            % if spreadsheet
            if any(strcmp(currentFormat, spreadsheetFileExtensions))
                importType = 'spreadsheet';
            else
                importType = 'text';
            end
        end

        function [fileExists, fileLength, resolvedFile] = checkFileExists(selectedFile)
            % Check to see if the specified file actually exists.  Uses 'which' if
            % needed, to resolve partial paths.

            arguments
                selectedFile string
            end

            f = dir(selectedFile);
            resolvedFile = selectedFile;

            if isempty(f)
                % The file can't be accessed.  Check if the file is on the path.
                fileOnPath = which(selectedFile);
                if isempty(fileOnPath)
                    % Can't find the file this way either
                    f = struct("bytes", 0);
                else
                    % The file was found somewhere on the path, use this as the full
                    % path name.
                    resolvedFile = fileOnPath;
                    f = dir(resolvedFile);
                end
            end

            fileLength = f.bytes;
            fileExists = isfield(f, 'name');

            if fileExists
                [status, attr] = fileattrib(resolvedFile);
                readAccess = status && attr.UserRead;
                fileExists = fileExists && readAccess;
            end

            if fileExists && ispc 
                % Check if this is a shortcut link file
                [~, ~, ext] = fileparts(resolvedFile);
                if ext == ".lnk"
                    aserver = actxserver('WScript.Shell');
                    s = aserver.CreateShortcut(resolvedFile);
                    [fileExists, fileLength, resolvedFile] = internal.matlab.importtool.server.ImportUtils.checkFileExists(s.TargetPath);
                end
            end
        end

        function isValid = isValidExcelRange(excelRange)
            isValid = true;
            if (~isstring(excelRange) && ~ischar(excelRange)) || ~contains(excelRange, ":") || ...
                    startsWith(excelRange, ":") || endsWith(excelRange, ":")
                isValid = false;
            else
                try
                    [r,c] = internal.matlab.importtool.server.ImportUtils.getRowsColsFromExcel(excelRange);
                    if anynan(r) || anynan(c) || ~isequal(size(r,2), 2) || ~isequal(size(c,2), 2)
                        isValid = false;
                    end
                catch
                    isValid = false;
                end
            end
        end

        function b = isInteractiveCodegen(dataSource)
            % Returns true if dataSource is a struct, with a field
            % 'InteractionMode', and the value is interactiveCodegen.
            b = isstruct(dataSource) && ...
                isfield(dataSource, "InteractionMode") && ...
                ~isempty(dataSource.InteractionMode) && ...
                strcmp(dataSource.InteractionMode, "interactiveCodegen");
        end

        function sheets = sheetnames(filename)
            % Wrapper around the sheetnames function because it sets lasterror
            % even if the input is valid (g2681779)
            arguments
                filename (1,1) string
            end

            lx = lasterror;
            sheets = sheetnames(filename);
            lasterror(lx);
        end

        % checks the passed-in dialog to see if it is presently open
        function dialogIsOpen = dialogIsOpen(app, f)
            dialogIsOpen = false;

            % we can't track whether the dialog is open, because when the user closes it
            % we aren't notified. as a result, we can't set the flag false once the
            % window is gone. so we have to check our local store of the dialog
            % every time we want to tell if the dialog is open or not
            try
                % if dialog is not and never was a dialog, it will be an
                % empty double. in this case, isvalid will throw because it
                % is not a handle. hence the try/catch block.
                if ~isempty(app) && isvalid(app)
                    figure(app.(f));

                    % if dialog was an active dialog, we can infer that the
                    % dialog is open.
                    dialogIsOpen = true;
                end
                % if dialog was formerly a handle but has since been
                % closed, we will fall back on the initilized value of
                % false
            catch
                % if we get here, the dialog was not a dialog. from this we
                % can infer that the dialog is not open
                dialogIsOpen = false;
            end
        end
    end

    methods(Static, Access = private)

        function d = base27dec(s)
            %   BASE27DEC(S) returns the decimal of string S which
            %   represents a number in base 27, expressed as 'A'..'Z',
            %   'AA','AB'...'AZ', and so on. Note, there is no zero so
            %   strictly we have hybrid base26, base27 number system.
            %
            %   Examples
            %       base27dec('A') returns 1 base27dec('Z') returns 26
            %       base27dec('IV') returns 256
            %-------------------------------------------------------------
            s = upper(strtrim(s));
            if isscalar(s)
                d = s(1) -'A' + 1;
            else
                cumulative = 0;
                for i = 1:numel(s)-1
                    cumulative = cumulative + 26.^i;
                end
                indexes_fliped = 1 + s - 'A';
                indexes = fliplr(indexes_fliped);
                indexes_in_cells = num2cell(indexes);
                d = cumulative + sub2ind(repmat(26, 1,numel(s)), indexes_in_cells{:});
            end
        end
    end
end

function TF = needsNewName(varName, wsVarNames, derivedColumnNames, avoidShadow)
    % needsNewName returns true if a new name is needed. New names
    % are never needed if avoidShadow is ALLOW_SHADOW.
    % if avoidShadow is AVOID_SOME_SHADOWS, names must be
    % "isvarname" and not be duplicated.
    % if avoidShadow is AVOID_SOME_SHADOWS, names must be
    % "isvarname", not be duplicated, must not be an existing
    % variable, and must not be a function or builtin.

    %TODO: convert to char for isvarname
    TF = false;
    if avoidShadow.isAvoidSomeShadows && ... % tables
            (any(strcmp(varName,derivedColumnNames)) || ~isvarname(char(varName)))
        TF = true;
    elseif avoidShadow.isAvoidAllShadows && ... % column vectors
            (internal.matlab.importtool.server.ImportUtils.variableExists(varName)>1 ...
            || any(strcmp(varName,[wsVarNames(:); derivedColumnNames(:)])))
        TF = true;
        % else -  numeric Matrix or cell array - always false;
    end
end

function varName = getNewVarName(varName, wsVarNames, columnNames, avoidShadow)
    % getNewVarName returns a valid name that can be used as a column header
    numericSuffixStart = regexp(varName,'\d*$','once');
    if ~isempty(numericSuffixStart)
        varNameRoot = varName.extractBefore(numericSuffixStart);
    else
        varNameRoot = varName;
    end
    suffixDigit = 1;

    if strlength(varNameRoot) >= namelengthmax
        varName = varNameRoot.extractBefore(min(namelengthmax-length(num2str(suffixDigit))+1, ...
            strlength(varNameRoot)+length(num2str(suffixDigit))));
    else
        varName = varNameRoot;
    end

    if avoidShadow.isAvoidSomeShadows % Tables - just don't used matlab
        % keywords or duplicated column
        % names.
        while iskeyword(varName+suffixDigit) || ...
                any(strcmp(varName+suffixDigit,columnNames(:)))
            suffixDigit=suffixDigit+1;
            if strlength(varName+suffixDigit) >= namelengthmax
                varName = varNameRoot.extractBefore(namelengthmax-length(num2str(suffixDigit))+1);
            end
        end
    elseif avoidShadow.isAvoidAllShadows % Column vectors
        while internal.matlab.importtool.server.ImportUtils.variableExists(varName+suffixDigit)>1 || ...
                any(strcmp(varName+suffixDigit, [wsVarNames(:); columnNames(:)]))
            suffixDigit=suffixDigit+1;
            if strlength(varName+suffixDigit) >= namelengthmax
                varName = varNameRoot.extractBefore(namelengthmax-length(num2str(suffixDigit))+1);
            end
        end
    end
    varName = varName+suffixDigit;
end

