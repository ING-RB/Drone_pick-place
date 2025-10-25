% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is the abstract base class for tabular file-specific importer
% functionality in the Import Tool

% Copyright 2022-2024 The MathWorks, Inc.

classdef TabularFileImporter < internal.matlab.importtool.server.Importer

    properties
        % Import Options for the import
        importOptions;

        % Table Identifier.  May be just the filename if there is only one table
        % supported, or a sheet or table name for when multiple tables are
        % supported
        TableIdentifier (1,1) string

        % Whether this file type supports multiple tables or not
        HasMultipleTables (1,1) logical = false;

        % The list of tables for the given file
        TableList string

        UseNumericVarNames (1,1) logical = false;
    end

    properties (Access = {?internal.matlab.importtool.server.Importer, ?matlab.unittest.TestCase})
        SheetDimensions;
        ImportOptionsProvided (1,1) logical = false;
        ValidMatlabVarNames (1,1) logical= true;
        DetectedColumnClasses
        CurrentVarNamesRow (1,1) double = 0;
        CurrentArbitraryVariableNames = strings(0);
        CurrentValidVariableNames = strings(0);
        InitialColumnNames;
        InitialColumnClasses;
        InitialColumnClassOptions;
        CurrentIsValidMatlabVarNames (1,1) logical= true;
        DefaultTextType = 'string';
        FillInColsAtStart (1,1) logical = false;
        SupportsTrimNonNumeric (1,1) logical = false;
        DataChangeListener;
        ViewType (1,1) string;

        % For arbitrary variable names, if the file type contains exact text of
        % column names, they should not be stripped.  However, some file types
        % are more generic and may typically have spaces (like a CSV file which
        % has "Col1, Col2, Col3"), where the spaces should be stripped.
        StripSpacesFromNames (1,1) logical = false;
        
        RawTextAtStart = strings(0);
        CurrentVarShadowSettings;
    end

    properties (Hidden)
        CacheData;
        OriginalOpts
    end

    properties (Constant, Access = protected)
        SampleRowCount = 100;
        SampleColumnCount = 1000;
        SampleLines = 100;
        UIBlockColumnCount = 64;
    end

    properties (Access = {?internal.matlab.importtool.server.Importer, ?matlab.unittest.TestCase})
        % These are used to increase blocks of data read in at a time
        COL_BLOCK_NUM (1,1) double = 100;
        ROW_BLOCK_NUM (1,1) double = 500;
        ROUND_DIGITS = -2;
        LARGE_ROW_RANGE (1,1) double = 500;
        LARGE_COL_RANGE (1,1) double = 250;
    end

    properties(Access = private)
        ColumnNamesReset = false;
    end

    methods(Abstract, Access = public)
        % Import the data
        [varNames, vars] = importData(this, opts, varargin)

        % Generate a script
        [code, codeGenerator, codeDescription] = generateScriptCode(this, opts, NameValueArgs);

        % Generate a function
        [code, codeGenerator] = generateFunctionCode(this, opts, NameValueArgs);

        % Read data for the given range
        output = read(this, range, asDatetime)

        % Get the column types
        columnTypes = getUnderlyingColumnTypes(this);

        % Get the sheet dimensions
        dims = getSheetDimensions(this)

        % Get the header row
        headerRow = getHeaderRow(this)

        % Get the date formats
        dateColFormats = getDateFormats(this)

        % Get the initial selection
        initialSelection = getInitialSelection(this)

        % Get the column class options
        columnClassOptions = getColumnClassOptions(this)

        % Get the import options that can be used for importing
        [opts, dataRanges] = getImportOptions(this, varargin)

        % Get the column count
        columnCount = getColumnCount(this)

        % Get the column names
        columnNames = getColumnNames(this, row, avoidShadow, varargin)

        % Add in additional import data fields
        s = addAdditionalImportDataFields(this, currImportDataStruct)

        % Get the converted datetime value
        interpreted = getConvertedDatetimeValue(this, importOptions, data, raw)

        % Get the default variable output name
        varOutputName = getDefaultVariableOutputName(this)
    end

    methods
        function this = TabularFileImporter(dataSource)
            arguments
                dataSource = struct();
            end

            this@internal.matlab.importtool.server.Importer(dataSource);

            this.CacheData = containers.Map;
        end

        function initColumnNames(this)
            headerRow = this.getHeaderRow();
            % avoidShadow is used to avoid creating column names as
            % workspace variables which coincide with existing matlab
            % functions
            avoidShadow = struct('isAvoidSomeShadows', true, 'isAvoidAllShadows', false);
            this.getDefaultColumnNames(headerRow, avoidShadow);

            % Call again to init arbitrary variable names
            this.ValidMatlabVarNames = false;
            this.getDefaultColumnNames(headerRow, avoidShadow);
            this.ValidMatlabVarNames = true;
        end

        function columnClasses = getColumnClasses(this)
            colClasses = this.importOptions.VariableTypes;
            dataPos = this.getSheetDimensions();
            numColClasses = size(colClasses);

            % check if the length of the column classes returned is the same as
            % the number of columns if not then the data does not start from the
            % first column fill out the missing column class info with 'string'
            if numColClasses(2) ~= dataPos(4)
                columnClasses = cell(1, dataPos(4));
                % get the difference in length
                diffLength = dataPos(4) - numColClasses(2);

                if this.FillInColsAtStart
                    columnClasses(1:diffLength) = {this.DefaultTextType};
                    columnClasses(diffLength + 1:end) = colClasses;
                else
                    columnClasses = colClasses;
                    columnClasses(end+1:end+1+diffLength-1) = {this.DefaultTextType};
                end
            else
                columnClasses = colClasses;
            end

            % By default, categorical columns are also returned as string.
            % Replace them with the correct datatypes
            categoricalColumns = this.getCategoricalColumns;
            columnClasses(categoricalColumns) = {'categorical'};

            % The Import Tool doesn't handle logicals.  Treat these as doubles.
            logicalColumns = cellfun(@(x) x == "logical", columnClasses);
            columnClasses(logicalColumns) = {'double'};

            if isempty(this.InitialColumnClasses)
                this.InitialColumnClasses = columnClasses;
            end
        end

        function [data, raw, dateData, cachedData, rowRange, colRange] = getData(this, startRow, endRow, startCol, endCol, asDatetime)
            % Get data from the text file for the given range specified by row
            % and column
            newRange = this.getRange(startRow, endRow, startCol, endCol);
            if nargin < 6
                % Unless explicitly set as an argument, dates will be returned
                % as text rather than datetime objects.
                asDatetime = false;
            end
            [data, raw, dateData, cachedData, rowRange, colRange] = this.getDataFromRangeStruct(newRange, asDatetime);
        end

        function [data, raw, dateData, cachedData, rowRange, colRange] = getDataFromExcelRange(this, excelRange, asDatetime)
            % Get data from the text file for the given range specified by Excel
            % range, like 'A1:D100'
            newRange = this.getRange(excelRange);
            if nargin <= 2
                % Unless explicitly set as an argument, dates will be returned
                % as text rather than datetime objects.
                asDatetime = false;
            end
            [data, raw, dateData, cachedData, rowRange, colRange] = this.getDataFromRangeStruct(newRange, asDatetime);
        end

        function colsToTrim = getTrimNonNumericCols(this, currVarTypes)
            % Returns the columns that will be set to "TrimNonNumeric".  I went
            % back and forth on the logic for this setting, since it isn't user
            % selectable, but in the end we decided to have it set to true for
            % columns which detectImportOptions did not detect as numeric, but
            % that either the Import Tool's logic to look for prefixes/suffices,
            % or the user has set them to be numeric.
            %
            % currVarTypes can be passed in, or will be taken as the current
            % ImportOptions.VariableTypes property.
            if nargin < 2
                currVarTypes = this.importOptions.VariableTypes;
            end
            doubleColumns = cellfun(@(x) x == "double", currVarTypes);
            initialNonDoubleCols = ~cellfun(@(x) x == "double", this.DetectedColumnClasses);

            % It's possible that the current number of columns is different than
            % the originally detected number of columns, because sometimes once
            % we read in the data, additional columns are found.  Any of these
            % newly found columns are considered to be text, so just fill in the
            % non-double columns to be true and the double columns to be false.
            initialNonDoubleCols(end+1:end+(length(doubleColumns)-length(initialNonDoubleCols))) = true;
            doubleColumns(end+1:end+(length(initialNonDoubleCols)-length(doubleColumns))) = true;

            colsToTrim = doubleColumns & initialNonDoubleCols;
        end

        function columnNames = getDefaultColumnNames(this, row, avoidShadow, varargin)
            import internal.matlab.importtool.server.ImportUtils;

            this.CurrentVarShadowSettings = avoidShadow;
            data = [];
            if this.CurrentVarNamesRow == row
                if this.ValidMatlabVarNames
                    data = this.CurrentValidVariableNames;
                else
                    data = this.CurrentArbitraryVariableNames;
                end
            else
                this.resetStoredNames()
            end

            if isempty(data)
                % Would like to use detectImportOptions... but no way to specify the
                % range for the variable names in the constructor.  This also would
                % change the default variable names generated by the Import Tool,
                % since detectImportOptions has a different algorithm for generating
                % variable names from invalid data.
                dataPos = this.getSheetDimensions();

                if ~isempty(this.RawTextAtStart) && size(this.RawTextAtStart, 2) == dataPos(4) && ...
                        size(this.RawTextAtStart, 1) >= row
                    % If we have the RawTextAtStart, and it includes the row,
                    % reference it directly.
                    data = this.RawTextAtStart(row, :);
                else
                    % Otherwise read in the data for that row.  (This only
                    % causes a read from the file if the user selects a row out
                    % of the initial view, otherwise this is already cached).
                    range = char(ImportUtils.toExcelRange(row, row, 1, dataPos(4)));
                    newRange = this.getRange(range);
                    newRange.fromClient = false;
                    [~, data] = this.getDataFromRangeStruct(newRange, false);
                end

                % Check if data is not a viable header name row.
                % A viable header row is only if they data is not all empty
                % or all numeric, i.e. we want to use the data as header
                % names only if it is text data. 
                if ~this.UseNumericVarNames 
                    if ~(all(cellfun(@(x) isempty(x) || isnumeric(x), data)))
                        data = data(:)';
                    else
                        data = "";
                    end
                else 
                    data = cellfun(@num2str, data, "UniformOutput", false);
                end

                % The data must be of size equal to the number of columns
                % for the column names to be correctly set
                if size(data,2) ~= dataPos(4)
                    data(length(data)+1:dataPos(4)) = {''};
                end
            end

            % Variable names can be optional varargin.  (Depending on the call
            % stack, the variables in 'caller' may not be what we want).
            if nargin == 4
                varNames = varargin{1};
            else
                varNames = evalin('caller', 'who');
            end
            if avoidShadow.isAvoidSomeShadows && ~this.ValidMatlabVarNames
                % For tables, where the user is not enforcing valid matlab
                % names, and arbitrary names are supported
                columnNames = ImportUtils.getArbitraryColumnNames(data, ...
                    this.StripSpacesFromNames, false);
                this.CurrentArbitraryVariableNames = columnNames;
            else
                columnNames = ImportUtils.getDefaultColumnNames(...
                    varNames, data, -1, avoidShadow, false);
                this.CurrentValidVariableNames = columnNames;
            end
            if isempty(this.InitialColumnNames)
                this.InitialColumnNames = columnNames;
            end

            this.CurrentVarNamesRow = row;
            this.CurrentIsValidMatlabVarNames = this.ValidMatlabVarNames;
        end

        function resetStoredNames(this)
            this.CurrentValidVariableNames = strings(0);
            this.CurrentArbitraryVariableNames = strings(0);
            this.ColumnNamesReset = true;
        end

        function [data, raw, dateData] = updateDisplayContent( ...
                this, data, raw, dateData, cachedData, rowRange, colRange) %#ok<INUSD> 
        end
    end

    methods(Access = protected)
        function [data, raw, dateData, cachedData, rowsFromCache, colsFromCache] = ...
                getDataFromRangeStruct(this, newRange, asDatetime)
            key = newRange.excelRange;
            rowsFromCache = [];
            colsFromCache = [];

            if isKey(this.CacheData, key)
                cachedData = this.CacheData(key);
                data = cachedData.data;
                raw = cachedData.raw;
                dateData = cachedData.dateData;
            else
                % No exact match, but check if the requested range is contained
                % in the cacheData
                dataFound = false;
                k = keys(this.CacheData);
                dim = this.getSheetDimensions;

                % This is a special case for Java Import Tool performance.  The
                % Java Import Tool always requests a block of at least 64
                % columns, even if there aren't that many columns in the file.
                % But it expects only up to the number of columns in the file.
                % So if the request is to have 64 columns, but there aren't that
                % many columns, just look for the range up to the actual number
                % of columns.
                if isempty(newRange.endCol) || (newRange.endCol == this.UIBlockColumnCount && newRange.endCol > dim(4))
                    newRange.endCol = dim(4);
                    if isempty(newRange.startCol)
                        newRange.startCol = 1;
                    end
                end

                for idx = 1:length(k)
                    mapKey = k{idx};
                    [cacheRows, cacheCols] = ...
                        internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(mapKey);
                    cachedData = this.CacheData(mapKey);

                    % If the cache contains the specified rows and columns, then
                    % reuse it and return the specified range.
                    if cacheRows(1) <= newRange.startRow && ...
                            cacheRows(end) >= newRange.endRow && ...
                            cacheCols(1) <= newRange.startCol && ...
                            cacheCols(end) >= newRange.endCol && ...
                            cachedData.asDatetime == asDatetime

                        try
                            [data, raw, dateData, rowsFromCache, colsFromCache] = this.getDataFromCachedDataRange( ...
                                cachedData, cacheRows, cacheCols, newRange, dim);
                            dataFound = true;
                        catch
                        end
                        break;
                    end
                end

                if ~dataFound
                    internal.matlab.datatoolsservices.logDebug("it", "Data not cached: " + newRange.excelRange);
                    % data wasn't found, try to read in a larger block than
                    % requested to help make scrolling less choppy

                    if newRange.fromClient && (newRange.endRow - newRange.startRow > this.LARGE_ROW_RANGE || ...
                            newRange.endCol - newRange.startCol > this.LARGE_COL_RANGE)
                        data = [];
                        raw = {};
                        dateData = {};
                        return;
                    end

                    origRange = newRange;

                    dims = this.getSheetDimensions;
                    if newRange.endCol - newRange.startCol < (this.COL_BLOCK_NUM -1)
                        newRange.startCol = max(1, round(newRange.startCol - ((this.COL_BLOCK_NUM/2) + 1), this.ROUND_DIGITS));
                        newRange.endCol = min(dims(4), round(newRange.endCol + ((this.COL_BLOCK_NUM/2) + 1), this.ROUND_DIGITS));
                    end

                    if newRange.endRow - newRange.startRow < (this.ROW_BLOCK_NUM - 1)
                        newRange.startRow = max(1, round(newRange.startRow - ((this.ROW_BLOCK_NUM/2) + 1), this.ROUND_DIGITS));
                        newRange.endRow = min(dims(2), round(newRange.endRow + ((this.ROW_BLOCK_NUM/2) + 1), this.ROUND_DIGITS));
                    end

                    newRange.excelRange = internal.matlab.importtool.server.ImportUtils.toExcelRange( ...
                        newRange.startRow, newRange.endRow, newRange.startCol, newRange.endCol);
                    key = newRange.excelRange;

                    internal.matlab.datatoolsservices.logDebug("it", "Adjusted range: " + key);

                    cachedData = read(this, newRange.excelRange, asDatetime);
                    cachedData.asDatetime = asDatetime;
                    this.CacheData(key) = cachedData;

                    [data, raw, dateData, rowsFromCache, colsFromCache] = this.getDataFromCachedDataRange(cachedData, ...
                        newRange.startRow:min(newRange.endRow, dims(2)), ...
                        newRange.startCol:min(newRange.endCol, dims(4)), ...
                        origRange, dims);
                end
            end
        end

        function [data, raw, dateData, rowsFromCache, colsFromCache] = getDataFromCachedDataRange(~, cachedData, cacheRows, cacheCols, newRange, dims)
            % Figure out where the requested rows/columns are in relation
            % to the cache data
            rowIncrement = newRange.startRow - cacheRows(1);
            colIncrement = newRange.startCol - cacheCols(1);

            rowsFromCache = rowIncrement + (1:(min(newRange.endRow, dims(2)) - newRange.startRow + 1));
            colsFromCache = colIncrement + (1:(min(newRange.endCol, dims(4)) - newRange.startCol + 1));

            % Make sure the data being retrieved from the cache isn't
            % larger than the cache itself
            sz = size(cachedData.data);
            numDataRows = sz(1);
            rowsFromCache(rowsFromCache > numDataRows) = [];
            numDataCols = sz(2);
            colsFromCache(colsFromCache > numDataCols) = [];

            data = cachedData.data(rowsFromCache, colsFromCache);
            raw = cachedData.raw(rowsFromCache, colsFromCache);

            if cachedData.asDatetime
                % dateData is a 1xN array of datetimes (one column vector of datetimes for each datetime
                % column).  So we need to index into it individually on each column.
                dateData = cellfun(@(x) x(rowsFromCache), cachedData.dateData, "UniformOutput", false, "ErrorHandler", @(varargin) []);
                dateData = dateData(colsFromCache);
            else
                % dateData is a cellstr of datetimes as text.
                dateData = cachedData.dateData(rowsFromCache, colsFromCache);
            end
        end

        function r = getRange(~, varargin)
            if nargin == 5
                startRow = varargin{1};
                endRow = varargin{2};
                startCol = varargin{3};
                endCol = varargin{4};
                excelRange = internal.matlab.importtool.server.ImportUtils.toExcelRange(startRow, endRow, startCol, endCol);
            else
                excelRange = varargin{1};
                [rows, cols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(excelRange);
                startRow = rows(1);
                endRow = rows(end);
                startCol = cols(1);
                endCol = cols(end);
            end

            r = struct('startRow', startRow, ...
                'endRow', endRow, ...
                'startCol', startCol, ...
                'endCol', endCol, ...
                'excelRange', excelRange, ...
                'fromClient', true);
        end

        function columnClassOptions = getEmptyColumnClassOptions(this)
            dataPos = this.getSheetDimensions();
            numcols = dataPos(4);
            columnClassOptions = repmat({''}, 1, numcols);
        end

        function state = getCommonState(this)
            state = struct;
            state.CurrentValidVariableNames = this.CurrentValidVariableNames;
            state.CurrentArbitraryVariableNames = this.CurrentArbitraryVariableNames;
            state.InitialColumnClasses = this.InitialColumnClasses;
            state.InitialColumnClassOptions = this.InitialColumnClassOptions;
            state.InitialColumnNames = this.InitialColumnNames;
            state.SupportsTrimNonNumeric = this.SupportsTrimNonNumeric;
            state.ValidMatlabVarNames = this.ValidMatlabVarNames;
            state.ViewType = this.ViewType;
        end

        function setCommonState(this, NameValueArgs)
            arguments
                this
                NameValueArgs.CurrentArbitraryVariableNames;
                NameValueArgs.CurrentValidVariableNames;
                NameValueArgs.ValidMatlabVarNames;
            end

            if isfield(NameValueArgs, "CurrentValidVariableNames")
                if isstruct(NameValueArgs.CurrentValidVariableNames)
                    data = NameValueArgs.CurrentValidVariableNames;
                    this.CurrentValidVariableNames(data.indices) = data.names;
                else
                    this.CurrentValidVariableNames = NameValueArgs.CurrentValidVariableNames;
                end
            end

            if isfield(NameValueArgs, "CurrentArbitraryVariableNames")
                if isstruct(NameValueArgs.CurrentArbitraryVariableNames)
                    data = NameValueArgs.CurrentArbitraryVariableNames;
                    this.CurrentArbitraryVariableNames(data.indices) = data.names;
                else
                    this.CurrentArbitraryVariableNames = NameValueArgs.CurrentArbitraryVariableNames;
                end
            end

            if isfield(NameValueArgs, "ValidMatlabVarNames")
                this.ValidMatlabVarNames = NameValueArgs.ValidMatlabVarNames;
            end
        end

        function varOutputName = getDefaultVarNameFromFile(~, filename)
            [~, varOutputName, ~] = fileparts(filename);
            varOutputName = matlab.lang.makeValidName(varOutputName);
        end

        function dataChanged(this, ~, ed)
            % By default just propagate the event
            this.notify("DataChange", ed);
        end
    end

    methods(Access = {?internal.matlab.importtool.server.Importer, ?matlab.unittest.TestCase})
        function categoricalCols = getCategoricalColumns(this)
            % Setup the datetime columns.  Need to handle cases where the
            % spreadsheet doesn't start at cell A1, so there could be columns
            % prior to the ones that importOptions has reported
            dataPos = this.getSheetDimensions();
            dims = [dataPos(2) dataPos(4)];

            textCols = cellfun(@(x) x == "char" || x == "string", this.importOptions.VariableTypes);
            if any(textCols)
                % Need to determine if there are any categorical columns. Read
                % in some sample data to do so (because detectImportOptions
                % doesn't detect categoricals)
                testDims(1) = min(dims(1), this.SampleRowCount);
                testDims(2) = min(dims(2), this.SampleColumnCount);
                range = internal.matlab.importtool.server.ImportUtils.toExcelRange(...
                    1, testDims(1), 1, testDims(2));
                newRange = this.getRange(range);
                newRange.fromClient = false;
                [data, raw] = this.getDataFromRangeStruct(newRange, false);

                raw(~isnan(data)) = {''};
                categoricalCols = internal.matlab.datatoolsservices.preprocessing.VariableTypeDetectionService.getPossibleCategoricalColumnsFromData(raw);
                if ~isequal(length(categoricalCols), length(textCols))
                    % We may have additional categoricalCols because this is
                    % based off of the sheet dimensions, which includes any
                    % additional variables found.
                    sizeDiff = length(categoricalCols) - length(textCols);
                    if sizeDiff > 0
                        textCols(end + 1:end + 1 + (sizeDiff - 1)) = true;
                    else
                        % There are more columns than we checked for
                        % categoricals, fill in the rest as false
                        categoricalCols(end + 1:end + 1 + (abs(sizeDiff) - 1)) = false;
                    end
                end
                categoricalCols = categoricalCols & textCols;
                categoricalCols(1, size(categoricalCols, 2)+1:dims(2)) = false;
            else
                categoricalCols = false(1, dims(2));
            end
        end
    end
end
