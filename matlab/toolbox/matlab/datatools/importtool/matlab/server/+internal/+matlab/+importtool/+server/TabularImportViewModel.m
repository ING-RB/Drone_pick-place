classdef TabularImportViewModel < internal.matlab.importtool.server.RowTimesViewMixin & internal.matlab.variableeditor.ArrayViewModel

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % This class is the ViewModel class for Text and spreadsheet Import.

    % Copyright 2018-2025 The MathWorks, Inc.

    properties (Constant, Access = private)
        CONVERTED = 'isConvertedTo';
        REPLACED = 'isReplacedBy';
        NUM_VARS_IN_CONFIRM_MESSAGE = 5;
        EMPTY_DATETIME = NaT;
    end

    properties(Constant)
        DEFAULT_OUTPUT_TYPE = 'table';
        DEFAULT_OUTPUT_TYPES = ["table", "timetable", "columnvector", "numericarray", ...
            "stringarray", "cellarray"];
        DEFAULT_OUTPUT_ACTIONS = ["importdata", "codegen"];
        DEFAULT_INTERACTION_MODE = "normal";
    end

    properties
        ColumnClasses;
        ColumnClassOptions;
        Workspace = "base";
        SelRows;
        SelCols;
        CachedDatetimeOptions;
        ImportDataCallback = [];
        CloseOnImportCallback = [];
        SupportsMultiDataRange = true;
        OriginalState = [];
    end

    properties(Hidden)
        % Cache cell data for reuse when scrolling
        CellInfoCache dictionary = dictionary(string.empty, struct.empty);

        CachedDMState = [];

        % Tests may set this to false
        InteractiveScrolling (1,1) logical = true;

        RenderedDataCache dictionary = dictionary(uint64.empty, struct.empty);

        EditedColNames = strings(0);
    end

    properties (Access = private)
        DataChangeListener
    end

    methods
        function this = TabularImportViewModel(dataModel, doInit)
            arguments
                dataModel
                doInit logical = false;
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel);

            if doInit
                % get the column names and column classes and store on view
                this.ColumnClasses = this.DataModel.getColumnClasses();
                this.ColumnClassOptions = this.DataModel.getColumnClassOptions();
                this.DataModel.initColumnNames();

                % Setup some initial properties
                sel = this.DataModel.getInitialSelection;
                this.setTableModelProperty("excelSelection", ...
                    internal.matlab.importtool.server.ImportUtils.toExcelRange(sel(1), sel(3), sel(2), sel(4)), false);
                this.setTableModelProperty("OutputVariableType", "table", false);
                this.setTableModelProperty("SupportedOutputActions", ["importdata", "codegen"], false);
                this.setTableModelProperty("VariableNamesRow", dataModel.getHeaderRow(), false);

                dataSourceProps = dataModel.getDataSourceProps();
                if isfield(dataSourceProps, "PreserveVariableNames") && dataSourceProps.PreserveVariableNames
                    % If the incoming properties have PreserveVariableNames set,
                    % then this means ValidMatlabVarNames should be false.
                    this.DataModel.setState("ValidMatlabVarNames", false);
                end
                state = this.DataModel.getState();
                this.OriginalState = state;
                f = fieldnames(state);
                for idx = 1:length(f)
                    this.setTableModelProperty(f{idx}, state.(f{idx}), false);
                end
                this.setTableModelProperty("ValidVariableNames", state.ValidMatlabVarNames);

                this.initOutputType(dataSourceProps);
                this.initOutputActions(dataSourceProps);
                this.initDefaultVariableNameAndSelection(dataSourceProps);

                this.DataChangeListener = event.listener(this.DataModel, "DataChange", @(es, ed) this.dataChanged(es, ed));
            end
        end

        function this = reset(this)
            % Reset the DataModel state to the initial state
            state = this.OriginalState;
            f = fieldnames(state);
            for idx = 1:length(f)
                fn = f{idx};
                value = state.(fn);
                this.setTableModelProperty(fn, value, false);

                try
                    this.DataModel.setState(fn, value);
                catch
                    % not all properties are settable
                end
            end

            % Re-initialize content in the view model
            this.ColumnClasses = this.DataModel.getColumnClasses();
            this.ColumnClassOptions = this.DataModel.getColumnClassOptions();
            this.DataModel.initColumnNames();
            sel = this.DataModel.getInitialSelection;
            this.setTableModelProperty("excelSelection", ...
                internal.matlab.importtool.server.ImportUtils.toExcelRange(sel(1), sel(3), sel(2), sel(4)), false);
            this.setTableModelProperty("OutputVariableType", "table", false);
            this.setTableModelProperty("SupportedOutputActions", ["importdata", "codegen"], false);
            this.setTableModelProperty("VariableNamesRow", this.DataModel.getHeaderRow(), false);
            this.setTableModelProperty("ValidVariableNames", state.ValidMatlabVarNames);
            this.DataModel.FileImporter.RulesStrategy = internal.matlab.importtool.server.rules.RulesStrategy;

            % Setup all of the ViewModel based on the original settings
            dataSourceProps = this.DataModel.getDataSourceProps();
            this.initOutputType(dataSourceProps);
            this.initOutputActions(dataSourceProps);
            this.initDefaultVariableNameAndSelection(dataSourceProps);
            this.CellInfoCache(keys(this.CellInfoCache)) = [];

            % Refresh the selection back to its initial selection
            this.refreshSelection(true, false);
        end

        function delete(this)
            this.closeRowTimesDialog();
        end

        function refreshSelection(this, ~, ~)
            % Called to re-select the current selection in the table.  This is
            % needed when the rules change, as the replacement/conversion colors
            % displayed may change.

            % Get the excel selection ("A1:C10", for example)
            excelRange = this.getTableModelProperty('excelSelection');
            if ~isempty(excelRange)
                this.dispatchRefreshAllEvent();
            end
        end

        function dispatchRefreshAllEvent(this)
            % Dispatch dataChange to refresh data on the client for the entire dataModel
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;

            dataSize = this.getTabularDataSize();
            % Setting to entire size will ensure that data buffer is
            % cleared and view is updated

            eventdata.StartRow = 1;
            eventdata.EndRow = dataSize(1);
            eventdata.StartColumn = 1;
            eventdata.EndColumn = dataSize(2);

            eventdata.SizeChanged = false;
            this.notify('DataChange', eventdata);
        end

        function selRows = currentRowSelection(this, startRow, endRow)
            selRows = [];
            if ~isempty(this.SelectedRowIntervals)
                selRows(1) = max(startRow, this.SelectedRowIntervals(1, 1));
                selRows(2) = min(endRow, this.SelectedRowIntervals(end, end));
            else
                selRows(1) = startRow;
                selRows(2) = endRow;
            end
            selRows = (selRows - startRow) + 1;
            this.SelRows = selRows;
        end

        function selCols = currentColumnSelection(this, startColumn, endColumn)
            selCols = [];
            if ~isempty(this.SelectedColumnIntervals)
                selCols(1) = max(startColumn, this.SelectedColumnIntervals(1, 1));
                selCols(2) = min(endColumn, this.SelectedColumnIntervals(end, end));
            else
                selCols(1) = startColumn;
                selCols(2) = endColumn;
            end
            selCols = (selCols - startColumn) + 1;
            this.SelCols = selCols;
        end

        function [renderedData, renderedDims] = getRawRenderedData(this, ...
                startRow, endRow, startColumn, endColumn)

            dictKey = keyHash([startRow, endRow, startColumn, endColumn]);
            if ~isempty(this.RenderedDataCache) && isKey(this.RenderedDataCache, dictKey)
                renderedData = this.RenderedDataCache(dictKey);
                renderedDims = size(renderedData.values);
                return;
            end

            [data, raw, dateData, cachedData, rowRange, colRange] = this.DataModel.getData(startRow, endRow, startColumn, endColumn);
            [data, raw, dateData] = this.DataModel.FileImporter.updateDisplayContent(data, raw, dateData, cachedData, rowRange, colRange);
            range.startRow = startRow;
            range.endRow = endRow;
            range.startColumn = startColumn;
            range.endColumn = endColumn;
            if isempty(this.CachedDatetimeOptions)
                this.CachedDatetimeOptions = containers.Map;
            end

            columnClasses = this.ColumnClasses;
            columnClassInfoSize = min(length(this.ColumnClasses), length(this.ColumnClassOptions));
            colClassIdx = startColumn:min(columnClassInfoSize, endColumn);
            columnClasses = columnClasses(colClassIdx);

            columnClassOptions = this.ColumnClassOptions(colClassIdx);
            rowCount = endRow - startRow + 1;
            colCount = endColumn - startColumn + 1;

            trimNonNumericCols = this.DataModel.getTrimNonNumericCols(this.ColumnClasses);
            trimNonNumericCols = trimNonNumericCols(colClassIdx);
            selRows = this.currentRowSelection(startRow, endRow);
            selCols = this.currentColumnSelection(startColumn, endColumn);

            state = this.DataModel.getState();
            rulesStrategy = this.DataModel.getRulesStrategy();
            rulesStrategy.setFileImporterState(state);
            rulesStrategy.generateExclusionMaps(data, raw, dateData, trimNonNumericCols, ...
                startRow, endRow, startColumn, endColumn, selRows, selCols, this.ColumnClasses);
            replacementVal = rulesStrategy.getRuleReplacementValue();

            % cell information required for display
            % values: display values
            % editValues: processed values (after conversion, replacement, etc.)
            % valueType: can be 'isConvertedTo', 'isReplacedBy', 'isError',
            % 'None'
            % Tooltip: tooltip string
            values = cell(rowCount, colCount);
            editValues = cell(rowCount, colCount);
            valueType = cell(rowCount, colCount);
            toolTip = cell(rowCount, colCount);

            dataSize = size(data);

            % disable any warnings coming from the datetime constructor. It will
            % try to warn for ambiguous formats which we may not care about, and
            % capture lasterror to reset it afterwards, so format errors won't
            % show up in lasterror after Import.
            s = warning('off', 'all');
            cl1 = onCleanup(@() warning(s));
            L = lasterror; %#ok<*LERR>
            cl2 = onCleanup(@() lasterror(L));

            for col = 1:colCount
                range.col = col;
                if col <= length(columnClasses)
                    colClass = columnClasses{col};
                    colClassOption = columnClassOptions{col};

                    % Use the column class option to specify whether numeric
                    % columns will be trimmed of non-numeric data or not.
                    if colClass == "double" && col <= length(trimNonNumericCols) ...
                            && trimNonNumericCols(col)
                        colClassOption = "trim";
                    end
                else
                    colClass = 'string';
                    colClassOption = '';
                end

                dtdata = [];
                if colClass == "datetime" && ~isempty(colClassOption) && ~isempty(dateData)
                    % do a quick datetime conversion of the entire row of data
                    dtc = dateData(1:rowCount, col);
                    try
                        dtdata = datetime(dtc, "InputFormat", colClassOption, "Format", "preserveinput");
                    catch
                        dtdata = NaT;
                    end
                    if all(isnat(dtdata))
                        dtdata = [];
                    end
                end

                for row = 1:rowCount
                    range.row = row;
                    key = (startRow + row) + "_" + (startColumn + col);
                    if row > dataSize(1) || col > dataSize(2)
                        % It's possible that the Import Tool client is asking
                        % for data which is out of range.  This can happen when
                        % new data is discovered while scrolling down in a file
                        % (for example, new columns are found), but this extra
                        % data may not always be available.  In this case, just
                        % treat this as an empty cell.
                        [values{row, col}, editValues{row, col}, valueType{row, col}, toolTip{row, col}] = ...
                            this.getCellInfo(colClass, colClassOption, nan, '', '', range, replacementVal, state);
                    else
                        if this.InteractiveScrolling && isKey(this.CellInfoCache, key)
                            % Use the cached information for this cell
                            st = this.CellInfoCache(key);
                            values{row, col} = st.value;
                            editValues{row, col} = st.editValue;
                            valueType{row, col} = st.valueType;
                            toolTip{row, col} = '';
                            continue;
                        end
                        if isempty(dtdata)
                            cellDateData = dateData{row,col};
                        else
                            cellDateData = dtdata(row);
                        end
                        [values{row, col}, editValues{row, col}, valueType{row, col}, toolTip{row, col}] = ...
                            this.getCellInfo(colClass, colClassOption, data(row, col), raw{row, col}, cellDateData, range, replacementVal, state);
                    end

                    valueType{row, col} = rulesStrategy.getExclusionType(row, col, valueType{row, col});

                    if this.InteractiveScrolling
                        % Store the cell info in the cache
                        st = struct;
                        st.value = values{row, col};
                        st.editValue = editValues{row, col};
                        st.valueType = valueType{row, col};
                        this.CellInfoCache(key) = st;
                    end
                end
            end

            renderedData.values = values;
            renderedData.editValues = editValues;
            renderedData.valueType = valueType;
            renderedData.toolTip = toolTip;
            renderedDims = size(values);
            this.RenderedDataCache(dictKey) = renderedData;
        end

        function [renderedData, renderedDims] = getRenderedData(this, ...
                startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = ...
                this.getRawRenderedData(startRow, endRow, startColumn, endColumn);
        end

        function [value, editValue, valueType, toolTip] = getCellInfo(...
                this, colClass, colClassOption, data, raw, dateData, ~, ...
                replacementVal, state)
            arguments
                this
                colClass
                colClassOption
                data
                raw
                dateData
                ~
                replacementVal
                state = this.DataModel.getState
            end

            % method constructs cell information required for display
            % values: display values
            % editValues: processed values (after conversion, replacement, etc.)
            % valueType: can be 'isConvertedTo', 'isReplacedBy', 'isError',
            % 'None'
            % Tooltip: tooltip string
            % Note - last argument 'range' is unused in this version of the
            % method
            import internal.matlab.datatoolsservices.preprocessing.VariableTypeDetectionService;
            value = raw;
            switch(colClass)
                case 'double'
                    editValue = [];

                    % if there is a value in the data array then
                    % it is the converted value.
                    if ~isempty(data) && ~isnan(data)
                        % converted-to values
                        editValue = data;
                        valueType = internal.matlab.importtool.server.TabularImportViewModel.CONVERTED;
                    else
                        if ~isempty(value) && (isStringScalar(value) || ischar(value))

                            if state.SupportsTrimNonNumeric
                                if colClassOption == "trim"
                                    extractedVal = VariableTypeDetectionService.extractNumberFromText(...
                                        value, state.DecimalSeparator, state.ThousandsSeparator);

                                    if ~isempty(extractedVal)
                                        % If it is not empty, treat this as its
                                        % converted-to value.
                                        editValue = extractedVal;
                                        valueType = internal.matlab.importtool.server.TabularImportViewModel.CONVERTED;
                                    end
                                else
                                    dblVal = str2double(value);
                                    if ~isnan(dblVal)
                                        % Catches conditions of numbers
                                        % containing commas
                                        editValue = dblVal;
                                        valueType = internal.matlab.importtool.server.TabularImportViewModel.CONVERTED;
                                    end
                                end
                            end

                            if (endsWith(value, "i") || endsWith(value, "j")) && ...
                                    (any(regexp(value, "^\d*i")) || any(regexp(value, "^\d*j")))
                                % Text as complex numbers, that end in a lower
                                % case i or j, are also converted properly.
                                % First pass check with endsWith is much quicker
                                % than regexp.
                                editValue = str2double(value);
                                valueType = internal.matlab.importtool.server.TabularImportViewModel.CONVERTED;
                            end

                            if strcmpi(raw, "nan")
                                % Text that is "nan" is not unimportable, so
                                % show as valid.  Need to return the text 'NaN'
                                % because the value NaN causes the cell to show
                                % as unimportable.
                                editValue = 'NaN';
                                valueType = internal.matlab.importtool.server.TabularImportViewModel.CONVERTED;
                            end
                        end

                        if isempty(editValue)
                            % replaced-to values
                            editValue = num2str(replacementVal);
                            valueType = internal.matlab.importtool.server.TabularImportViewModel.REPLACED;
                        end
                    end

                case 'datetime'
                    if isdatetime(dateData)
                        interpreted = dateData;
                    else
                        importOptions = internal.matlab.importtool.server.ImportToolColumnTypes.getColumnImportOptions(colClass, colClassOption);
                        if ~isempty(colClassOption)
                            try
                                interpreted = this.getConvertedDatetimeValue(importOptions, data, raw);
                            catch
                                interpreted = internal.matlab.importtool.server.TabularImportViewModel.EMPTY_DATETIME;
                            end
                        else
                            interpreted = internal.matlab.importtool.server.TabularImportViewModel.EMPTY_DATETIME;
                        end
                    end

                    % if there is a value in the dateData array then
                    % it is the converted value.
                    if ~isempty(dateData) && isempty(colClassOption)
                        % converted-to values
                        editValue = dateData;
                        valueType = internal.matlab.importtool.server.TabularImportViewModel.CONVERTED;
                        if isdatetime(value)
                            value = char(value);
                        end
                    elseif ~isnat(interpreted)
                        % convert text to datetime with specified input format
                        value = string(raw);
                        editValue = interpreted;
                        valueType = internal.matlab.importtool.server.TabularImportViewModel.CONVERTED;
                    else
                        % replaced-to values
                        editValue = 'NaT';
                        valueType = internal.matlab.importtool.server.TabularImportViewModel.REPLACED;
                        if ~isempty(value) && isdatetime(value)
                            value = char(value);
                        end
                    end

                case 'duration'
                    % interpret the raw value at a duration according to InputFormat
                    interpreted = NaN;
                    importOptions = internal.matlab.importtool.server.ImportToolColumnTypes.getColumnImportOptions(colClass, colClassOption);
                    if ~isempty(colClassOption)
                        l = lasterror;
                        try
                            if isfield(importOptions, 'InputFormat')
                                % set format to show all 9 fractional
                                % digits, and then strip off the trailing
                                % zeros later for the editValue
                                format = importOptions.InputFormat;
                                if isequal(format(end-1:end), '.S')
                                    format = [format 'SSSSSSSS'];
                                end
                                interpreted = duration(string(raw), 'InputFormat', importOptions.InputFormat, 'Format', format);
                            end
                        catch
                        end
                        lasterror(l);
                    end

                    if ~isnan(interpreted)
                        % converted-to values
                        % strip off the trailing zeros for fractional seconds
                        editValue = strip(strip(char(interpreted), 'right', '0'), 'right', '.');
                        valueType = internal.matlab.importtool.server.TabularImportViewModel.CONVERTED;
                    else
                        % replaced-to values
                        editValue = 'NaN';
                        valueType = internal.matlab.importtool.server.TabularImportViewModel.REPLACED;
                    end

                otherwise
                    % text or categoricals have the values and
                    % converted-to values are always the same
                    editValue = raw;
                    valueType = internal.matlab.importtool.server.TabularImportViewModel.CONVERTED;
            end
            toolTip = '';
        end

        function s = getSize(this)
            s = this.DataModel.getSheetDimensions();
            % sheet dimensions contains [startRow endrow startColumn endColumn]
            % we need to convert to the conventional [rowCount columnCount]
            s = [s(2) s(4)];
        end

        % Takes in a function string which ties the method names in this class
        % with the actions Ex: 'importData', 'generateScript', etc) and calls
        % the appropriate function for the action performed.
        %
        % On success, returns a status message containing a notification message
        % about the import ("The following variables were imported..."), or an
        % empty string for other import actions.  On error, an exception is
        % thrown.
        function status = handleImportActions(this, funcStr)
            status = '';
            sheetVarName = this.getTableModelProperty('OutputVariableName');
            fnHandle = str2func(funcStr);
            if funcStr == "importData"
                % For import, call the function and capture the variable names
                % and values which were imported.
                [varNames, vars] = fnHandle(this, sheetVarName);
                if isempty(vars)
                    return;
                end

                if ischar(varNames)
                    varNames = string(varNames);
                end

                % Loop through the variables which were created, and create a
                % message containing their name, type and size.
                varInfo = "";
                numVars = min(length(varNames), this.NUM_VARS_IN_CONFIRM_MESSAGE);
                for idx = 1:numVars
                    if idx > 1
                        varInfo = varInfo + newline;
                    end
                    sz = internal.matlab.datatoolsservices.FormatDataUtils.dimensionString(vars{idx});
                    varInfo = varInfo + varNames(idx) + " (" + sz + " " + class(vars{idx}) + ")";
                end

                % Format the appropriate message based on the number of
                % variables which were created.
                if isscalar(varNames)
                    status = message("MATLAB:codetools:importtool:ImportSuccessMsg", ...
                        varInfo).getString;
                elseif length(varNames) > this.NUM_VARS_IN_CONFIRM_MESSAGE
                    status = message("MATLAB:codetools:importtool:ImportSuccessMsgMultiAndMore", ...
                        varInfo, length(varNames) - this.NUM_VARS_IN_CONFIRM_MESSAGE).getString;
                else
                    status = message("MATLAB:codetools:importtool:ImportSuccessMsgMulti", ...
                        varInfo).getString;
                end
            else
                % Otherwise, just call the function
                fnHandle(this, sheetVarName);
            end
        end

        function createVarsInWorkspace(this, varNames, vars, opts)
            % Creates the variables in the workspace.  The variable names are
            % specified as varNames, and the corresponding variables themselves
            % are contained in vars.  varNames and vars are expected to be the
            % same length.

            % Note that the JS Import Tool currently is limited to importing
            % data into base workspace only. This will be changed when the
            % functionality is extended to support other workspaces.
            this.setTableModelProperty('OutputVariableNameWarning', []);
            varNames = string(varNames);

            if (ischar(this.Workspace) || isstring(this.Workspace)) && ...
                    isempty(this.ImportDataCallback)
                % Assign the variable(s) that were created into the workspace
                if ~isempty(vars)
                    for idx = 1:length(varNames)
                        assignin(this.Workspace, varNames(idx), vars{idx});
                    end
                end
            else
                % Generated code always needs the output variable name.  In the
                % case of column vectors, they will be filled in from the column
                % variable names.
                outputVarName = this.getTableModelProperty("OutputVariableName");
                c = this.generateScriptCode(outputVarName, false);

                st = struct('code', c);
                st.varNames = varNames;
                st.vars = vars;
                st.importOptions = opts;
                st.fileName = this.DataModel.getFileName;
                st.outputType = string(this.getTableModelProperty("OutputVariableType"));
                st.selection = string(this.getTableModelProperty("excelSelection"));
                st = this.addAdditionalImportDataFields(st);

                if isempty(this.ImportDataCallback)
                    this.Workspace.assignin(outputVarName, st);
                else
                    this.ImportDataCallback(st);
                end
            end

            if ~isempty(this.CloseOnImportCallback)
                this.CloseOnImportCallback();
            end
        end

        % generates the code for a script and opens in editor
        function c = generateScript(this, varNames)
            [c, tcg] = this.generateScriptCode(varNames, false);
            tcg.openCodeInEditor(c);
        end

        % generates the code for a live script and opens in live editor
        function c = generateLiveScript(this, varNames)
            % Pass in true to set the showLastOutput flag to true, so the
            % semi-colon will be left off for live scripts.
            [c, tcg] = this.generateScriptCode(varNames, true);
            tcg.openCodeInLiveEditor(c);
        end

        % generates the code for a function and opens in editor
        function c = generateFunction(this, varNames)
            [c, tcg] = this.generateFunctionCode(varNames, '');
            tcg.openCodeInEditor(c);
        end

        % Get the Import Options from the DataModel, to use to import or to
        % generate code.  Returns the Import Options object, the dataLines
        % (array), and the output type.
        function [opts, range, outputType] = getImportOptions(this, providedRange)
            arguments
                this
                providedRange = strings(0);
            end
            % get the input info to pass to code generator
            outputTypeStr = this.getTableModelProperty('OutputVariableType');
            [outputType, range, rules, colTargetTypes, ...
                colTargetTypeOptions, columnVarNames] = this.getInputForImport(...
                outputTypeStr, providedRange);

            % generate code
            [opts, range] = this.DataModel.getImportOptions(...
                "Range", range, ...
                "ColumnVarNames", columnVarNames, ...
                "ColumnVarTypes", colTargetTypes, ...
                "ColumnVarTypeOptions", colTargetTypeOptions, ...
                "Rules", rules);
        end

        function [outputType, range, rules, colTargetTypes, ...
                colTargetTypeOptions, columnVarNames] = getInputForImport(...
                this, outputTypeStr, providedRange)

            arguments
                this
                outputTypeStr (1,1) string = "table"
                providedRange string = strings(0);
            end

            import internal.matlab.importtool.server.OutputTypeFactory;
            import internal.matlab.importtool.server.ImportUtils;

            outputType = OutputTypeFactory.getOutputTypeFromText(outputTypeStr);
            outputType.initOutputArgsFromProperties(this);

            % get the selection range, which is the excel style of specifying
            % selection (letters for columns, numbers for rows) both text and
            % spreadsheet import use "excelSelection".
            if isempty(providedRange)
                currentExcelSelection = this.getTableModelProperty('excelSelection');
            else
                currentExcelSelection = providedRange;
            end
            [~, currentSelectionCols] = ...
                ImportUtils.excelRangeToMatlab(currentExcelSelection);

            range = this.getRanges(currentExcelSelection);

            import internal.matlab.importtool.server.rules.ImportRuleFactory;

            rules = this.DataModel.getRulesStrategy().getRulesList();

            % get the column target types for this selection
            colTargetTypes = cellstr(this.ColumnClasses);
            colTargetTypes = colTargetTypes(currentSelectionCols);

            % get the column target type options for this selection
            colTargetTypeOptions = cellstr(this.ColumnClassOptions);
            colTargetTypeOptions = colTargetTypeOptions(currentSelectionCols);

            % get the column variable names
            columnVarNames = this.getCurrentColumnVarNames;
            columnVarNames = columnVarNames(currentSelectionCols);
        end

        function columnVarNames = getCurrentColumnVarNames(this)
            % Returns the current column variable names.  These will be the
            % user-edited ones if they have edited them, or the default names
            % from the file.

            outputVarType = this.getTableModelProperty('OutputVariableType');

            % Arbitrary variable names are supported for table and timetable
            % output types
            supportsArbitraryVarNames = (isempty(outputVarType) || ...
                outputVarType == "table" || outputVarType == "timetable");
            validVariableNames = this.getTableModelProperty("ValidVariableNames");

            if isempty(this.CachedDMState)
                state = this.DataModel.getState();
                this.CachedDMState = state;
            else
                state = this.CachedDMState;
            end
            if ~supportsArbitraryVarNames || validVariableNames
                columnVarNames = cellstr(state.CurrentValidVariableNames);
                if isempty(columnVarNames)
                    avoidShadow = struct('isAvoidSomeShadows', true, 'isAvoidAllShadows', false);
                    columnVarNames = cellstr(state.CurrentArbitraryVariableNames);
                    columnVarNames = internal.matlab.importtool.server.ImportUtils.getDefaultColumnNames(...
                        [], columnVarNames, length(columnVarNames), avoidShadow, false);
                end
            else
                columnVarNames = cellstr(state.CurrentArbitraryVariableNames);
            end
        end

        % Returns the individual ranges which make up the current excel
        % selection, grouped by row selection.  If there is a single selection,
        % it will just be returned. For example:  "A3:C10" returns "A3:C10".
        % Similarly, a range of:  "A3:C10, D3:D10" returns {'A3:C10', 'D3:D10'}.
        % However, a range of: "B3:B7,B10:B11" returns: {{'B3:B7'}, {'B10:B11'}}
        function range = getRanges(~, currentExcelSelection)
            import internal.matlab.importtool.server.ImportUtils;

            if contains(currentExcelSelection, ",")
                range = {};
                ranges = strtrim(split(currentExcelSelection, ","));
                currRow = -1;

                % Loop through the comma separated ranges
                for idx = 1:length(ranges)
                    % Convert the letter range to rows
                    [r, ~] = ImportUtils.excelRangeToMatlab(ranges{idx});

                    if isequal(r, currRow)
                        % If it is the same rows as previous, add to the cell
                        % array
                        range{end}{end + 1} = ranges{idx};
                    else
                        % Otherwise create a new cell array for these row ranges
                        range{end + 1} = {}; %#ok<*AGROW>
                        range{end}{1} = ranges{idx};
                        currRow = r;
                    end
                end

                % Make sure the columns within each row range are in order.  For
                % example:
                % we want: {'A3:10', 'C3:C10'}, not: {'C3:C10', 'A3:A10'}

                % Function to convert Excel column letters to a number
                columnToNumber = @(col) sum((col - 'A' + 1) .* 26.^(length(col)-1:-1:0));

                for idx = 1:length(range)
                    ranges = range{idx};

                    % Extract the first column letters from each range
                    firstColumns = cellfun(@(r) regexp(r, '^[A-Z]+', 'match', 'once'), ranges, 'UniformOutput', false);

                    % Convert the column letters to numbers
                    columnNumbers = cellfun(columnToNumber, firstColumns);

                    % Sort the ranges based on the column numbers
                    [~, sortedIndices] = sort(columnNumbers);
                    range{idx} = ranges(sortedIndices);
                end
            else
                range = currentExcelSelection;
            end
        end

        function c = getInitialColumnClasses(this)
            state = this.DataModel.getState();
            c = state.InitialColumnClasses;
        end

        function c = getInitialColumnClassOptions(this)
            state = this.DataModel.getState();
            c = state.InitialColumnClassOptions;
        end

        function c = getInitialColumnNames(this)
            state = this.DataModel.getState();
            c = state.InitialColumnNames;
        end

        function setColumnNames(this, indices, names)
            this.CachedDMState = [];
            state = this.DataModel.getState();
            outputVarType = this.getTableModelProperty('OutputVariableType');
            supportsArbitraryVarNames = (isempty(outputVarType) || ...
                outputVarType == "table" || outputVarType == "timetable");
            if ischar(names)
                data = struct;
                data.indices = indices;
                data.names = names;
                if state.ValidMatlabVarNames || ~supportsArbitraryVarNames
                    this.DataModel.setState("CurrentValidVariableNames", data);
                else
                    this.DataModel.setState("CurrentArbitraryVariableNames", data);
                end
            else
                if state.ValidMatlabVarNames || ~supportsArbitraryVarNames
                    % The names must be fully specified for all columns
                    this.DataModel.setState("CurrentValidVariableNames", names);
                else
                    this.DataModel.setState("CurrentArbitraryVariableNames", names);
                end
            end
        end

        % generates the code for a script
        function [code, codeGenerator, codeDescription] = generateScriptCode(this, varNames, showOutput, shortCircuitCode)
            arguments
                this
                varNames
                showOutput (1,1) logical = false
                shortCircuitCode (1,1) logical = false
            end

            [opts, dataRange, outputType] = this.getImportOptions();
            % Generate code
            origOpts = this.DataModel.FileImporter.OriginalOpts;
            dims = this.DataModel.getSheetDimensions();
            [code, codeGenerator, codeDescription] = this.DataModel.generateScriptCode(opts, ...
                "Range", dataRange, ...
                "OutputType", outputType, ...
                "VarName", varNames, ...
                "OriginalOpts", origOpts, ...
                "NumRows", dims(2), ...
                "DefaultTextType", internal.matlab.importtool.server.ImportUtils.getSetTextType, ...
                "ShowOutput", showOutput, ...
                "ShortCircuitCode", shortCircuitCode);
        end

        % generates the code for a function
        function [code, codeGenerator] = generateFunctionCode(this, varNames, funcName)
            [opts, dataRange, outputType] = this.getImportOptions();
            % Generate code
            [code, codeGenerator] = this.DataModel.generateFunctionCode(opts, ...
                "Range", dataRange, ...
                "OutputType", outputType, ...
                "VarName", varNames, ...
                "DefaultTextType", internal.matlab.importtool.server.ImportUtils.getSetTextType, ...
                "FunctionName", funcName);
        end

        function [varNames, vars] = importData(this, varNames)
            [opts, dataRange, outputType] = this.getImportOptions();
            supportedOutput = this.getTableModelProperty("SupportedOutputActions");
            if isempty(supportedOutput) || any(supportedOutput == "importdata")
                [varNames, vars, opts] = this.DataModel.importData(opts, ...
                    "VarName", varNames, ...
                    "OutputType", outputType, ...
                    "Range", dataRange);
            else
                vars = {};
            end

            this.createVarsInWorkspace(varNames, vars, opts);
        end

        function s = addAdditionalImportDataFields(this, currImportDataStruct)
            s = this.DataModel.addAdditionalImportDataFields(currImportDataStruct);
        end

        function interpreted = getConvertedDatetimeValue(this, importOptions, data, raw)
            interpreted = this.DataModel.getConvertedDatetimeValue(importOptions, data, raw);
        end

        function setOutputVariableName(this, outputVariableName)
            % make the varname valid
            outputVariableName = matlab.lang.makeValidName(outputVariableName);

            % if that variable name exists in the workspace, then send a
            % warning that it already exists
            % Set fireUpdate flag to false
            this.updateOutputVariableNameWarningState(outputVariableName, false);
            % Update the client by triggering a updateTableModelInformation
            % cycle
            this.setTableModelProperty('OutputVariableName', outputVariableName);
        end

        function setOutputVariableType(this, outputVariableType)
            % Clear the cached data
            this.CellInfoCache(keys(this.CellInfoCache)) = [];
            this.RenderedDataCache(keys(this.RenderedDataCache)) = [];

            this.setTableModelProperty('OutputVariableType', outputVariableType);
        end

        function updateIncludesVarNamesRow(this, includesVarNamesRow)
            % Called when the "Variable Names Row" checkbox is toggled,
            % indicating whether or not the file has a variable names row.
            currIncludesVarNamesRow = this.getTableModelProperty('IncludesVariableNamesRow');
            this.setTableModelProperties('IncludesVariableNamesRow', includesVarNamesRow);

            if ~isequal(includesVarNamesRow, currIncludesVarNamesRow)
                % Variable Names changed, reset this if it is set
                rowTimesColIdx = this.getRowTimesColumnIndex();
                this.DataModel.resetStoredNames();

                if ~includesVarNamesRow
                    % Set the column names to default (VarName1, VarName2, etc)
                    this.setDefaultColumnNames();
                else
                    % Update the column names based on the data in the variable
                    % names row
                    this.updateColumnNames();
                end
                if ~isempty(rowTimesColIdx)
                    this.setTableModelProperty("RowTimesColumn", ...
                        this.getColumnNameFromIndex(rowTimesColIdx));
                end

                this.resolveVarNameRowAndSelection();
            end
        end

        function resolveVarNameRowAndSelection(this)
            % Called to resolve selection vs. the Variable Names Row and whether
            % variable names are included for this file.  A 'select all'
            % operation already only select from below the Variable Names Row,
            % and changing the Variable Names Row or whether the file includes
            % Variable Names should do the same.
            includesVarNamesRow = this.getTableModelProperty("IncludesVariableNamesRow");

            % If the user has changed the Variable Names row or the Includes
            % Variable Names Row setting see if we need to adjust the selection.
            currSelection = this.getSelection();
            currSelection = [currSelection{1}(1), currSelection{2}(1), ...
                currSelection{1}(2), currSelection{2}(2)];

            initialSelection = this.DataModel.getInitialSelection;
            endOfInitialSelection = initialSelection(2:4);

            % If the selection is the same as the initial selection, or if it is
            % one row off the initial selection or variable names row, reset the
            % selection
            varNamesRow = this.getTableModelProperty("VariableNamesRow");
            if isequal(currSelection, initialSelection) || ...
                    isequal(currSelection, [initialSelection(1)-1, endOfInitialSelection]) || ...
                    isequal(currSelection, [initialSelection(1)+1, endOfInitialSelection]) || ...
                    isequal(currSelection, [varNamesRow, endOfInitialSelection])
                selectionChanged = true;
                if ~includesVarNamesRow && ...
                        currSelection(1) - 1 == varNamesRow
                    % If the file doesn't have a variable names row, and the
                    % selection is one off of the variable names row, then
                    % we can extend the selection up a row
                    initialSelection(1) = max([initialSelection(1) - 1, 1, varNamesRow]);
                elseif includesVarNamesRow && currSelection(1) == varNamesRow
                    % Selection shouldn't include the variable names row,
                    % move it down a row
                    initialSelection(1) = varNamesRow + 1;
                else
                    selectionChanged = false;
                end

                if selectionChanged
                    excelSelection = internal.matlab.importtool.server.ImportUtils.toExcelRange(...
                        initialSelection(1), initialSelection(3), initialSelection(2), initialSelection(4));
                    this.setImportSelection(excelSelection, "server");
                end
            end
        end

        function setImportVariableNamesRow(this, ~)
            rowTimesColIdx = this.getRowTimesColumnIndex();

            this.updateColumnNames();
            this.updateVariableNamesRow();

            if ~isempty(rowTimesColIdx)
                this.setTableModelProperty("RowTimesColumn", ...
                    this.getColumnNameFromIndex(rowTimesColIdx));
            end

            this.resolveVarNameRowAndSelection();
        end

        function setImportColumnClass(this, indices, class, classOptions)
            currentClasses = this.ColumnClasses;
            currentClassOptions = this.ColumnClassOptions;

            class = convertStringsToChars(class);

            if isempty(indices)
                % set all columns
                indices = this.StartColumn:this.EndColumn;
            end

            if ischar(class)
                this.ColumnClasses(indices) = {class};
            else
                % The classes must be fully specified for all columns
                this.ColumnClasses = class;
            end

            if ischar(classOptions)
                this.ColumnClassOptions(indices) = {classOptions};
            else
                this.ColumnClassOptions = classOptions;
            end

            if ~(isequal(currentClasses, this.ColumnClasses) && isequal(currentClassOptions, this.ColumnClassOptions))
                % Clear the cached data
                this.CellInfoCache(keys(this.CellInfoCache)) = [];
                this.RenderedDataCache(keys(this.RenderedDataCache)) = [];

                % we have to make sure we don't attempt to access past the
                % end of the column options array. Sometimes the viewport
                % is larger than the column count when we get to this
                % point, so we protect against that by taking a minimum
                % of the number of columns available in total as a safety
                % measure
                if isprop(this, "ViewportStartColumn")
                    this.updateColumnModelInformation(this.ViewportStartColumn, min(this.ViewportEndColumn, this.DataModel.getColumnCount));
                end
                this.updateSelectionMetaInfo();

                outputType = this.getTableModelProperty("OutputVariableType");
                if strcmp(outputType, "timetable")
                    this.reevaluateTimetableSettings();

                    this.setTableModelProperty("DTDurationColumns", ...
                        this.getDTDurationColNames);
                    this.updateRowTimesInTable();
                end
                % Dispatch dataChange to refresh data on the client for the entire dataModel
                this.dispatchRefreshAllEvent();
            end
        end

        function setValidVariableNames(this, validVariableNames)
            currentValidVariableNames = this.getTableModelProperty('ValidVariableNames');
            this.setTableModelProperties('ValidVariableNames', validVariableNames);

            if ~isequal(validVariableNames, currentValidVariableNames)
                this.DataModel.setState("ValidMatlabVarNames", validVariableNames);
                this.updateColumnNames();
            end
        end

        function setImportColumnNames(this, indices, names)
            currentNames = this.getCurrentColumnVarNames;
            names = convertStringsToChars(names);
            viewSize = this.getViewSize();

            if isempty(indices)
                % set all columns
                indices = viewSize(3):viewSize(4);
            end

            state = this.DataModel.getState();
            if state.ValidMatlabVarNames || ...
                    ~any(strcmp(this.getTableModelProperty('OutputVariableType'), ["table", "timetable"]))
                names = matlab.lang.makeValidName(names);
            end

            this.setColumnNames(indices, names);

            % Update any datetime/duration columns which may be displayed
            this.setTableModelProperty("DTDurationColumns", ...
                this.getDTDurationColNames);

            if ~(isequal(currentNames, this.getCurrentColumnVarNames))
                this.updateColumnModelInformation(viewSize(3), viewSize(4));
                this.updateSelectionMetaInfo();

                eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                eventdata.StartRow = viewSize(1);
                eventdata.EndRow = viewSize(2);
                eventdata.StartColumn = viewSize(3);
                eventdata.EndColumn = viewSize(4);

                eventdata.SizeChanged = true;
                % DataChange event takes care of a full refresh
                this.notify('DataChange', eventdata);
            end
        end

        function setImportSelection(~, ~, varargin)
            % overwritten by the remote layer
            % Arguments are:  this, excelRange, varargin
        end
    end

    methods (Access = {?internal.matlab.importtool.server.TabularImportViewModel, ?matlab.unittest.TestCase})
        function initOutputType(this, dataSource)
            % Determine list of Supported Output Types
            if isfield(dataSource, "SupportedOutputTypes") ...
                    && ~isempty(dataSource.SupportedOutputTypes)
                supportedOutputTypes = string(dataSource.SupportedOutputTypes);
            else
                supportedOutputTypes = this.DEFAULT_OUTPUT_TYPES;
            end

            % Determine the default output type (table, if it is in the list,
            % otherwise choose the first list item)
            defaultOutputType = this.DEFAULT_OUTPUT_TYPE;
            rowTimes = this.getDefaultRowTimesProperties();
            firstColumnType = this.ColumnClasses(1);

            if isfield(dataSource, "InitialOutputType") ...
                    && ~isempty(dataSource.InitialOutputType)
                % InitialOutputType, if specified, takes precedence
                defaultOutputType = dataSource.InitialOutputType;
            elseif any(supportedOutputTypes == this.DEFAULT_OUTPUT_TYPE)
                if any(supportedOutputTypes == "timetable")
                    if firstColumnType == "datetime" || firstColumnType == "duration"
                        defaultOutputType = "timetable";
                    end
                end
            else
                defaultOutputType = supportedOutputTypes(1);
            end

            if defaultOutputType == "timetable" && (firstColumnType == "datetime" || firstColumnType == "duration")
                varNames = this.getCurrentColumnVarNames;
                rowTimes.rowTimesColumn = varNames{1};
                rowTimes.rowTimesType = "column";
            end

            % Add in the interaction mode (normal vs. rangeonly)
            if isfield(dataSource, "InteractionMode") ...
                    && ~isempty(dataSource.InteractionMode)
                interactionMode = dataSource.InteractionMode;
            else
                interactionMode = this.DEFAULT_INTERACTION_MODE;
            end

            % Set the table model properties
            this.setTableModelProperties(...
                "SupportedOutputTypes", supportedOutputTypes, ...
                "OutputVariableType", defaultOutputType, ...
                "DefaultOutputType", defaultOutputType, ...
                "DTDurationColumns", this.getDTDurationColNames, ...
                "RowTimesType", rowTimes.rowTimesType, ...
                "RowTimesValue", rowTimes.rowTimesValue, ...
                "RowTimesUnits", rowTimes.rowTimesUnits, ...
                "RowTimesStart", rowTimes.rowTimesStart, ...
                "RowTimesStartType", rowTimes.rowTimesStartType, ...
                "RowTimesColumn", rowTimes.rowTimesColumn, ...
                "InteractionMode", interactionMode);

            if defaultOutputType == "timetable"
                this.updateRowTimesInTable
            end

            % If the output type is not the default output, adjust the column
            % types accordingly
            if ~isequal(defaultOutputType, this.DEFAULT_OUTPUT_TYPE) && ...
                    ~isequal(defaultOutputType, "timetable")
                outputClass = internal.matlab.importtool.server.OutputTypeFactory.getOutputTypeFromText(defaultOutputType);
                colNames = outputClass.getColumnNames(this.getCurrentColumnVarNames);
                colClasses = outputClass.getColumnClasses(this.ColumnClasses);
                if ~isequal(length(colNames), length(colClasses))
                    colClasses = repmat(colClasses, 1, length(colNames));
                end
                colClasses = cellstr(colClasses);
                colClassOptions = outputClass.getColumnClassOptions(this.ColumnClassOptions);

                this.ColumnClasses = colClasses;
                this.ColumnClassOptions = colClassOptions;
            end
        end

        function initOutputActions(this, dataSource)
            % Determine list of Supported Output Actions
            if isfield(dataSource, "SupportedOutputActions") ...
                    && ~isempty(dataSource.SupportedOutputActions)
                supportedOutputActions = dataSource.SupportedOutputActions;
            else
                supportedOutputActions = this.DEFAULT_OUTPUT_ACTIONS;
            end

            % Set the table model properties
            this.setTableModelProperty("SupportedOutputActions", ...
                supportedOutputActions);

            if isfield(dataSource, "InteractionMode") && ~isempty(dataSource.InteractionMode) && ...
                    dataSource.InteractionMode == "rangeOnly"
                this.setTableModelProperty('IncludesVariableNamesRow', false);
            else
                this.setTableModelProperty('IncludesVariableNamesRow', true);
            end
        end

        function updateColumnNames(this)
            this.CachedDMState = [];
            % update the column names property
            % avoidShadow is used to avoid creating column names as
            % workspace variables which coincide with existing matlab
            % functions
            includesVarNamesRow = this.getTableModelProperty('IncludesVariableNamesRow');
            if includesVarNamesRow
                variableNamesRow = this.getTableModelProperty('VariableNamesRow');
                avoidShadow = this.getAvoidShadowForOutputType();

                % Until the workspace can be better specified, we need to
                % use the variable names in the base workspace.  'caller'
                % doesn't work, since we're in the action callback code.
                varNames = evalin('base', 'who');

                c = this.DataModel.getColumnNames(...
                    variableNamesRow, avoidShadow, varNames);
                c(~ismissing(this.EditedColNames)) = this.EditedColNames(~ismissing(this.EditedColNames));
                
                this.DataModel.setState("CurrentValidVariableNames", c);

                % Update any datetime/duration columns which may be displayed
                this.setTableModelProperty("DTDurationColumns", ...
                    this.getDTDurationColNames);

                try
                    endColumn = length(c);
                    changeEventData = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                    changeEventData.Column = 1:endColumn;
                    this.notify('TableMetaDataChanged', changeEventData);
                    this.notify('ColumnMetaDataChanged', changeEventData);
                catch e
                    disp (e);
                end
            else
                this.setDefaultColumnNames();
            end
        end

        function setDefaultColumnNames(this)
            % Resets the column names to default
            dims = this.DataModel.getSheetDimensions();
            numCols = dims(4);

            varNames = "Var" + (1:numCols);
            varNames(~ismissing(this.EditedColNames)) = this.EditedColNames(~ismissing(this.EditedColNames));
            this.setImportColumnNames(1:numCols, varNames);

            % Update any datetime/duration columns which may be displayed
            this.setTableModelProperty("DTDurationColumns", ...
                this.getDTDurationColNames);
        end

        % Updates output variable name warning state. Takes in fireUpdate
        % to decide whether to notify the client.
        function updateOutputVariableNameWarningState(this, outputVariableName, fireUpdate)
            fireUpdateOnPropSet = true;
            if (nargin > 2)
                fireUpdateOnPropSet = fireUpdate;
            end
            if any(strcmp(evalin('base', 'who'), outputVariableName))
                this.setTableModelProperty('OutputVariableNameWarning', ...
                    getString(message('MATLAB:codetools:importtool:OutputVariableNameWarning')), ...
                    fireUpdateOnPropSet);
            else
                this.setTableModelProperty('OutputVariableNameWarning', [], fireUpdateOnPropSet);
            end
        end
    end

    methods(Access = protected)
        function initDefaultVariableNameAndSelection(this, dataSource)
            if isfield(dataSource, "VariableName") && ...
                    ~isempty(dataSource.VariableName)
                this.setTableModelProperty("OutputVariableName", ...
                    dataSource.VariableName);
            else
                this.setTableModelProperty("OutputVariableName", ...
                    this.DataModel.getDefaultVariableOutputName());
            end

            [useInitialSelection, rows, cols] = this.getInitialSelectionFromUserInput(dataSource);
            if useInitialSelection
                % Resolve the initial selection so that it is within the bounds
                % of the current table
                dims = this.DataModel.getSheetDimensions();
                rows = min(rows, dims(2));
                cols = min(cols, dims(4));

                excelSelection = internal.matlab.importtool.server.ImportUtils.getExcelRangeArray(rows, cols);
                this.TableModelProperties.excelSelection = excelSelection;
                this.setSelection(rows, cols, 'server');
            end
        end

        function [useInitialSelection, rows, cols] = getInitialSelectionFromUserInput(this, dataSource)
            % Returns true for useInitialSelection, and the rows/cols of it, if
            % it is specified in the user's input to the function, and the
            % initial selection matches the initial sheet (if applicable).
            arguments
                this
                dataSource
            end

            useInitialSelection = false;
            rows = [];
            cols = [];

            if isfield(dataSource, "InitialSelection") && ~isempty(dataSource.InitialSelection)
                useInitialSelection = true;
                state = this.DataModel.getState();
                if isfield(state, "SheetName")
                    if isfield(dataSource, "InitialSheet") && ~isempty(dataSource.InitialSheet)
                        useInitialSelection = strcmp(dataSource.InitialSheet, state.SheetName);
                    end
                end

                if useInitialSelection
                    excelSelection = dataSource.InitialSelection;
                    try
                        % Resolve the excel selection.  If it happens to be
                        % invalid, assume an empty selection.
                        [rows, cols] = internal.matlab.importtool.server.ImportUtils.getRowsColsFromExcel(excelSelection);
                    catch
                        rows = [1,0];
                        cols = [1,0];
                    end
                end
            end
        end

        function avoidShadow = getAvoidShadowForOutputType(this)
            if this.getTableModelProperty('OutputVariableType') == "columnvector"
                avoidShadow = struct('isAvoidSomeShadows', false, ...
                    'isAvoidAllShadows', true);
            else
                avoidShadow = struct('isAvoidSomeShadows', true, ...
                    'isAvoidAllShadows', false);
            end
        end

        function viewSize = getViewSize(this)
            viewSize = this.DataModel.getSheetDimensions();
        end

        function updateVariableNamesRow(this)
            cols = this.ViewportStartColumn:this.ViewportEndColumn;
            currentVariableNames = this.getCurrentColumnVarNames;
            this.setColumnModelProperties(cols, {'HeaderName'}, ...
                {cellstr(currentVariableNames(cols))});
        end

        function dataChanged(this, ~, ed)
            if isfield(ed, "NewData") || isprop(ed, "NewData")
                data = ed.NewData;
                f = fieldnames(data);
                refresh = false;
                forceUpdate = false;
                forceColClassUpdate = false;
                for idx = 1:length(f)
                    fld = f{idx};
                    if fld == "refreshSelection"
                        refresh = true;
                    elseif fld == "forceSelectionUpdate"
                        forceUpdate = true;
                    elseif fld == "forceColClassUpdate"
                        forceColClassUpdate = true;
                    else
                        this.setTableModelProperty(fld, data.(fld));
                    end
                end

                if refresh
                    % Clear the cached data
                    this.CellInfoCache(keys(this.CellInfoCache)) = [];
                    this.RenderedDataCache(keys(this.RenderedDataCache)) = [];
                    this.CachedDMState = [];
                    this.refreshSelection(forceUpdate, forceColClassUpdate);
                end
            end
        end

        %%% Added to be overwritten by remote class %%%
        % Arguments are: this, startCol, endCol, fullColumns
        function updateColumnModelInformation(~, ~, ~, ~)
        end

        function updateSelectionMetaInfo(~)
        end
        %%%
    end
end
