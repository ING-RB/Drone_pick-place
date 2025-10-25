classdef TextDataModel < internal.matlab.importtool.TabularDataModel

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % This class is the DataModel class for Text Import.

    % Copyright 2018-2022 The MathWorks, Inc.

    properties (Access = private)
        DecimalSeparator;
        ThousandsSeparator = '';
        TextOnlyRawData = false;
        Delimiter;
        InitialDelimiter = [];
        ColumnClassOptions = [];

        FixedWidth = false;
        VariableWidths;

        fwIOpts = [];
        delIOpts = [];

        % From TextFileImporter
        FileEncoding = '';
        EncodingBOMLength = 0;
        FileEncodingForReadtable = '';
        NullCharsExist = false;
        IsCJK = internal.matlab.datatoolsservices.LocaleUtils.isCJK();
        HalfWidthCharsExist = false;
        FullWidthCharsExist = false;
        FilePointer;
        RowCount = 0;
        EmptyRowCount = 0;
        ByteCount = 0;
        SampleData = [];

        % This is used by uiimport to determine the file size at which to show a
        % message about opening a large file, and is also used internally to
        % make decisions to improve performance for large files.
        LargeFileRowCount = 1e6;

        DetectFcn = @detectImportOptions;
    end

    properties(Hidden = true)
        AddedVars = 0;
    end

    properties(Constant = true)
        SampleLines = 100;
        SuggestedDelimMaxLength = 20;
        DefaultVariableWidthInChars = 9;
        DefaultThousandsSeparator = ",";
    end

    methods
        function this = TextDataModel(dataSource, varargin)
            % Create a TextDataModel.  Requires the filename - either on its own
            % or as a field in the dataSource struct.
            if nargin < 1 || isempty(dataSource)
                error(message('MATLAB:codetools:FilenameMustBeSpecified'));
            end

            if isstruct(dataSource)
                filename = dataSource.FileName;

                if internal.matlab.importtool.server.ImportUtils.isInteractiveCodegen(dataSource)
                    this.DetectFcn = memoize(@detectImportOptions);
                end
            else
                filename = dataSource;
                
                if nargin > 1
                    this.TextOnlyRawData = varargin{1};
                end
            end
            
            if nargin < 1 || isempty(filename)
                error(message('MATLAB:codetools:FilenameMustBeSpecified'));
            end
            if ~ischar(filename) && ~isstring(filename)
                error(message('MATLAB:codetools:FilenameMustBeAString'));
            end
            if any(strfind(filename, '*'))
                error(message('MATLAB:codetools:FilenameMustNotContainAsterisk'));
            end

            fid = fopen(char(filename));
            if (fid < 0)
                error(message('MATLAB:codetools:TextFileInvalid'));
            end
            this.FilePointer = fid;

            this.FileName = filename;
            this.HasFile = true;
            this.CacheData = containers.Map;
            this.StripSpacesFromNames = true;

            if nargin > 1
                this.TextOnlyRawData = varargin{1};
            end

            % Use detectImportOptions to create the Text Import Options
            % object which will be used as the basis for the initial import
            % display.
            this.initFile();
            
            if isfield(dataSource, "ImportOptions") && ~isempty(dataSource.ImportOptions)
                this.imopts = dataSource.ImportOptions;
                this.ImportOptionsProvided = true;
            end

            this.initImportOptions();

            % read some data to get a more accurate representation of the column
            % count
            this.initSampleData();

            % close the file after initFile
            fclose(this.FilePointer);

            dblColumns = find(cellfun(@(x) x == "double", this.imopts.VariableTypes));
            if any(dblColumns)
                % Use the decimal separator from the first numeric column
                this.DecimalSeparator = this.imopts.VariableOptions(dblColumns).DecimalSeparator;
            else
                % There's no numeric columns, use '.' as the default decimal
                % separator.
                this.DecimalSeparator = '.';
            end
        end

        function columnTypes = getUnderlyingColumnTypes(this)
            dataPos = this.getSheetDimensions();
            columnTypes = repmat({this.DefaultTextType}, 1, dataPos(4));
        end

        function columnClassOptions = getColumnClassOptions(this)
            if isempty(this.ColumnClassOptions)
                columnClassOptions = this.getColumnClassOptions@internal.matlab.importtool.TabularDataModel();
                % include date formats
                dateColFormats = this.getDateFormats();
                formatIndices = ~cellfun('isempty', dateColFormats);
                columnClassOptions(formatIndices) = dateColFormats(formatIndices);
                % include duration formats
                durationColFormats = this.getDurationFormats();
                formatIndices = ~cellfun('isempty', durationColFormats);
                columnClassOptions(formatIndices) = durationColFormats(formatIndices);
                this.ColumnClassOptions = columnClassOptions;

                if isempty(this.InitialColumnClassOptions)
                    if ~isempty(this.InitialColumnClasses)
                        % Make sure the column class is set for columns which are
                        % datetime or duration columns.
                        dtIdx = this.InitialColumnClasses == "datetime";
                        drIdx = this.InitialColumnClasses == "duration";
                        emptyIdx = cellfun('isempty', columnClassOptions);
                        if any(dtIdx & emptyIdx)
                            columnClassOptions{dtIdx & emptyIdx} = 'default';
                        end
                        if any(drIdx & emptyIdx)
                            columnClassOptions{drIdx & emptyIdx} = 'default';
                        end
                    end
                    this.InitialColumnClassOptions = columnClassOptions;
                end
            end
            columnClassOptions = this.ColumnClassOptions;
        end

        function initImportOptions(this, varargin)
            % Reset the sheet dimensions so it will get recomputed
            this.SheetDimensions = [];
            this.CacheData = containers.Map;
            this.InitialColumnClasses = [];
            this.InitialColumnClassOptions = [];
            this.AddedVars = 0;
            this.ColumnClassOptions = [];

            % Temporarily disable warnings from detectImportOptions.  The
            % warning state will get reverted when the function completes.
            w = warning('off');
            revertWarning = onCleanup(@() warning(w));
            
            if nargin == 1 && ~this.ImportOptionsProvided || nargin > 1
                % Build up the arguments for detectImportOptions.  Need to use a
                % cell array because some argument values may themselves be cell
                % arrays (Delimiter, for example)
                defaultArgs = {'FileType', 'text', 'TextType', 'string', ...
                    'HexType', 'text', 'BinaryType', 'text'};
                if nargin == 1
                    args = defaultArgs;
                else
                    args = varargin;
                    if any(cellfun(@(x) (ischar(x) || isstring(x)) && strcmp(x, "FileType"), args))
                        % input argument supersedes default setting
                        args = [args, {'TextType', 'string'}];
                    else
                        args = [args, defaultArgs];
                    end
                end
                if ~isempty(this.FileEncodingForReadtable)
                    args = [args, 'Encoding', this.FileEncodingForReadtable];
                end
                
                try
                    this.imopts = detectImportOptions(this.FileName, args{:});
                catch
                    % If it fails, just create an empty DelimitedText
                    % Import Options object.
                    this.imopts = delimitedTextImportOptions('NumVariables', 0);
                end
            end
            
            this.FixedWidth = isa(this.imopts, "matlab.io.text.FixedWidthImportOptions");

            if this.FixedWidth
                this.fwIOpts = this.imopts;
            else
                this.delIOpts = this.imopts;
            end

            if (isempty(varargin) && strcmp(this.imopts.Whitespace, '\b') && ...
                    ~this.FixedWidth)
                % ImportOptions has a SpaceAligned mode which sets up multiple
                % delimiters, but the Import Tool only expects one initially.
                % Specifying the delimiter will force a Delimited Import Options
                % object to be created.
                d = this.detectDelimiters();
                if isempty(d)
                    d = {' '};
                end
                args = [args, "Delimiter", d{1}];
                if isequal(d{1}, ' ')
                    args = [args, "ConsecutiveDelimitersRule", "join"];
                end

                % Reinitialize using this delimiter
                this.imopts = this.DetectFcn(this.FileName, args{:});

                this.delIOpts = this.imopts;
            end
            if strcmp(this.imopts.Whitespace, "\b\t")
                this.imopts.Whitespace = '\b';
            end

            if this.FixedWidth
                this.VariableWidths = this.fwIOpts.VariableWidths;
            else
                this.Delimiter = this.imopts.Delimiter;

                if isempty(this.InitialDelimiter)
                    % Save the delimiter which was initially detected
                    this.InitialDelimiter = this.imopts.Delimiter;
                end

                if isequal(this.imopts.Delimiter, {' '})
                    % Set LeadingDelimitersRule to 'ignore' for when space is the
                    % delimiter
                    this.imopts.LeadingDelimitersRule = "ignore";

                    % Set TrailingDelimitersRule to match legacy behavior
                    this.imopts.TrailingDelimitersRule = "ignore";
                else
                    % This is the default, but just locking down the expected
                    % behavior
                    this.imopts.LeadingDelimitersRule = "keep";
                    this.imopts.TrailingDelimitersRule = "keep";
                end
            end

            % Save the detected variable types, for comparison later on.  This
            % should be done after detectImportOptions is called, and before any
            % Import Tool specific detection may change the data types.
            this.DetectedColumnClasses = this.imopts.VariableTypes;

            % Check for any columns which contain text that can be converted to
            % numeric.  For any of these columns, set them to 'double'.  Save
            % the originally detected column types first.
            numericColumns = this.getNumericColumns();

            % Save and reset the lasterror state, which may be set in the
            % setvartype call
            l = lasterror;
            this.imopts = setvartype(this.imopts, numericColumns, "double");
            lasterror(l);
        end

        function initSampleData(this)
            % read some data to get a more accurate representation of the column
            % count
            numCols = this.getColumnCount();
            if numCols > 0
                this.getData(1, min(this.SampleLines, this.getRowCount), 1, numCols, false);
            end

            if ~isequal(numCols, this.getColumnCount())
                % The number of colunns changed. This means that
                % detectImportOptions returned one value, but when we actually
                % read in the data we found more columns.  This is rare -- but
                % call getData one more time to initialize everything correctly
                % with the new number of columns.
                this.getData(1, this.SampleLines, 1, this.getColumnCount(), false);
            end
        end

        function delete(this)
            if ~isempty(this.FilePointer) && this.FilePointer > 2 && ...
                    ~isempty(fopen(this.FilePointer))
                fclose(this.FilePointer);
            end
        end

        function b = isFixedWidth(this)
            b = this.FixedWidth;
        end

        function setFixedWidth(this, isFixedWidth)
            if ~isequal(isFixedWidth, this.FixedWidth)
                this.FixedWidth = isFixedWidth;

                if isFixedWidth
                    this.initImportOptions("FileType", "fixedwidth");
                else
                    this.initImportOptions("FileType", "delimited");
                end
            end
        end

        function varWidths = getVariableWidths(this)
            % Always return the Fixed Width Import Options value
            colCount = this.getColumnCount;
            if this.isFixedWidth
                varWidths = this.fwIOpts.VariableWidths;
                if length(varWidths) < colCount
                    varWidths(end+1:colCount) = NaN;
                    varWidths = fillmissing(varWidths, 'previous');
                end
            else
                varWidths = repmat(this.DefaultVariableWidthInChars, 1, colCount);
            end
        end

        function setVariableWidths(this, varWidths)
            if ~isequal(varWidths, this.VariableWidths)
                this.resetStoredNames();

                this.initImportOptions("VariableWidths", varWidths);
            end
        end

        function enc = getEncodingForReadtable(this)
            enc = this.FileEncodingForReadtable;
        end

        function dims = getSheetDimensions(this)
            if ~isempty(this.SheetDimensions)
                dims = this.SheetDimensions;
                return;
            end

            this.SheetDimensions = [1, this.RowCount, ...
                1, this.getColumnCount()];
            dims = this.SheetDimensions;
        end

        function headerRow = getHeaderRow(this)
            % Use the ImportOptions to get the header row
            if isempty(this.imopts.VariableNamesLine)
                headerRow = 1;
            else
                headerRow = max(this.imopts.VariableNamesLine, 1);
            end
        end

        function delimiter = getDelimiter(this)
            if this.FixedWidth
                delimiter = '';
            else
                % Use the ImportOptions to get the delimiter
                delimiter = this.resolveDelimiter(this.imopts.Delimiter);
            end
        end

        function delimiter = getInitialDelimiter(this)
            if this.FixedWidth
                delimiter = '';
            else
                % Return the initially detected delimiter
                delimiter = this.resolveDelimiter(this.InitialDelimiter);
            end
        end

        function setDelimiter(this, delimiter)
            if ~isequal(delimiter, this.Delimiter)
                this.resetStoredNames();
                this.initImportOptions("Delimiter", delimiter, ...
                    "ConsecutiveDelimitersRule", this.imopts.ConsecutiveDelimitersRule);

                % The number of columns may have changed.  Re-initialize
                % everything by reading in some sample data.
                this.initSampleData();
            end
        end

        function consecutiveDelimRule = getConsecutiveDelimitersRule(this)
            if this.FixedWidth
                % This isn't used for fixed width, so just use the default value
                consecutiveDelimRule = "split";
            else
                % Use the ImportOptions to get the ConsecutiveDelimitersRule
                consecutiveDelimRule = this.imopts.ConsecutiveDelimitersRule;
            end
        end

        function setConsecutiveDelimitersRule(this, rule)
            if ~isequal(this.imopts.ConsecutiveDelimitersRule, rule)
                this.imopts.ConsecutiveDelimitersRule = rule;
                this.resetStoredNames();
                this.initImportOptions("Delimiter", this.imopts.Delimiter, ...
                    "ConsecutiveDelimitersRule", rule);

                % The number of columns may have changed.  Re-initialize
                % everything by reading in some sample data.
                this.initSampleData();
            end
        end

        function dataStartRow = getDataStartRow(this)
            dataStartRow = this.imopts.DataLines(1);
        end

        function columnCount = getColumnCount(this)
            columnCount = length(this.imopts.VariableNames);
            columnCount = columnCount + this.AddedVars;
        end

        function dateColFormats = getDateFormats(this)
            dateCols = cellfun(@(x) x == "datetime", this.imopts.VariableTypes);
            dateColFormats = this.getClassColFormats(dateCols, ...
                @internal.matlab.importtool.server.ImportUtils.getDateFormat);
        end

        function durationColFormats = getDurationFormats(this)
            durationCols = cellfun(@(x) x == "duration", this.imopts.VariableTypes);
            durationColFormats = this.getClassColFormats(durationCols, ...
                @internal.matlab.importtool.server.ImportUtils.getDurationFormat);
        end

        function classColFormats = getClassColFormats(this, classCols, formatFunc)
            dataPos = this.getSheetDimensions();
            dims = [dataPos(2) dataPos(4)];

            if any(classCols)
                testDims(1) = min(dims(1), this.SampleRowCount);
                testDims(2) = min(dims(2), this.SampleColumnCount);
                range = internal.matlab.importtool.server.ImportUtils.toExcelRange(...
                    1, testDims(1), 1, testDims(2));
                [data, raw, ~] = this.getDataFromExcelRange(range, false);
                raw(~isnan(data)) = {''};

                for idx = 1:dims(2)
                    if idx <= length(classCols) && classCols(idx)
                        classFormats = internal.matlab.importtool.server.ImportUtils.getFormatsForCol(strtrim(raw(:,idx)), testDims(1), formatFunc);
                        [words, ~, uniqueIdx] = unique(classFormats);
                        numOccurences = histcounts(uniqueIdx, numel(words));
                        [~, rankIdx] = sort(numOccurences, 'descend');
                        if ~isempty(words{rankIdx(1)})
                            classColFormats{idx} = words{rankIdx(1)};
                        elseif length(rankIdx) > 1
                            classColFormats{idx} = words{rankIdx(2)};
                        else
                            classColFormats{idx} = '';
                        end
                    else
                        classColFormats{idx} = '';
                    end
                end
            else
                classColFormats = repmat({''}, 1, dims(2));
            end
        end

        function numericColumns = getNumericColumns(this)
            import internal.matlab.datatoolsservices.preprocessing.VariableTypeDetectionService;

            % Setup the numeric columns.  Need to handle cases where the data
            % doesn't start at cell A1, so there could be columns prior to the
            % ones that imopts has reported
            dataPos = this.getSheetDimensions();
            numcols = dataPos(4);

            numericColumns = false(1, numcols);
            dblColumns = cellfun(@(x) x == "double", this.imopts.VariableTypes);
            numericColumns(dataPos(3):min(numcols, length(dblColumns))) = dblColumns;

            textCols = cellfun(@(x) x == "char" || x == "string", this.imopts.VariableTypes);
            
            if any(textCols) || any(dblColumns)
                textCols = find(textCols);
                textCols(textCols > this.SampleColumnCount) = [];
                dblColumns = find(dblColumns);
                dblColumns(dblColumns > this.SampleColumnCount) = [];
                dblAndTextCols = sort(horzcat(textCols, dblColumns));
                
                % Need to determine if there are any text columns which appear
                % to contain some numeric data. Read in some sample data to do
                % this.
                dims = [dataPos(2) dataPos(4)];
                testDims(1) = min(dims(1), this.SampleRowCount);
                testDims(2) = min(dims(2), this.SampleColumnCount);
                range = internal.matlab.importtool.server.ImportUtils.toExcelRange(...
                    1, testDims(1), 1, testDims(2));
                [~, raw, ~] = this.getDataFromExcelRange(range, false);

                for col = dblAndTextCols
                    colData = string(raw(:,col));
                    
                    if any(col == textCols)                       
                        % If there are a large number of rows in the file, only
                        % consider a column numeric if all of the sample data is
                        % numeric.  If there is a mix of numeric and non-numeric,
                        % default this column to text.  This results in better
                        % performance later on (so we can do fastpath import)
                        requireAllNumeric = this.RowCount > this.LargeFileRowCount;
                        
                        % Set the column to numeric if a percentage of cells are
                        % numbers with common prefixes and suffixes
                        isNumericCol = VariableTypeDetectionService.isPossibleNumericVector(...
                            colData, this.DecimalSeparator, requireAllNumeric);
                        if (isNumericCol)
                            numericColumns(col) = true;
                        end
                    else
                        isNumericCol = true;
                    end
                    
                    if isNumericCol && isempty(this.ThousandsSeparator) && ...
                            length(find(contains(colData, ","))) > 1
                        % If there are numbers with commas in them, make sure
                        % that the ThousandsSeparate is set, so it ends up being
                        % used during import and code generation
                        this.ThousandsSeparator = ',';
                    end
                end
            end
        end

        function initialSelection = getInitialSelection(this)
            % Returns the initial selection as: [startRow, startCol, endRow,
            % endCol]

            % Setup the initial selection based on the DataRange and
            % HeaderRow in the worksheet.  Don't call getHeaderRow which returns
            % at minimum a value of 1 -- if detectImportOptions detects a header
            % row of 0, we should start the selection on the first row.
            if isempty(this.imopts.VariableNamesLine)
                headerRow = 0;
            else
                headerRow = this.imopts.VariableNamesLine;
            end

            initialRow = max(headerRow + 1, this.imopts.DataLines(1));

            initialSelection = [min(initialRow, this.RowCount), 1, ...
                this.RowCount, length(this.imopts.VariableNames)];
        end

        function allVarNames = getVarNamesForImport(this, columnVarNames, cols)
            % Start with invalid variable names of ["1", "2", ... for all
            % variables].  This way there will be no duplication between these
            % and the user-supplied ones
            numvars = length(this.imopts.VariableNames);
            allVarNames = "Var" + (1:numvars);

            % Make sure the allVarNames aren't one of the column names
            % selected in the file already.
            allVarNames = matlab.lang.makeUniqueStrings(allVarNames, columnVarNames, namelengthmax);

            if ~isempty(columnVarNames)
                % Assign the variable names which was an argument into the right
                % index
                if all(diff(cols) == 1)
                    allVarNames(cols(1):cols(end)) = columnVarNames;
                else
                    for idx = 1:length(cols)
                        allVarNames(cols(idx)) = columnVarNames(idx);
                    end
                end
            end
        end

        function varTypes = getColTypesForImport(this, colTargetTypes, cols)
            % Start out with the user-supplied types, and then fill in with the
            % argument values in the right indices
            varTypes = string(this.imopts.VariableTypes);
            if all(diff(cols) == 1)
                varTypes(cols(1):cols(end)) = colTargetTypes;
            else
                for idx = 1:length(cols)
                    varTypes(cols(idx)) = colTargetTypes(idx);
                end
            end
        end

        function [opts, dataLines] = getImportOptions(this, varargin)
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
                addParameter(p, "VariableWidths", [], @(x) validateattributes(x, ...
                    "double", {'2d'}));
                addParameter(p, "Delimiter", [], @(x) validateattributes(x, ...
                    ["string", "char", "cell"], {}));
                addParameter(p, "ConsecutiveDelimitersRule", [], @(x) validateattributes(x, ...
                    ["string", "char"], {'nonempty'}));
                addParameter(p, "DecimalSeparator", [], @(x) validateattributes(x, ...
                    ["string", "char"], {'scalartext'}));
                addParameter(p, "ThousandsSeparator", [], @(x) validateattributes(x, ...
                    ["string", "char"], {'scalartext'}))
            end
            parse(p, varargin{:})
            args = p.Results;

            [opts, dataLines] = getImportOptionsFromArgs(this, args);
            opts.DataLines = dataLines{1};
        end

        function [opts, dataLines] = getImportOptionsFromArgs(this, args)

            % Create the DelimitedTextImportOptions object
            if this.FixedWidth
                opts = matlab.io.text.FixedWidthImportOptions;
                this.imopts = this.fwIOpts;
            else
                opts = matlab.io.text.DelimitedTextImportOptions;
                this.imopts = this.delIOpts;

                if ~isempty(args.Delimiter)
                    opts.Delimiter = args.Delimiter;
                else
                    opts.Delimiter = this.imopts.Delimiter;
                end

                % Set multiple delimiters rule
                if ~isempty(args.ConsecutiveDelimitersRule)
                    opts.ConsecutiveDelimitersRule = args.ConsecutiveDelimitersRule;
                else
                    opts.ConsecutiveDelimitersRule = this.imopts.ConsecutiveDelimitersRule;
                end

                % This is set to 'ignore' typically when detectImportOptions is
                % called, but is 'keep' when the import options is constructed
                % manually.  Setting it to 'ignore' to mach detection defaults for
                % when space is the delimiter
                if isequal(opts.Delimiter, {' '})
                    opts.LeadingDelimitersRule = "ignore";

                    % Set TrailingDelimitersRule to match legacy behavior
                    opts.TrailingDelimitersRule = "ignore";
                else
                    % This is the default, but just locking down the expected
                    % behavior
                    opts.LeadingDelimitersRule = "keep";
                    opts.TrailingDelimitersRule = "keep";
                end
            end

            % Use readtable to read in the table range
            if ~isempty(this.FileEncodingForReadtable)
                opts.Encoding = this.FileEncodingForReadtable;
            end

            % If the user has chosen to not enforce valid Matlab table variable
            % names, then we need to set the 'PreserveVariableNames' flag in the
            % Import Options object, to allow arbitrary variable names to be
            % passed through.
            if ~this.ValidMatlabVarNames
                opts.PreserveVariableNames = true;
            end

            opts.VariableNames = this.imopts.VariableNames;

            % Setup the Variable Names and types.
            if ischar(args.Range) || isstring(args.Range)
                % There is a single range specified by text, like "A3:D100"
                [~, cols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(args.Range);
                opts.VariableNames = this.getVarNamesForImport(args.ColumnVarNames, cols);
                if ~isempty(args.ColumnVarNames)
                    % Use opts.VariableNames, since this will be the unique
                    % column names, fixed by the Import Options object
                    opts.SelectedVariableNames = opts.VariableNames(cols);
                end

                opts.VariableTypes = this.getColTypesForImport(args.ColumnVarTypes, cols);
            elseif (iscell(args.Range) && length(args.Range{1}) == 1)
                % There may be multiple row ranges, but only a single column
                % range.  Setup the column names and types just like if the
                % range is a char or string.  We can use the first range,
                % because all columns have the same names/types even for
                % different row ranges.
                [~, cols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(args.Range{1}{1});
                opts.VariableNames = this.getVarNamesForImport(args.ColumnVarNames, cols);
                if ~isempty(args.ColumnVarNames)
                    opts.SelectedVariableNames = args.ColumnVarNames;
                end

                opts.VariableTypes = this.getColTypesForImport(args.ColumnVarTypes, cols);
            else
                cols = [];
                for colBlockRange = 1:length(args.Range{1})
                    [~, colBlock] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(args.Range{1}{colBlockRange});
                    cols = [cols colBlock]; %#ok<*AGROW>
                end

                opts.VariableNames = this.getVarNamesForImport(args.ColumnVarNames, cols);
                if ~isempty(args.ColumnVarNames)
                    opts.SelectedVariableNames = args.ColumnVarNames;
                else
                    opts.SelectedVariableNames = opts.VariableNames(cols);
                end

                opts.VariableTypes = this.getColTypesForImport(args.ColumnVarTypes, cols);
            end

            if this.FixedWidth
                if ~isempty(args.VariableWidths)
                    len = length(args.VariableWidths);
                    opts.VariableWidths(1:len) = args.VariableWidths;
                else
                    opts.VariableWidths = this.getVariableWidths;
                end
            end

            % For most files, the VariableTypes and ColumnVarTypeOptions will be the same
            % length.  But they can differ for files in which the Import Tool discovers 
            % additional columns.  When this happens, the args.ColumnVarTypeOptions will
            % contain only the first N columns (up to the discovered ones) if the user
            % doesn't select them for import, so we can just use this set of options.
            if isempty(args.ColumnVarTypeOptions)
                columnVarTypeOptions = {};
            elseif length(opts.VariableTypes) == length(args.ColumnVarTypeOptions)
                columnVarTypeOptions = cellstr(args.ColumnVarTypeOptions);
            else
                typeOptions = cell(size(opts.VariableTypes));
                typeOptions(cols) = cellstr(args.ColumnVarTypeOptions(cols));
                columnVarTypeOptions = typeOptions;
            end

            % disable any warnings coming from the datetime constructor. It will
            % try to warn for ambiguous formats which we may not care about.
            s = warning('off', 'all');

            % Setup the variable type options
            optionColumns = ~cellfun(@isempty, columnVarTypeOptions);
            for column = find(optionColumns)
                if any(cols == column)
                    dataType = opts.VariableTypes{column};
                    typeOption = columnVarTypeOptions{column};
                    importOptions = internal.matlab.importtool.server.ImportToolColumnTypes.getColumnImportOptions(dataType, typeOption);
                    if isstruct(importOptions)
                        if strcmp(dataType, "datetime")
                            importOptions.DatetimeFormat = 'preserveinput';
                        end

                        % getColumnImportOptions will return a struct with the
                        % property and value to set in the import options object if
                        % it is a valid property for that column type.
                        fields = fieldnames(importOptions);
                        values = struct2cell(importOptions);
                        for j = 1:length(fields)
                            opts = setvaropts(opts, column, fields{j}, values{j});
                        end
                    end
                end
            end

            warning(s);

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

            % Handle prefix/suffix.  Trim any columns set to numeric that were
            % not initially numeric.

            % always update the InitialColumnClasses and options since they will
            % change after you set the new delimiter
            this.InitialColumnClasses = this.getColumnClasses();
            this.InitialColumnClassOptions = this.getColumnClassOptions();

            colsToTrim = this.getTrimNonNumericCols(opts.VariableTypes);
            if any(colsToTrim)
                opts = setvaropts(opts, colsToTrim, "TrimNonNumeric", true);
            end

            if any(doubleColumns)
                if ~isempty(args.DecimalSeparator)
                    decimalSeparator = args.DecimalSeparator;
                else
                    decimalSeparator = this.DecimalSeparator;
                end
                opts = setvaropts(opts, doubleColumns, ...
                    "DecimalSeparator", decimalSeparator);

                if ~isempty(args.ThousandsSeparator)
                    thousandsSeparator = args.ThousandsSeparator;
                else
                    thousandsSeparator = this.ThousandsSeparator;
                end
                if any(colsToTrim) && isempty(thousandsSeparator)
                    thousandsSeparator = this.DefaultThousandsSeparator;
                end
                if any(colsToTrim) && ~isempty(thousandsSeparator)
                    opts = setvaropts(opts, colsToTrim, ...
                        "ThousandsSeparator", thousandsSeparator);
                elseif any(doubleColumns) && ~isempty(thousandsSeparator)
                    % Also set the thousands separator if there are double
                    % columns, and the thousands separator was detected
                    % previously
                    opts = setvaropts(opts, doubleColumns, ...
                        "ThousandsSeparator", thousandsSeparator);
                end
            end

            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";

            dataLines = {};
            if ischar(args.Range) || isstring(args.Range)
                % There's just a single range specified by the text only
                dataRangeRows = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(args.Range);
                if dataRangeRows(end) == this.RowCount
                    dataLines = {[dataRangeRows(1), inf]};
                else
                    dataLines = {[dataRangeRows(1), dataRangeRows(end)]};
                end

            else
                for rowBlockRange = 1:length(args.Range)
                    firstRange = args.Range{rowBlockRange}{1};
                    [dataRangeRows, ~] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(firstRange);
                    if dataRangeRows(end) == this.RowCount
                        dataLines = [dataLines {[dataRangeRows(1), inf]}];
                    else
                        dataLines = [dataLines {[dataRangeRows(1), dataRangeRows(end)]}];
                    end
                end
            end
        end

        function [varNames, vars] = ImportData(this, opts, varargin)
            persistent p;
            if isempty(p)
                p = inputParser;
                addParameter(p, "VarNames", "", @(x) validateattributes(x, ...
                    ["string", "char", "cell"], {'nonempty'}));
                addParameter(p, "OutputType", "", @(x) validateattributes(x, ...
                    "internal.matlab.importtool.server.output.OutputType", {'scalar'}));
                addParameter(p, "DataLines", strings(0), @(x) validateattributes(x, ...
                    ["double", "cell"], {'nonempty'}));
            end
            parse(p, varargin{:})
            args = p.Results;

            if isempty(args.DataLines)
                args.DataLines = {opts.DataLines};
            end

            % Get the read* function to use for importing.  This could be
            % readtable, readmatrix, readttimetable, etc...
            readFcn = args.OutputType.getImportFunction();
            opts = args.OutputType.updateImportOptionsForOutputType(opts);
            additionalArgs = args.OutputType.getAdditionalArgsForImportFcn();
            
            dataLines = [args.DataLines{:}];
            if numel(dataLines) > 2
                dataLines = reshape(dataLines, [], length(args.DataLines))';
            end
            opts.DataLines = dataLines;

            % Temporarily turn off this warning
            w = warning('off', 'MATLAB:readtable:AllNaTVariable');
            
            if isempty(additionalArgs)
                t = readFcn(this.FileName, opts);
            else
                t = readFcn(this.FileName, opts, additionalArgs{:});
            end
            
            % Revert warning state
            warning(w);

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

        function bomLength = getEncodingBOMLength(this)
            bomLength = this.EncodingBOMLength;
        end

        function rowCount = getRowCount(this)
            rowCount = this.RowCount;
        end

        function emptyRowCount = getEmptyRowCount(this)
            emptyRowCount = this.EmptyRowCount;
        end

        function fileEncoding = getFileEncodingForReadtable(this)
            fileEncoding = this.FileEncodingForReadtable;
        end

        function fileEncoding = getFileEncoding(this)
            fileEncoding = this.FileEncoding;
        end

        function byteCount = getByteCount(this)
            byteCount = this.ByteCount;
        end

        function decimalSeparator = getDecimalSeparator(this)
            decimalSeparator = this.DecimalSeparator;
        end

        function decimalSeparator = getThousandsSeparator(this)
            decimalSeparator = this.ThousandsSeparator;
        end

        function setDecimalSeparator(this, decimalSeparator)
            if ~isequal(this.DecimalSeparator, decimalSeparator)
                this.DecimalSeparator = decimalSeparator;

                if decimalSeparator == this.DefaultThousandsSeparator
                    % switch the thousands separator to ".", since both it can't be
                    % the same as the decimal separator.
                    this.ThousandsSeparator = ".";
                else
                    this.ThousandsSeparator = this.DefaultThousandsSeparator;
                end

                this.initImportOptions("Delimiter", this.imopts.Delimiter, ...
                    "DecimalSeparator", decimalSeparator);
            end
        end

        function sampleData = getSampleData(this)
            import internal.matlab.importtool.server.ImportUtils;

            if isempty(this.SampleData)
                this.SampleData = ImportUtils.getTextFileSampleContent(...
                    this.FileName, this.SampleLines);
            end

            sampleData = this.SampleData;
        end

        % Find all the potential delimiters in the file by analyzing the
        % sample data
        function [delimiters, count] = findDelimiters(this)
            [delimiters, count] = this.detectDelimiters();
            if ~this.isFixedWidth
                % Make sure the delimiter detected by detectImportOptions is one
                % of the delimiters that shows up in the delimiters dropdown
                for idx = 1:length(this.imopts.Delimiter)
                    if ~any(contains(delimiters, this.imopts.Delimiter{idx}))
                        additionalDelimiter = this.imopts.Delimiter(idx);
                        if isequal(additionalDelimiter, {'\t'})
                            additionalDelimiter = {sprintf('\t')};
                        end
                        delimiters(end + 1) = additionalDelimiter;
                        count(end + 1) = 0;
                    end
                end
            end
        end

        function columnNames = getColumnNames(this, row, avoidShadow, varargin)
            addedVars = this.AddedVars;
            if ~isempty(varargin)
                columnNames = this.getDefaultColumnNames(row, avoidShadow, varargin{:});
            else
                columnNames = this.getDefaultColumnNames(row, avoidShadow);
            end
            
            this.AddedVars = addedVars;

            dataPos = this.getSheetDimensions();
            numColNames = size(columnNames);

            if numColNames(2) ~= dataPos(4)
                % get the difference in length
                diffLength = dataPos(4) - numColNames(2);
                columnNames(end+1:end+1+diffLength-1) = "Var";
                columnNames = matlab.lang.makeUniqueStrings(columnNames);
            end
        end
    end

    methods (Access = protected)

        function out = read(this, range, asDatetime)
            if (~this.HasFile)
                error(message('MATLAB:codetools:NoFileOpen'));
            end

            validateattributes(range, {'char'}, {});

            % Save and reset the lasterror state, which may be set in the
            % process of calling setvartype.
            l = lasterror; %#ok<*LERR>

            % Use the right import options (delimited or fixed width)
            if this.FixedWidth
                currImOpts = this.fwIOpts;
            else
                currImOpts = this.imopts;
            end
            currImOpts.SelectedVariableNames = currImOpts.VariableNames;

            % Use readtable to read in the range of data from the specified file
            % Call readtable to get numeric and datetime data first.  We
            % need this to show 'replacement values' in the UI
            datetimeCols = cellfun(@(x) x == "datetime", currImOpts.VariableTypes);

            localImopts = setvartype(currImOpts, find(~datetimeCols), "double");

            lasterror(l);

            % Adjust the Variable Names being read so that the range can be
            % set accordingly
            [rows, cols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(range);
            numvars = length(localImopts.VariableNames) + this.AddedVars;

            % Reset the dimensions so it will be recomputed with the new added
            % variables
            this.SheetDimensions = [];

            if numvars == 0
                localImopts.VariableNames = "Var1";
            elseif length(cols) > numvars
                tmpVarNames = repmat("VarName", size(cols));
                tmpVarNames(1:length(localImopts.VariableNames)) = localImopts.VariableNames;
                localImopts.VariableNames = cellstr(matlab.lang.makeUniqueStrings(tmpVarNames));
                localImopts.SelectedVariableNames = localImopts.VariableNames;
            elseif length(cols) < length(localImopts.VariableNames)
                endCol = min(cols(end), length(localImopts.VariableNames));
                localImopts.SelectedVariableNames = localImopts.VariableNames(cols(1):endCol);
            end
            localImopts.DataLines = [rows(1), rows(end)];

%             localImopts.ExtraColumnsRule = 'ignore';
            localImopts.EmptyLineRule = "read";

            w = warning('off');
            revertWarning = onCleanup(@() warning(w));

            tb = readtable(this.FileName, localImopts);
            rawData = table2cell(tb);

            % Account for any additional variables which were found.  Go with
            % the max of the newly found AddedVars and the existing AddedVars,
            % so the value never goes down for a given file.  (It's possible
            % that scrolling to a new position in the file yields a different
            % value, but we know the file contained it previously)
            this.AddedVars = max(length(tb.Properties.VariableNames) - length(localImopts.VariableNames), ...
                this.AddedVars);

            % Data will be the numeric data in the text file
            idx = cellfun(@isnumeric, rawData);
            data = rawData;
            data(~idx) = {nan};
            data = cell2mat(data);

            % remove complex numbers from import
            data(logical(imag(data))) = NaN;

            % raw is a cell array containing numbers for numeric values,
            % and the text for any non-numeric valuies.  We need to call
            % readtable again to get the text values for columns which may
            % be mixed (or for header values, for example).   Save and reset the
            % lasterror state, which may be set in the process of calling
            % setvartype.
            l = lasterror;
            opts = setvartype(localImopts, 'char');
            opts = setvaropts(opts, 'WhitespaceRule', 'preserve');
            lasterror(l);
            opts.DataLines = [rows(1), rows(end)];
%             opts.ExtraColumnsRule = 'ignore';
            data2 = readtable(this.FileName, opts);
            raw2 = table2cell(data2);

            % Find nans and datetimes from the initial rawData
            nanIdx = cellfun(@(x) (isnumeric(x) && isnan(x)) || isdatetime(x), rawData);
            datetimeIdx = cellfun(@(x) isdatetime(x) && ~isnat(x), rawData);

            % readtable treats the letters i and j as complex data, which is
            % fine, but we can't pass complex data back to the clients.  For
            % now, convert this to NaN.
            iIdx = cellfun(@(x) ~isempty(x), regexp(raw2, '(\d*j$)|(\d*i$)'));
            data(iIdx) = nan;

            % Save the space-padded raw, with all columns padded to the same
            % width
            spacedPaddedRaw = raw2;
            for idx=1:size(raw2, 2)
                spacedPaddedRaw(:,idx) = pad(raw2(:,idx));
            end

            if this.TextOnlyRawData
                raw = raw2;
            else
                combinedIdx = nanIdx | iIdx;
                raw = rawData;
                raw(combinedIdx) = raw2(combinedIdx);
            end

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

            out.data = data;
            out.raw = raw;
            out.dateData = dateData;
            out.spacedPaddedRaw = spacedPaddedRaw;
        end

        function delimiter = resolveDelimiter(~, delimiter)
            if isequal(delimiter, {'\t'})
                delimiter = {sprintf('\t')};
            end
        end

        %
        % From TextFileImporter
        %


        function initFile(this)
            % Refresh the RowCount and other fixed file parameters (which
            % do not depend on UI settings like delimiters and fixed width
            % positions)
            frewind(this.FilePointer);

            % First read a few characters from the file to see if it contains
            % a Byte Order Mark (BOM).  If this exists, its an indication as to
            % the encoding of the file.
            this.FileEncoding = '';
            ch = fread(this.FilePointer, 10, '*uchar');
            [this.FileEncoding, this.EncodingBOMLength, this.FileEncodingForReadtable] = ...
                this.checkFileEncoding(ch);
            if isempty(this.FileEncodingForReadtable)
                frewind(this.FilePointer);
            else
                % Reopen the file with the encoding determined from the BOM.
                fclose(this.FilePointer);
                this.FilePointer = fopen(char(this.FileName), 'r', 'n', ...
                    this.FileEncodingForReadtable);
            end

            chunksize = 1e6; % read chunks of 1MB at a time
            byteCount = 0;

            numlfs = 0;
            numcrs = 0;
            numdupcrs = 0;
            numduplfs = 0;
            numcrlfs = 0;
            windowsLineBreaks = false;
            macLineBreaks = false;
            linuxLineBreaks = false;
            lastChar = ' ';
            while ~feof(this.FilePointer)
                ch = fread(this.FilePointer, chunksize, '*uchar');
                if isempty(ch)
                    break
                end

                unicodeCh = [];
                if this.IsCJK
                    unicodeCh = native2unicode(ch); %#ok<N2UNI>
                end

                if macLineBreaks
                    Icr = (ch == newline);
                    numcrs = numcrs + sum(Icr);
                elseif linuxLineBreaks
                    Ilf = (ch == sprintf('\r'));
                    numlfs = numlfs + sum(Ilf);
                elseif windowsLineBreaks
                    Icr = (ch == newline);
                    Ilf = (ch == sprintf('\r'));
                    numcrs = numcrs + sum(Icr);
                else
                    Icr = (ch == newline);
                    Ilf = (ch == sprintf('\r'));
                    numcrs = numcrs + sum(Icr);
                    numlfs = numlfs + sum(Ilf);
                end

                % Detect the presence of null characters so that they can
                % be replaced by spaces (as they are in the command
                % window). This prevents java interpreting null chars as
                % line breaks.
                if ~this.NullCharsExist && any(ch == 0)
                    this.NullCharsExist = true;
                end

                % Detect the presense of half-width characters
                % (0x0021 <= c && c <= 0x00FF) ||
                % (0xFF61 <= c && c <= 0xFFDC) ||
                % (0xFFE8 <= c && c <= 0xFFEE);
                if this.IsCJK && ~this.HalfWidthCharsExist && ...
                        any((21 <= unicodeCh & unicodeCh <= 255) | (65377 <= unicodeCh & unicodeCh <= 65500) | (65512 <= unicodeCh & unicodeCh <= 65518))
                    this.HalfWidthCharsExist = true;
                end

                % Detect the presense of full-width characters
                if this.IsCJK && ~this.FullWidthCharsExist && ...
                        any((255 < unicodeCh & unicodeCh < 65377) | (65500 < unicodeCh & unicodeCh < 65512) | (65518 < unicodeCh))
                    this.FullWidthCharsExist = true;
                end

                if ~windowsLineBreaks && ~linuxLineBreaks && ~macLineBreaks
                    if numcrs>=2 && numlfs==0
                        macLineBreaks = true;
                    elseif numcrs==0 && numlfs>=2
                        linuxLineBreaks = true;
                    elseif numcrs>=2
                        windowsLineBreaks = true;
                    end
                end

                % If the platform type is undefined there can only have
                % been at most 1 lf or cr, so there are no
                % repetitions.
                if macLineBreaks
                    numdupcrs = numdupcrs + sum(Icr(2:end) & Icr(1:end-1));
                    if lastChar==ch(end) && ch(1)==newline && lastChar==newline
                        numdupcrs = numdupcrs+1;
                    end
                elseif linuxLineBreaks
                    numduplfs = numduplfs + sum(Ilf(2:end) & Ilf(1:end-1));
                    if lastChar==ch(end) && ch(1)==sprintf('\r') && lastChar==sprintf('\r')
                        numduplfs = numduplfs+1;
                    end
                elseif windowsLineBreaks
                    numcrlfs = numcrlfs + sum(Ilf(2:end) & Icr(1:end-1));
                    if lastChar==newline && ch(1)==sprintf('\r')
                        numcrlfs = numcrlfs+1;
                    end
                end
                lastChar = ch(end);
                byteCount = byteCount+length(ch);
            end

            if macLineBreaks
                % If the last char is not a new line there is an additional row
                numlines = numcrs + (~Icr(end));
                emptylines = numdupcrs;
            elseif linuxLineBreaks
                % If the last char is not a lf there is an additional row
                numlines = numlfs + (~Ilf(end));
                emptylines = numduplfs;
            elseif windowsLineBreaks
                % If the last char is not a new line there is an additional row
                numlines = numcrs + (~Icr(end));
                emptylines = numcrlfs;
            else
                numlines = max(numcrs+(~Icr(end)),numlfs+(~Ilf(end)));
                emptylines = 0;
            end

            frewind(this.FilePointer);
            this.EmptyRowCount = emptylines;
            this.ByteCount = byteCount;
            this.RowCount = numlines; %-emptylines;
        end

        function [fileEncoding, encodingLength, encodingForFopen] = ...
                checkFileEncoding(~, ch)
            fileEncoding = [];
            encodingForFopen = [];
            encodingLength = 0;

            % Check for the existence of a Byte Order Mark (BOM) at the
            % beginning of the file.  If it is defined, it will indicate
            % the file encoding to be used for this file.
            utf8BOM = hex2dec({'EF'; 'BB'; 'BF'});
            utf16LEBOM = hex2dec({'FF'; 'FE'});
            utf16BEBOM = flipud(utf16LEBOM);
            utf32LEBOM = hex2dec({'FF'; 'FE'; '00'; '00'});
            utf32BEBOM = flipud(utf32LEBOM);

            % Check for BOM.  Note that the order of the checks is important
            % once other encoding supported is added (utf-16 BOM is a subset of
            % utf-32 BOM.  In the past, some encodings were not supported, so
            % UTF-8 was returned as the supported encoding, but now all
            % encodings detected with a BOM are supported.  
            bom = {utf8BOM, utf32LEBOM, utf32BEBOM, utf16LEBOM, utf16BEBOM};
            encodings = {'UTF-8', 'UTF32-LE', 'UTF32-BE', 'UTF16-LE', 'UTF16-BE'};
            supportedEncodings = {'UTF-8', 'UTF32-LE', 'UTF32-BE', 'UTF16-LE', 'UTF16-BE'};
            for i=1:length(bom)
                if length(ch) >= length(bom{i}) && ...
                        isequal(ch(1:length(bom{i})), bom{i})
                    fileEncoding = encodings{i};
                    encodingLength = length(bom{i});
                    encodingForFopen = supportedEncodings{i};
                    break;
                end
            end
        end


        %
        % End From TextFileImporter
        %

        function [delimiters, count] = detectDelimiters(this)
            sampleData = this.getSampleData;

            % Regular expression defines:
            % Any char one or more times (lazy) followed by a delimiter
            % (non-alphanumeric/quote) one or more times, followed by any
            % char one or more times (lazy),followed by the same delimiter,
            % followed by any character one or more times (lazy), followed
            % by the same delimiter
            tokens = regexp(sampleData,'.+?([^a-zA-Z0-9''"]+).+?\1.+?\1.*?','tokens');
            delimiters = {};
            for k=1:length(tokens)
                if iscell(tokens{k})
                    delimiters = [delimiters cellfun(@(x) x{:},tokens{k},'UniformOutput',false)];
                end
            end
            [delimiters,~,I] = unique(delimiters,'legacy');

            % Limit the delimiters to reasonably sized ones (longer ones
            % are more than likely not valid choices)
            largeDelimiters = cellfun('length', delimiters) > this.SuggestedDelimMaxLength;
            delimiters(largeDelimiters) = [];

            count = diff([0 find(diff([sort(I) max(I)+1]))]);
            count(largeDelimiters) = [];
        end
    end
end
