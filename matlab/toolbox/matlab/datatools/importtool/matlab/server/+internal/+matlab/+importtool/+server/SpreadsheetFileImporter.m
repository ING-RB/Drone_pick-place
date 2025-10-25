% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides the Spreadsheet file-specific importer functionality in
% the Import Tool

% Copyright 2022-2024 The MathWorks, Inc.

classdef SpreadsheetFileImporter < internal.matlab.importtool.server.TabularFileImporter

    properties
        Workbook;
        Sheet;
        SheetName;
        SheetID;
        UseExcelDefault = false;
    end

    properties (Access = {?internal.matlab.importtool.server.SpreadsheetFileImporter, ?matlab.unittest.TestCase})
        DataRange;
        FullRange;
    end

    properties(Constant)
        % Used in datetime conversion from Excel date numbers to MATLAB
        % datetime.  It is assumed currently that the "Spreadsheet" classes for
        % the Import Tool refer to Excel Spreadsheets, but if we have additional
        % spreadsheets to support, this can grow, and the
        % getConvertedDatetimeValue can be updated.
        CONVERT_FROM_EXCEL = "excel";
    end

    methods
        function this = SpreadsheetFileImporter(dataSource)
            arguments
                dataSource struct = struct();
            end
            this@internal.matlab.importtool.server.TabularFileImporter(dataSource);

            if nargin < 1 || isempty(dataSource)
                error(message('MATLAB:codetools:FilenameMustBeSpecified'));
            end

            filename = dataSource.FileName;
            if nargin < 1 || isempty(filename)
                error(message('MATLAB:codetools:FilenameMustBeSpecified'));
            end

            filename = convertStringsToChars(filename);
            if ~ischar(filename)
                error(message('MATLAB:codetools:FilenameMustBeAString'));
            end
            if any(strfind(filename, '*'))
                error(message('MATLAB:codetools:FilenameMustNotContainAsterisk'));
            end

            if ~isempty(this.Workbook)
                this.Close();
            end

            if isfield(dataSource, "Workbook")
                % If the Workbook has already been created, it can be passed in
                % as an optional argument.
                this.Workbook = dataSource.Workbook;
            else
                % Otherwise, create the Workbook object.
                swf = internal.matlab.importtool.server.SpreadsheetWorkbookFactory.getInstance;
                this.Workbook = swf.getWorkbookForFile(filename);
            end

            this.TableList = internal.matlab.importtool.server.ImportUtils.getSheetNames(filename);
            if isfield(dataSource, "SheetName")
                sheetname = dataSource.SheetName;
            else
                % Initialize to the first table
                sheetname = this.TableList(1);
            end

            if isfield(dataSource, "SheetID")
                sheetID = dataSource.SheetID;
            else
                sheetID = find(strcmp(sheetname, this.TableList));
            end

            this.Sheet = this.Workbook.getSheet(convertStringsToChars(sheetname));
            this.FileName = filename;
            this.SheetName = sheetname;
            this.SheetID = sheetID;
            this.FillInColsAtStart = true;
            this.COL_BLOCK_NUM = 50;
            this.ROW_BLOCK_NUM = 50;
            this.ROUND_DIGITS = -1;

            % Identifiers from the super class
            this.Identifier = "spreadsheet";
            this.TableIdentifier = sheetname;
            this.HasMultipleTables = true;

            % Excel formats of xlsb and ods require the use of Excel, so any
            % interactions with I/O functions should set "UseExcel" to true.
            % (The default is false for better performance and consistent
            % cross-platform support)
            import internal.matlab.importtool.server.ImportUtils;
            this.UseExcelDefault = ImportUtils.requiresExcelForImport(this.Workbook.Format);

            % Use detectImportOptions to create the Spreadsheet Import Options
            % object which will be used as the basis for the initial import
            % display.  Save and reset the lasterror state, which may be set in
            % the process of calling detectImportOptions.
            if isfield(dataSource, "ImportOptions") && ~isempty(dataSource.ImportOptions)
                this.importOptions = dataSource.ImportOptions;
                this.ImportOptionsProvided = true;
            else
                l = lasterror; %#ok<*LERR>
                this.importOptions = detectImportOptions(this.FileName, "Sheet", sheetname, ...
                    "TextType", "string");
                lasterror(l);
            end
            this.OriginalOpts = this.importOptions;

            % Save the detected variable types, for comparison later on.  This
            % should be done after detectImportOptions is called.
            this.DetectedColumnClasses = this.importOptions.VariableTypes;

            this.ViewType = "SpreadsheetView";
            this.RulesStrategy = internal.matlab.importtool.server.rules.RulesStrategy;
            this.DataChangeListener = event.listener(this.RulesStrategy, "DataChange", @(es, ed) this.dataChanged(es, ed));
        end

        function delete(this)
            % Removes the workbook for this file from the
            % SpreadsheetWorkbookFactory cache.
            swf = internal.matlab.importtool.server.SpreadsheetWorkbookFactory.getInstance;
            swf.workbookClosed(this.FileName);
        end

        function d = convertEmptyDatetimes(~, val)
            d = datetime(val, "ConvertFrom", "excel");
        end
    end

    methods  % Implementation of ImportFileImporter

        function columnTypes = getUnderlyingColumnTypes(this)
            columnTypes = this.getColumnClasses();
        end

        function dims = getSheetDimensions(this)
            % Returns a 4-tuple [startRow, rowCount, startColumn, columnCount]
            if ~isempty(this.SheetDimensions)
                dims = this.SheetDimensions;
                return;
            end

            [~, fullRange] = this.getUsedRange();
            [rows, cols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(fullRange);
            this.SheetDimensions = [rows(1), rows(end), cols(1), cols(end)];
            dims = this.SheetDimensions;
        end

        function headerRow = getHeaderRow(this)
            % Returns the header row

            % Use the ImportOptions to get the header row
            if isempty(this.importOptions.VariableNamesRange)
                headerRow = 1;
            else
                headerRow = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(...
                    [this.importOptions.VariableNamesRange ':' this.importOptions.VariableNamesRange]);
            end
        end

        function dateColFormats = getDateFormats(this)
            % Setup the datetime columns.  Need to handle cases where the
            % spreadsheet doesn't start at cell A1, so there could be columns
            % prior to the ones that imopts has reported
            dataPos = this.getSheetDimensions();
            numcols = dataPos(4);

            datetimeCols = cellfun(@(x) x == "datetime", this.importOptions.VariableTypes);
            dateFormats = repmat({''}, size(datetimeCols));
            if any(datetimeCols)
                dateFormats(datetimeCols) = {this.importOptions.VariableOptions(datetimeCols).DatetimeFormat};
            end
            dateColFormats = repmat({''}, 1, numcols);
            dateColFormats(dataPos(3):end) = dateFormats;
        end

        function initialSelection = getInitialSelection(this)
            % Returns the initial selection as: [startRow, startCol, endRow,
            % endCol]

            % Setup the initial selection based on the DataRange and
            % HeaderRow in the worksheet
            dataRange = this.getUsedRange();
            [rows, cols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(dataRange);

            % Don't call getHeaderRow which returns at minimum a value of 1 --
            % if detectImportOptions detects a VariableNamesRange of [], we
            % should start the selection on the first row.
            if isempty(this.importOptions.VariableNamesRange)
                headerRow = 0;
            else
                headerRow = this.getHeaderRow();
            end

            initialSelection = ...
                [min(max(rows(1), headerRow+1), rows(end)), cols(1), rows(end), cols(end)];
        end

        function columnClassOptions = getColumnClassOptions(this)
            columnClassOptions = this.getEmptyColumnClassOptions();

            % Need to make sure the InitialColumnClassOptions is set
            if isempty(this.InitialColumnClassOptions)
                this.InitialColumnClassOptions = columnClassOptions;
            end
        end

        function [opts, dataRanges] = getImportOptions(this, NameValueArgs)
            arguments
                this
                NameValueArgs.ColumnVarNames {mustBeA(NameValueArgs.ColumnVarNames, ["string", "char", "cell"])} = strings(0);
                NameValueArgs.ColumnVarTypeOptions {mustBeA(NameValueArgs.ColumnVarTypeOptions, ["string", "char", "cell", "double"])} = '';
                NameValueArgs.ColumnVarTypes {mustBeA(NameValueArgs.ColumnVarTypes, ["string", "cell"])} = "";
                NameValueArgs.Range {mustBeA(NameValueArgs.Range, ["string", "char", "cell"])} = "";
                NameValueArgs.Rules {mustBeA(NameValueArgs.Rules, ["internal.matlab.importtool.server.rules.ImportRule", "double"])} = [];
            end

            [opts, dataRanges] = getImportOptionsFromArgs(this, NameValueArgs);
            if ischar(dataRanges) || isstring(dataRanges)
                opts.DataRange = dataRanges;
            elseif ischar(dataRanges{1})
                opts.DataRange = dataRanges{1};
            end
        end

        function columnCount = getColumnCount(this)
            columnCount = length(this.importOptions.VariableNames);
        end

        function [varNames, vars, opts] = importData(this, opts, NameValueArgs)
            arguments
                this
                opts
                NameValueArgs.VarNames {mustBeA(NameValueArgs.VarNames, ["string", "char", "cell"])} = "";
                NameValueArgs.OutputType {mustBeA(NameValueArgs.OutputType, "internal.matlab.importtool.server.output.OutputType")} = internal.matlab.importtool.server.output.TableOutputType;
                NameValueArgs.Range {mustBeA(NameValueArgs.Range, ["string", "char", "cell"])} = strings(0);
            end

            if isempty(NameValueArgs.Range)
                NameValueArgs.Range = opts.DataRange;
            end

            % Save and reset the lasterror state, which may be set in the
            % process of calling readtable.
            l = lasterror;
            % Get the read* function to use for importing.  This could be
            % readtable, readmatrix, readttimetable, etc...
            readFcn = NameValueArgs.OutputType.getImportFunction();
            opts = NameValueArgs.OutputType.updateImportOptionsForOutputType(opts);
            additionalArgs = NameValueArgs.OutputType.getAdditionalArgsForImportFcn();

            t = [];
            if ischar(NameValueArgs.Range) || isstring(NameValueArgs.Range)
                % There's just a single range specified by the text only
                opts.DataRange = NameValueArgs.Range;

                % Use readtable to read in the table range
                if isempty(additionalArgs)
                    t = readFcn(this.FileName, opts, "UseExcel", this.UseExcelDefault);
                else
                    t = readFcn(this.FileName, opts, "UseExcel", this.UseExcelDefault, additionalArgs{:});
                end
            else
                dataRange = [];
                dataRangeIdx = 1;
                for rowBlockRange = 1:length(NameValueArgs.Range)
                    if length(NameValueArgs.Range{rowBlockRange}) == 1
                        % If we have one continuous set of columns to
                        % import, just use the DataRange as is
                        opts.DataRange = NameValueArgs.Range{rowBlockRange}{1};
                    else
                        % For discontiguous sets of columns, specify the
                        % range as the top left corner to the bottom right
                        % corner of the last column -- the
                        % SelectedVariableNames property will handle what
                        % actually gets imported
                        firstRange = NameValueArgs.Range{rowBlockRange}{1};
                        [dataRangeRows, dataRangeCols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(firstRange);
                        lastRange = NameValueArgs.Range{rowBlockRange}{end};
                        if dataRangeCols(1) == 1
                            opts.DataRange = extractBefore(firstRange, ":") + ":" + extractAfter(lastRange, ":");
                        else
                            % Readjust the range to start at A1
                            firstRange = internal.matlab.importtool.server.ImportUtils.toExcelRange(...
                                dataRangeRows(1), dataRangeRows(end), 1, dataRangeCols(end));
                            opts.DataRange = extractBefore(firstRange, ":") + ":" + extractAfter(lastRange, ":");
                        end
                    end

                    % Use readtable to read in the table range
                    if isempty(additionalArgs)
                        tb = readFcn(this.FileName, opts, "UseExcel", this.UseExcelDefault);
                    else
                        tb = readFcn(this.FileName, opts, "UseExcel", this.UseExcelDefault, additionalArgs{:});
                    end
                    
                    dataRows = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(opts.DataRange);
                    dataRange(dataRangeIdx, 1) = dataRows(1);
                    dataRange(dataRangeIdx, 2) = dataRows(end);
                    dataRangeIdx = dataRangeIdx + 1;

                    if isempty(t)
                        t = tb;
                    else
                        % Piece together discontiguous sets of rows into a
                        % single table
                        t = [t; tb];
                    end
                end

                opts.DataRange = dataRange;
            end
            lasterror(l);

            % Call the OutputType to convert the table to the appropriate output
            % type.
            [convertedVars, convertedVarNames] = NameValueArgs.OutputType.convertFromImportedData(t);
            varNames = NameValueArgs.VarNames;
            if ~isempty(convertedVarNames)
                for idx = 1:length(convertedVarNames)
                    vars{idx} = convertedVars{idx};
                end
                varNames = convertedVarNames;
            else
                vars{1} = convertedVars;
            end
        end

        function out = read(this, range, asDatetime)
            arguments
                this
                range char
                asDatetime (1,1) logical
            end

            [data, raw, dateData] = readSheet(this, this.SheetName, range, asDatetime);

            out.data = data;
            out.raw = raw;
            out.dateData = dateData;
        end

        % Get the state of the spreadsheet file importer
        function state = getState(this)
            state = this.getCommonState();

            state.SheetName = this.SheetName;
        end

        % Set the state of the spreadsheet file importer
        function setState(this, NameValueArgs)
            arguments
                this
                NameValueArgs.CurrentArbitraryVariableNames;
                NameValueArgs.CurrentValidVariableNames;
                NameValueArgs.ValidMatlabVarNames;
            end

            args = namedargs2cell(NameValueArgs);
            this.setCommonState(args{:});
        end

        function columnNames = getColumnNames(this, row, avoidShadow, varargin)
            columnNames = this.getDefaultColumnNames(row, avoidShadow, varargin{:});
        end

        function [code, codeGenerator, codeDescription] = generateScriptCode(this, opts, NameValueArgs)
            arguments
                this
                opts

                NameValueArgs.Range
                NameValueArgs.OutputType
                NameValueArgs.VarName
                NameValueArgs.DefaultTextType
                NameValueArgs.OriginalOpts
                NameValueArgs.ShowOutput (1,1) logical = false
                NameValueArgs.NumRows (1,1) double
                NameValueArgs.ShortCircuitCode (1,1) logical = false
            end
            codeGenerator = internal.matlab.importtool.server.SpreadsheetCodeGenerator(NameValueArgs.ShowOutput);
            codeGenerator.ShortCircuitCode = NameValueArgs.ShortCircuitCode;
            state = this.getState;
            arbitraryVarNames = ~isequal(state.CurrentArbitraryVariableNames, state.CurrentValidVariableNames);

            [code, codeDescription] = codeGenerator.generateScript(opts, ...
                "Filename", this.FileName, ...
                "Range", NameValueArgs.Range, ...
                "OutputType", NameValueArgs.OutputType, ...
                "VarName", NameValueArgs.VarName, ...
                "OriginalOpts", NameValueArgs.OriginalOpts, ...
                "InitialSelection", this.getInitialSelection, ...
                "InitialSheet", this.TableList(1), ...
                "NumRows", NameValueArgs.NumRows, ...
                "ArbitraryVarNames", arbitraryVarNames, ...
                "DefaultTextType", NameValueArgs.DefaultTextType);
        end

        function [code, codeGenerator] = generateFunctionCode(this, opts, NameValueArgs)
            arguments
                this
                opts

                NameValueArgs.Range
                NameValueArgs.OutputType
                NameValueArgs.VarName
                NameValueArgs.DefaultTextType
                NameValueArgs.ShowOutput (1,1) logical = false
                NameValueArgs.FunctionName
            end
            codeGenerator = internal.matlab.importtool.server.SpreadsheetCodeGenerator;
            code = codeGenerator.generateFunction(opts, ...
                "Filename", this.FileName, ...
                "Range", NameValueArgs.Range, ...
                "OutputType", NameValueArgs.OutputType, ...
                "VarName", NameValueArgs.VarName, ...
                "InitialSelection", this.getInitialSelection, ...
                "DefaultTextType", NameValueArgs.DefaultTextType, ...
                "FunctionName", NameValueArgs.FunctionName);
        end

        function s = addAdditionalImportDataFields(this, currImportDataStruct)
            s = currImportDataStruct;
            s.sheetName = this.SheetName;
        end

        function interpreted = getConvertedDatetimeValue(this, importOptions, data, raw)
            % Override the TabularImportViewModel version to handle numeric conversion
            % from excel numeric values to datetime, which is specific to
            % spreadsheets
            if isfield(importOptions, 'InputFormat')
                if isnumeric(data) && ~isnan(data)
                    % Convert numeric values (excel dates) to datetime, using
                    % the convert from flag, with the output format being the
                    % format specified by the user.
                    interpreted = datetime(data, "ConvertFrom", this.CONVERT_FROM_EXCEL, ...
                        "Format", importOptions.InputFormat);
                else
                    % convert text to datetime with specified input format.  The
                    % output format will be the same as the input format when it
                    % isn't specified.
                    interpreted = datetime(string(raw), "Format", "preserveinput", ...
                        "InputFormat", importOptions.InputFormat);
                end
            end
        end

        % returns the output name with which the data will be imported
        % default output variable name is the filename, converted to a valid MATLAB name
        function varOutputName = getDefaultVariableOutputName(this)
            [~, varOutputName, ~] = fileparts(this.FileName);
            varOutputName = matlab.lang.makeValidName(varOutputName);
            if ~isequal(this.SheetID, 1)
                % append the sheet ID with a prefix 'S' to the output name
                % if it is not the first sheet
                varOutputName = string(varOutputName) + ...
                    getString(message('MATLAB:codetools:importtool:VariableOutputNameSheetIdentifier')) + ...
                    this.SheetID;
            end
        end
    end

    methods(Access = protected)
        function [dataRange, fullRange] = getUsedRange(this)
            % Returns the dataRange and fullRange of data in the file.  The full
            % range is typically the "usedRange" of the Excel file, which
            % includes things table headers and metadata.  The dataRange is the
            % table data range, that is selected by default in the Import Tool.
            if isempty(this.DataRange)
                % Only call the usedDataRange function if it hasn't been done
                % previously, as there is a high performance cost to this
                % determining this.
                dataRange = this.Sheet.getDataSpan();
                if internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(dataRange) == 0
                    % Some Excel files return an invalid data range (like @0),
                    % so try the used range instead. (Especially .xlsb and .ods)
                    dataRange = this.Sheet.usedRange;
                end
                fullRange = dataRange;
                if ~contains(dataRange, ":")
                    % If usedRange is a single cell, double it up.  For example,
                    % 'A1' becomes 'A1:A1'
                    dataRange = [dataRange ':' dataRange];
                    fullRange = dataRange;
                else
                    s = split(dataRange, ":");
                    if ~strcmp(s{1}, this.importOptions.DataRange) && ~contains(this.importOptions.DataRange, ':')
                        % Import Options reported a single value DataRange (like
                        % 'A2'.  Use this as the starting point, unless there
                        % aren't that many rows in the table.
                        dataRangeEndRow = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(s{2});
                        importOptionsStartRow = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(this.importOptions.DataRange);
                        if importOptionsStartRow <= dataRangeEndRow
                            s{1} = this.importOptions.DataRange;
                            dataRange = join(s, ':');
                            dataRange= dataRange{1};
                        end
                    end
                end

                this.DataRange = dataRange;
                this.FullRange = fullRange;
            else
                dataRange = this.DataRange;
                fullRange = this.FullRange;
            end
        end

        function [data, raw, dateData] = readSheet(this, sheetname, range, asDatetime)
            % Use readtable to read in the range of data from the
            % specified sheetname
            internal.matlab.datatoolsservices.logDebug("it", "SpreadsheetFileImporter.read: " + string(range));
            if isempty(this.importOptions)
                this.importOptions = detectImportOptions(this.FileName, "Sheet", sheetname, ...
                    "TextType", "string");
            end
            this.importOptions.Sheet = sheetname;

            % Call /table to get numeric and datetime data first.  We need
            % this to show 'replacement values' in the UI.  Save and reset the
            % lasterror state, which may be set in the process of calling
            % setvartype.
            datetimeCols = cellfun(@(x) x == "datetime", this.importOptions.VariableTypes);
            l = lasterror;
            localImopts = setvartype(this.importOptions, find(~datetimeCols), "double");
            lasterror(l);

            % Adjust the Variable Names being read so that the range can be
            % set accordingly
            [rows, cols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(range);
            numvars = length(localImopts.VariableNames);

            if numvars == 0
                localImopts.VariableNames = "Var1";
            elseif length(cols) > numvars
                [~, dataRangeCols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab([localImopts.DataRange ':' localImopts.DataRange]);
                if ~isequal(cols(1), dataRangeCols(1))
                    % The Import Tool always starts its display at cell A1,
                    % even if the data doesn't actually start there.  But
                    % the import options will only contain variable names
                    % starting at where the data actually beings
                    currVarTypes = localImopts.VariableTypes;
                    tmpVarNames = repmat("VarName", size(cols));
                    tmpVarNames(dataRangeCols:dataRangeCols + numvars - 1) = localImopts.VariableNames;
                    localImopts.VariableNames = cellstr(matlab.lang.makeUniqueStrings(tmpVarNames));

                    tmpVarTypes = repmat("char", size(cols));
                    tmpVarTypes(dataRangeCols:dataRangeCols + numvars - 1) = currVarTypes;
                    localImopts.VariableTypes = cellstr(tmpVarTypes);

                    tmpDTCols = false(size(cols));
                    tmpDTCols(dataRangeCols:dataRangeCols + numvars - 1) = datetimeCols;
                    datetimeCols = tmpDTCols;
                else
                    % The range is asking for data after the last column we
                    % know about -- we need to cut this down
                    cols = cols(1):numvars;
                    range = internal.matlab.importtool.server.ImportUtils.toExcelRange(...
                        rows(1), rows(end), cols(1), cols(end));
                end
            elseif length(cols) < numvars
                dataPos = this.getSheetDimensions();
                cols = cols(1):min(cols(end), dataPos(4));
                localImopts.VariableNames = localImopts.VariableNames(1:length(cols));
                range = internal.matlab.importtool.server.ImportUtils.toExcelRange(...
                    rows(1), rows(end), cols(1), cols(end));
            end
            localImopts.DataRange = range;

            tb = readtableInternal(this, localImopts);
            rawData = table2cell(tb);

            % Data will be the numeric data in the spreadsheet
            idx = cellfun(@isnumeric, rawData);
            data = rawData;
            data(~idx) = {nan};
            data = cell2mat(data);

            % remove complex numbers from import
            data(logical(imag(data))) = NaN;

            % raw is a cell array containing numbers for numeric values,
            % and the text for any non-numeric values.  We need to call
            % readtable again to get the text values for columns which may
            % be mixed (or for header values, for example).  Save and reset the
            % lasterror state, which may be set in the process of calling
            % setvartype.
            l = lasterror;
            opts = setvartype(localImopts, 'char');
            opts = setvaropts(opts, 'WhitespaceRule', 'preserve');
            lasterror(l);
            opts.DataRange = range;
            data2 = readtableInternal(this, opts);
            raw2 = table2cell(data2);
            if isempty(this.RawTextAtStart) && height(data2) > 1 && startsWith(range, "A1")
                % Save the raw text from the start of the file, before it is
                % resolved with numbers/excel datenums.  This is used to pull
                % variable names from.  For example, if the user has dates as
                % the variable names, RawTextAtStart will have the dates in the
                % same format as displayed in Excel (like "Jan. 01, 1984"), but
                % the 'raw' variable will have the excel datenum (like 728334).
                this.RawTextAtStart = raw2;
                this.resetStoredNames();
                if ~isempty(this.CurrentVarShadowSettings) && this.CurrentVarNamesRow > 0
                    % Re-initialize the column names if they were set previously
                    this.getDefaultColumnNames(this.CurrentVarNamesRow, this.CurrentVarShadowSettings);
                end
            end

            % Find nans and datetimes from the initial rawData
            nanIdx = cellfun(@(x) (isnumeric(x) && isnan(x)) || isdatetime(x), rawData);
            datetimeIdx = cellfun(@(x) isdatetime(x) && ~isnat(x), rawData);

            % readtable treats the letters i and j as complex data, which is
            % fine, but we can't pass complex data back to the clients.  For
            % now, convert this to NaN.
            iIdx = cellfun(@(x) ~isempty(x), regexp(raw2, '(\d*j$)|(\d*i$)'));
            data(iIdx) = nan;
            combinedIdx = nanIdx | iIdx;
            raw = rawData;
            raw(combinedIdx) = raw2(combinedIdx);

            if ~asDatetime
                % dateData is a cell array where every non-datetime cell is
                % empty, while every datetime cell is the text of the
                % datetime
                dateData = rawData;
                dateData(~datetimeIdx) = {''};
                if any(any(datetimeIdx))
                    dateData(datetimeIdx) = cellstr([dateData{datetimeIdx}]);
                end
            else
                % dateData is a one-row cell array, where datetime columns
                % are actual datetimes, while non-datetime columns are
                % empty
                numcols = size(tb, 2);
                dateData = cell(1, numcols);
                for i = 1:numcols
                    if ~isempty(datetimeCols) && datetimeCols(i)
                        dateData(i) = {tb{:,i}}; %#ok<CCAT1>
                    end
                end
            end
        end
    end

    methods(Access = {?internal.matlab.importtool.server.SpreadsheetFileImporter, ?matlab.unittest.TestCase })
        function numericColumns = getNumericColumns(this)
            % Setup the numeric columns.  Need to handle cases where the
            % spreadsheet doesn't start at cell A1, so there could be columns
            % prior to the ones that imopts has reported
            dataPos = this.getSheetDimensions();
            numcols = dataPos(4);

            numericColumns = false(1, numcols);
            dblColumns = cellfun(@(x) x == "double", this.importOptions.VariableTypes);
            numericColumns(dataPos(3):end) = dblColumns;
        end
    end

    methods(Access = private)
        function tb = readtableInternal(this, opts)
            % Call the internal readSpreadsheet function rather than calling
            % readtable directly.  This improves performance, because it reuses
            % the this.Sheet object, which takes some time to build for larger
            % files.  If we call the public readtable function directly, it
            % needs to rebuild the Sheet every time.  The only difference is
            % that we need to reconstruct the table from the cell array
            % returned.
            try
                [tableData, metadata] = matlab.io.spreadsheet.internal.readSpreadsheet(...
                    this.Sheet, opts, {'UseExcel', this.UseExcelDefault});
            catch ex
                if ispc
                    [tableData, metadata] = matlab.io.spreadsheet.internal.readSpreadsheet(...
                        this.Sheet, opts, {'UseExcel', true});

                    % If this is successful, set UseExcelDefault to true
                    % for all future calls to readtable
                    this.UseExcelDefault = true;
                else
                    rethrow(ex)
                end
            end
            % Resolve variable names vs. allowed ones
            varNames = matlab.lang.makeUniqueStrings(metadata.VariableNames, ...
                matlab.internal.tabular.private.varNamesDim.reservedNames, namelengthmax);

            % Resolve the table dimensions vs. the Variable Names.  The
            % dimension names can change to allow the user's Variable Names to
            % stay as is.  For example, if the user has 'Row' as one of the
            % Variable Names, keep this, but change the dimension name to
            % something unique (like 'Row_1').  This is exactly what readtable
            % does.
            dimNames = matlab.internal.tabular.private.metaDim().labels;
            dimNames = matlab.lang.makeUniqueStrings(dimNames, ...
                varNames, namelengthmax);

            % Unable to construct a table with DimensionNames property, so we
            % need to use the internal method like readtable does.  Empty arg is
            % the row names, which the Import Tool doesn't currently support.
            tb = table.init(tableData, size(tableData{1}, 1), {}, ...
                size(tableData, 2), varNames, dimNames);
        end

        function [opts, dataRanges] = getImportOptionsFromArgs(this, args)

            % Create the SpreadsheetImportOptions object, for the
            % specified sheet
            opts = matlab.io.spreadsheet.SpreadsheetImportOptions;
            opts.Sheet = this.SheetName;

            % If the user has chosen to not enforce valid Matlab table variable
            % names, then we need to set the 'PreserveVariableNames' flag in the
            % Import Options object, to allow arbitrary variable names to be
            % passed through.
            if ~this.ValidMatlabVarNames
                opts.PreserveVariableNames = true;
            end

            % Setup the Variable Names and types.
            if ischar(args.Range) || isstring(args.Range) || ...
                    (iscell(args.Range) && ...
                    (isscalar(args.Range) && iscell(args.Range{1}) && isscalar(args.Range{1})) || ...
                    (isscalar(args.Range) && ischar(args.Range{1})) || ...
                    (isscalar(args.Range{1})))
                % If there is a single contiguous block of columns
                % selected, it can just be assigned directly to the
                % column variable names.  (Its ok if it doesn't start at
                % the beginning of the data range -- the DataRange below
                % will align it).  Assign the VariableTypes as well.
                if isempty(args.ColumnVarNames)
                    % Column variable names were not supplied, so we need to
                    % generate them.
                    opts.VariableNames = cellstr(matlab.lang.makeValidName("Var" + (1:length(args.ColumnVarTypes))));
                else
                    opts.VariableNames = cellstr(args.ColumnVarNames);
                end

                % Save and reset the lasterror state, which may be set in the
                % process of setting the VariableTypes.
                l = lasterror;
                opts.VariableTypes = args.ColumnVarTypes;
                lasterror(l);
            else
                % If there are multiple blocks of columns selected, we
                % need to fill in the VariableNames to at least that
                % many variables, and then use the
                % SelectedVariableNames property to actually get the
                % columns which are selected.
                cols = [];
                for colBlockRange = 1:length(args.Range{1})
                    [~, colBlock] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(args.Range{1}{colBlockRange});
                    cols = [cols colBlock]; %#ok<*AGROW>
                end

                cols = sort(cols);

                % Create a temporary list of variable names, since the
                % full list needs to be specified
                tmpVarNames = strings(0);
                for idx = 1:cols(end)
                    tmpVarNames(end+1) = "Var" + idx;
                end

                % But assign the SelectedVariableNames to what we
                % actually want to import
                if isempty(args.ColumnVarNames)
                    opts.VariableNames = cellstr(tmpVarNames);
                    opts.SelectedVariableNames = cellstr(tmpVarNames(cols));
                else
                    % Make sure the tmpVarNames aren't one of the column names
                    % selected in the file already.
                    tmpVarNames = matlab.lang.makeUniqueStrings(tmpVarNames, args.ColumnVarNames, namelengthmax);

                    tmpVarNames(cols) = args.ColumnVarNames;
                    opts.VariableNames = cellstr(tmpVarNames);

                    opts.SelectedVariableNames = cellstr(args.ColumnVarNames);
                end

                % Assign the variable types for the selected columns to that
                % which is specified by the client. Save and reset the lasterror
                % state, which may be set in the process of setting the
                % VariableTypes.
                l = lasterror;
                opts.VariableTypes(cols) = cellstr(args.ColumnVarTypes);
                lasterror(l);
            end

            if isempty(args.ColumnVarTypeOptions)
                columnVarTypeOptions = {};
            elseif length(opts.VariableTypes) == length(args.ColumnVarTypeOptions)
                columnVarTypeOptions = cellstr(args.ColumnVarTypeOptions);
            else
                typeOptions = cell(size(opts.VariableTypes));
                typeOptions(cols) = cellstr(args.ColumnVarTypeOptions(1:length(cols)));
                columnVarTypeOptions = typeOptions;
            end

            % Setup the variable type options
            optionColumns = ~cellfun(@isempty, columnVarTypeOptions);
            for column = find(optionColumns)
                dataType = opts.VariableTypes{column};
                typeOption = columnVarTypeOptions{column};
                importOptions = internal.matlab.importtool.server.ImportToolColumnTypes.getColumnImportOptions(dataType, typeOption);
                fields = fieldnames(importOptions);
                values = struct2cell(importOptions);
                for j = 1:length(fields)
                    if ~isequal(fields{j}, "ConvertFrom")
                        % ConvertFrom is not currently supported
                        opts = setvaropts(opts, column, fields{j}, values{j});
                    end
                end
            end

            % Setup the rules for the import
            doubleColumns = cellfun(@(x) x == "double", opts.VariableTypes);
            importErrorRule = strings(0);
            missingRule = strings(0);
            fillValue = NaN;
            % Once we have saved the first fill value, we no longer want to
            % save any future fill values. The first one takes precedence
            % over any following values.
            savedFillValue = false;

            for idx = 1:length(args.Rules)
                rule = args.Rules(idx);
                switch (rule.ID)
                    case "excludeRowsWithBlanks"
                        if isempty(missingRule)
                            missingRule = "omitrow";
                        end

                    case "excludeUnimportableRows"
                        if isempty(importErrorRule) || importErrorRule == "error"
                            importErrorRule = "omitrow";
                        end
                        if isempty(missingRule)
                            missingRule = "omitrow";
                        end

                    case "excludeColumnsWithBlanks"
                        if isempty(missingRule)
                            missingRule = "omitvar";
                        end

                    case "excludeUnimportableColumns"
                        if isempty(importErrorRule) || importErrorRule == "error"
                            importErrorRule = "omitvar";
                        end
                        if isempty(missingRule)
                            missingRule = "omitvar";
                        end

                    case "blankReplace"
                        if isempty(importErrorRule)
                            importErrorRule = "error";
                        end
                        if isempty(missingRule)
                            missingRule = "fill";
                        end
                        if savedFillValue == false
                            fillValue = rule.replaceValue;
                            savedFillValue = true;
                        end

                    case "nonNumericReplaceRule"
                        if isempty(importErrorRule) || importErrorRule == "error"
                            importErrorRule = "fill";
                        end
                        if isempty(missingRule)
                            missingRule = "fill";
                        end
                        if savedFillValue == false
                            fillValue = rule.replaceValue;
                            savedFillValue = true;
                        end
                end
            end

            if ~isempty(importErrorRule)
                opts.ImportErrorRule = importErrorRule;
            end
            if ~isempty(missingRule)
                opts.MissingRule = missingRule;
            end
            if ~isempty(missingRule) || ~isempty(importErrorRule)
                opts = setvaropts(opts, doubleColumns, "TreatAsMissing", '');
            end
            if ~isempty(fillValue) && any(doubleColumns)
                opts = setvaropts(opts, doubleColumns, "FillValue", fillValue);
            end

            % For backwards compatibility, we want to preserve spaces in
            % text (by default the ImportOptions will be set to strip
            % leading/trailing spaces.
            textColumns = cellfun(@(x) x == "string" || x == "char", opts.VariableTypes);
            if any(textColumns)
                opts = setvaropts(opts, find(textColumns), "WhitespaceRule", "preserve");
            end

            % Also set the EmptyFieldRule -- this also helps to match legacy
            % behavior (regarding missing vs "" strings), as well as to help
            % with the exclusion rules (setting this forces the rules to be
            % ignored on text/categorical columns).
            textCatColumns = cellfun(@(x) x == "string" || x == "char" || x == "categorical", opts.VariableTypes);
            if any(textCatColumns)
                opts = setvaropts(opts, find(textCatColumns), "EmptyFieldRule", "auto");
            end

            dataRanges = args.Range;
        end
    end
end
