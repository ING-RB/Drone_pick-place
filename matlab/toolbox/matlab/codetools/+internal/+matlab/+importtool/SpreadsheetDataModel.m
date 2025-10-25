classdef SpreadsheetDataModel < internal.matlab.importtool.TabularDataModel

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % This class is the DataModel class for Spreadsheet Import.

    % Copyright 2018-2024 The MathWorks, Inc.

    properties (SetObservable = true)
        Workbook;
        Sheet;
        SheetName;
        SheetID;
        DataRange;
        FullRange;
        UseExcelDefault = false;
    end

    properties(Access = private)
        DetectFcn = @detectImportOptions;
    end

    methods
        function this = SpreadsheetDataModel(dataSource, sheetname, sheetID, varargin)
            % Create a SpreadsheetDataModel.  Requires the filename and
            % sheetname of the spreadsheet.  sheetID can be an ID or empty.
            % Optional varargin can be the Workbook object.  Since there is a
            % big performance hit to creating this, if it is already done it can
            % be reused here.
            if nargin < 1 || isempty(dataSource)
                error(message('MATLAB:codetools:FilenameMustBeSpecified'));
            end

            if isstruct(dataSource)
                filename = dataSource.FileName;
                sheetname = dataSource.SheetName;
                sheetID = dataSource.SheetID;

                if internal.matlab.importtool.server.ImportUtils.isInteractiveCodegen(dataSource)
                    this.DetectFcn = memoize(@detectImportOptions);
                end
            else
                filename = dataSource;
                
                if nargin == 3
                    this.SheetID = sheetID;
                else
                    this.SheetID = [];
                end
            end

            if nargin == 3
                this.SheetID = sheetID;
            else
                this.SheetID = [];
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

            if nargin == 4
                % If the Workbook has already been created, it can be passed in
                % as an optional argument.
                this.Workbook = varargin{1};
            else
                % Otherwise, create the Workbook object.
                swf = internal.matlab.importtool.server.SpreadsheetWorkbookFactory.getInstance;
                this.Workbook = swf.getWorkbookForFile(filename);
            end

            this.Sheet = this.Workbook.getSheet(convertStringsToChars(sheetname));
            this.FileName = filename;
            this.SheetName = sheetname;
            this.HasFile = true;
            this.CacheData = containers.Map;
            this.SheetID = sheetID;
            
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
                this.imopts = dataSource.ImportOptions;
                this.ImportOptionsProvided = true;
            else
                l = lasterror; %#ok<*LERR>
                this.imopts = this.DetectFcn(this.FileName, "Sheet", sheetname, ...
                    "TextType", "string");
                lasterror(l);
            end
            
            % Save the detected variable types, for comparison later on.  This
            % should be done after detectImportOptions is called.
            this.DetectedColumnClasses = this.imopts.VariableTypes;
        end

        function columnTypes = getUnderlyingColumnTypes(this)
            columnTypes = this.getColumnClasses();
        end

        function fmt = getFormat(this)
            % Returns the format of the worksheet (xlsx, xls, etc...)
            fmt = this.Workbook.Format;
        end

        function wb = getWorkbook(this)
            wb = this.Workbook;
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
            import internal.matlab.importtool.SpreadsheetDataModel;

            % Use the ImportOptions to get the header row
            if isempty(this.imopts.VariableNamesRange)
                headerRow = 1;
            else
                headerRow = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(...
                    [this.imopts.VariableNamesRange ':' this.imopts.VariableNamesRange]);
            end
        end

        function dateColFormats = getDateFormats(this)
            % Setup the datetime columns.  Need to handle cases where the
            % spreadsheet doesn't start at cell A1, so there could be columns
            % prior to the ones that imopts has reported
            dataPos = this.getSheetDimensions();
            numcols = dataPos(4);

            datetimeCols = cellfun(@(x) x == "datetime", this.imopts.VariableTypes);
            dateFormats = repmat({''}, size(datetimeCols));
            if any(datetimeCols)
                dateFormats(datetimeCols) = {this.imopts.VariableOptions(datetimeCols).DatetimeFormat};
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

            headerRow = this.getHeaderRow();
            initialSelection = ...
                [min(max(rows(1), headerRow+1), rows(end)), cols(1), rows(end), cols(end)];
        end

        function columnClassOptions = getColumnClassOptions(this)
            columnClassOptions = this.getColumnClassOptions@internal.matlab.importtool.TabularDataModel();

            % Need to make sure the InitialColumnClassOptions is set
            if isempty(this.InitialColumnClassOptions)
                this.InitialColumnClassOptions = columnClassOptions;
            end
        end

        function [opts, dataRanges] = getImportOptions(this, varargin)
            persistent p

            if isempty(p)
                p = inputParser;
                addParameter(p, "Range", "", @(x) validateattributes(x, ...
                    ["string", "char", "cell"], {'nonempty'}));
                addParameter(p, "Rules", [], @(x) validateattributes(x, ...
                    ["internal.matlab.importtool.server.rules.ImportRule", "double"], {'2d'}));
                addParameter(p, "ColumnVarTypes", "", @(x) validateattributes(x, ...
                    ["string", "cell"], {'nonempty'}));
                addParameter(p, "ColumnVarNames", strings(0), @(x) validateattributes(x, ...
                    ["string", "cell", "double"], {'2d'}));
                addParameter(p, "ColumnVarTypeOptions", [], @(x) validateattributes(x, ...
                    ["string", "cell", "double"], {'2d'}));
            end
            parse(p, varargin{:})
            args = p.Results;

            [opts, dataRanges] = getImportOptionsFromArgs(this, args);
            if ischar(dataRanges) || isstring(dataRanges)
                opts.DataRange = dataRanges;
            elseif ischar(dataRanges{1})
                opts.DataRange = dataRanges{1};
            end
        end
        
        function columnCount = getColumnCount(this)
            columnCount = length(this.imopts.VariableNames);
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
                % SelectedVareiableNames property to actually get the
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
            % ignoed on text/categorical columns).
            textCatColumns = cellfun(@(x) x == "string" || x == "char" || x == "categorical", opts.VariableTypes);
            if any(textCatColumns)
                opts = setvaropts(opts, find(textCatColumns), "EmptyFieldRule", "auto");
            end

            dataRanges = args.Range;
        end

        function [varNames, vars] = ImportData(this, opts, varargin)
            persistent p;
            if isempty(p)
                p = inputParser;
                addParameter(p, "VarNames", "", @(x) validateattributes(x, ...
                    ["string", "char", "cell"], {'nonempty'}));
                addParameter(p, "OutputType", "", @(x) validateattributes(x, ...
                    "internal.matlab.importtool.server.output.OutputType", {'scalar'}));
                addParameter(p, "Range", strings(0), @(x) validateattributes(x, ...
                    ["string", "char", "cell"], {'nonempty'}));
            end
            parse(p, varargin{:})
            args = p.Results;
            if isempty(args.Range)
                args.Range = opts.DataRange;
            end

            % Save and reset the lasterror state, which may be set in the
            % process of calling readtable.
            l = lasterror;
            % Get the read* function to use for importing.  This could be
            % readtable, readmatrix, readttimetable, etc...
            readFcn = args.OutputType.getImportFunction();
            opts = args.OutputType.updateImportOptionsForOutputType(opts);
            additionalArgs = args.OutputType.getAdditionalArgsForImportFcn();

            t = [];
            if ischar(args.Range) || isstring(args.Range)
                % There's just a single range specified by the text only
                opts.DataRange = args.Range;

                % Use readtable to read in the table range
                if isempty(additionalArgs)
                    t = readFcn(this.FileName, opts, "UseExcel", this.UseExcelDefault);
                else
                    t = readFcn(this.FileName, opts, "UseExcel", this.UseExcelDefault, additionalArgs{:});
                end
            else
                for rowBlockRange = 1:length(args.Range)
                    if length(args.Range{rowBlockRange}) == 1
                        % If we have one continuous set of columns to
                        % import, just use the DataRange as is
                        opts.DataRange = args.Range{rowBlockRange}{1};
                    else
                        % For discontiguous sets of columns, specify the
                        % range as the top left corner to the bottom right
                        % corner of the last column -- the
                        % SelectedVariableNames property will handle what
                        % actually gets imported
                        firstRange = args.Range{rowBlockRange}{1};
                        [dataRangeRows, dataRangeCols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(firstRange);
                        lastRange = args.Range{rowBlockRange}{end};
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

                    if isempty(t)
                        t = tb;
                    else
                        % Piece together discontiguous sets of rows into a
                        % single table
                        t = [t; tb];
                    end
                end
            end
            lasterror(l);

            % Call the OutputType to convert the table to the appropriate output
            % type.
            [convertedVars, convertedVarNames] = args.OutputType.convertFromImportedData(t);
            varNames = args.VarNames;
            if ~isempty(convertedVarNames)
                for idx = 1:length(convertedVarNames)
                    vars{idx} = convertedVars{idx};
                end
                varNames = convertedVarNames;
            else
                vars{1} = convertedVars;
            end
        end
        
        function delete(this)
            swf = internal.matlab.importtool.server.SpreadsheetWorkbookFactory.getInstance;
            swf.workbookClosed(this.FileName);
        end
    end

    methods (Access = protected)

        function out = read(this, range, asDatetime)
            if (~this.HasFile)
                error(message('MATLAB:codetools:NoFileOpen'));
            end

            validateattributes(range, {'char'}, {}, 'spreadsheet', 'Range');

            [data, raw, dateData] = readSheet(this, this.SheetName, range, asDatetime);

            out.data = data;
            out.raw = raw;
            out.dateData = dateData;
        end

        function [data, raw, dateData] = readSheet(this, sheetname, range, asDatetime)
            % Use readtable to read in the range of data from the
            % specifieid sheetname
            if isempty(this.imopts)
                this.imopts = this.DetectFcn(this.FileName, "Sheet", sheetname, ...
                    "TextType", "string");
            end
            this.imopts.Sheet = sheetname;

            % Call readtable to get numeric and datetime data first.  We need
            % this to show 'replacement values' in the UI.  Save and reset the
            % lasterror state, which may be set in the process of calling
            % setvartype.
            datetimeCols = cellfun(@(x) x == "datetime", this.imopts.VariableTypes);
            l = lasterror;
            localImopts = setvartype(this.imopts, find(~datetimeCols), "double");
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
            % and the text for any non-numeric valuies.  We need to call
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

        function tb = readtableInternal(this, opts)
            % Call the internal readSpreadsheet function rather than calling
            % readtable directly.  This improves performance, because it reuses
            % the this.Sheet object, which takes some time to build for larger
            % files.  If we call the public readtable function directly, it
            % needs to rebuild the Sheet every time.  The only difference is
            % that we need to reconstruct the table from the cell array
            % returned.
            [tableData, metadata] = matlab.io.spreadsheet.internal.readSpreadsheet(...
                this.Sheet, opts, {'UseExcel', this.UseExcelDefault});
            
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
                    if ~strcmp(s{1}, this.imopts.DataRange) && ~contains(this.imopts.DataRange, ':')
                        s{1} = this.imopts.DataRange;
                        dataRange = join(s, ':');
                        dataRange= dataRange{1};
                    end
                end

                this.DataRange = dataRange;
                this.FullRange = fullRange;
            else
                dataRange = this.DataRange;
                fullRange = this.FullRange;
            end
        end
    end
end
