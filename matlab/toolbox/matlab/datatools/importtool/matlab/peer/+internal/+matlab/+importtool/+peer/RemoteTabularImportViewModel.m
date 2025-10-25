% This class is unsupported and might change or be removed without notice
% in a future version.

% This class is the remote ViewModel for import

% Copyright 2022-2025 The MathWorks, Inc.

classdef RemoteTabularImportViewModel < internal.matlab.variableeditor.peer.RemoteArrayViewModel & internal.matlab.importtool.server.TabularImportViewModel

    properties
        workspaceListener;
        CellProperties;
        DocumentSize;
        RedrawStylesListener;
    end

    properties(Hidden)
        % Store the column widths which may be used when switching back and
        % forth between configurations
        ColumnWidths double = [];
    end

    properties(Constant, Access = private)
        OUTPUT_WITH_VAR_NAMES = ["table", "timetable", "columnvector"]
    end

    methods
        function this = RemoteTabularImportViewModel(document, variable, varargin)
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                document, variable, varargin{:});
            this@internal.matlab.importtool.server.TabularImportViewModel(...
                variable.DataModel, true);
            
            % TODO: Change this when IO functions can be run in the
            % background
            this.IsThreadSafe = false;

            this.RedrawStylesListener = event.listener(...
                this, 'DataChange', @(e, d) this.handleRedrawStyles);

            this.initViewModel(variable.DataSource);
        end

        % OVerride from RemoteArrayViewModel as we always want to turn off
        % bgpool fetches. IsThreadSafe flag is initialized in constructor
        function handled = initializeThreadSafety(~)
            handled = true;
        end

        function [renderedData, renderedDims] = getRenderedData(this, startRow, endRow, startColumn, endColumn)
            data = this.getRenderedData@internal.matlab.importtool.server.TabularImportViewModel(startRow, endRow, startColumn, endColumn);

            [renderedData, renderedDims] = this.getRenderedDataInternal(...
                data, startRow, endRow, startColumn, endColumn);
        end

        function [renderedData, renderedDims] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
            % Override getDisplayData to get the displayed data for the
            % table, which is used in determining column widths.  (This is
            % getting cached data, since it is already been retrieved by
            % the importer by this time).
            data = this.getRawRenderedData(startRow, endRow, startColumn, endColumn);
            renderedData = data.values;
            renderedDims = size(renderedData);
        end

        function [colWidths, startCol, endCol] = computeWidths(this, startCol, endCol)
            arguments
                this
                startCol
                endCol
            end
            import internal.matlab.variableeditor.VEColumnConstants;
            if endCol > numel(this.FittedColumnWidths) || any(~this.FittedColumnWidths(startCol:endCol))
                try
                    dispData = this.getDisplayData(1, 20, startCol, endCol);
                    allWidths = strlength(string(dispData));
                catch                   
                    % Setting widths to 1 so default width will get picked
                    % up.  Only tests hit this condition.
                    allWidths = ones(1, (endCol - startCol + 1));
                end
                dataWidths = max(allWidths)*this.CharacterWidth;
                widths = min(dataWidths, VEColumnConstants.MAX_COL_WIDTH);
                this.FittedColumnWidths(startCol:endCol) = widths;
            end
            colWidths = this.FittedColumnWidths(startCol:endCol);
            colWidths(colWidths<=VEColumnConstants.defaultColumnWidth)=0;
        end

        function forceUpdateSelection(this, newExcelSelection)
            this.setTableModelProperty('excelSelection', newExcelSelection);
            this.sendTableModelInformationDebounced();
        end
    end

    methods(Access='public')
        function initViewModel(this, dataSource)
            % set the size of the initial page from sheet dimensions if
            % Viewport info is empty at this point.
            s = this.DataModel.getSheetDimensions();
            this.ViewportStartColumn = 1;
            this.ViewportStartRow = 1;
            this.ViewportEndColumn = this.WindowBlockRows;
            this.ViewportEndRow = this.WindowBlockColumns;
            this.DocumentSize = [s(2) s(4)];
            this.CellProperties = cell(this.DocumentSize);

            if ~isempty(this.ViewportEndColumn) && ~isempty(this.ViewportEndRow)
                this.ViewportEndColumn = min(this.ViewportEndColumn, s(4));
                this.ViewportEndRow = min(this.ViewportEndRow,s(2));
            end

            [useInitialSelection, rows, cols] = this.getInitialSelectionFromUserInput(dataSource);
            if useInitialSelection
                % Use the user specified initial selection
                initialSelection = [rows(1) cols(1) rows(2) cols(2)];
            else
                % set the initial selection from the DataModel
                initialSelection = this.DataModel.getInitialSelection();

                % If we are using the initial selection, this has already been
                % done (and doing it here can have the effect of undoing plaid
                % range selections)
                this.setSelection([initialSelection(1) initialSelection(3)], [initialSelection(2) initialSelection(4)]);
            end

            % This is a one time update to initialize some table model
            % properties
            this.updateInitialTableMetaInfo(initialSelection);

            % set the listener on workspace
            this.workspaceListener = matlab.internal.mvm.eventmgr.MVMEvent.subscribe( ...
                '::MathWorks::ExecutionEvents::VariablesChangedEvent', ...
                @this.workspaceChanged);
        end

        function [renderedData, renderedDims] = getRenderedDataInternal(~, data, startRow, endRow, startColumn, endColumn)
            values = data.values;
            editValues = data.editValues;
            valueType = data.valueType;

            rowStrs = string(startRow-1:endRow-1);
            colStrs = string(startColumn-1:endColumn-1);

            renderedData = cell(size(data.values));
            for col = 1:size(renderedData,2)
                if isstring(values{1,col})
                    valuesCol = string([values{:,col}]);
                else
                    valuesCol = string(values(:,col));
                end
                if isstring(editValues{1,col})
                    editValuesCol = string([editValues{:,col}]);
                    editValuesCol(ismissing(editValuesCol)) = "";
                else
                    editValuesCol = string(editValues(:,col));
                end

                for row = 1:size(renderedData,1)
                    renderedData{row, col} = internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, ...
                        struct('value', struct( ...
                        'value', valuesCol(row),...
                        'editValue', editValuesCol(row), ...
                        'valueType', valueType{row, col}, ...
                        'toolTip', '', ...
                        'row', rowStrs(row), ...
                        'col', colStrs(col))));
                end
            end

            renderedDims = size(renderedData);
        end

        function workspaceChanged(this, varargin)
            % case where the outputvariablename control shows a warning
            % that the variable name exists in workspace
            % if the workspace changes and the variable is removed, the
            % outputvariablename control should reflect it
            outputVariableNameWarning = this.getTableModelProperty('OutputVariableNameWarning');
            if ~isempty(outputVariableNameWarning)
                outputVariableName = this.getTableModelProperty('OutputVariableName');
                this.updateOutputVariableNameWarningState(outputVariableName);
            end
        end

        % Sets the selection in the Import Tool table to the specified excel
        % range, which is something like B2:D100.  varargin can contain the
        % source of the selection ('server' or 'client') as the first value, and
        % the second value can optionally be a logical value to force
        % redisplay.  (Sometimes the server alters the selection, and we need
        % to force the client to update, even if it appears that we're resetting
        % the same selection)
        function setImportSelection(this, excelRange, varargin)
            if nargin >= 3
                source = varargin{1};
            else
                source = 'client';
            end

            forceRedisplay = false;
            if nargin == 4
                forceRedisplay = varargin{2};
            end

            % if new selection is not the same as old selection then update
            % table model property
            oldSelection = this.getTableModelProperty('excelSelection');
            if strcmp(oldSelection, excelRange) && ~forceRedisplay
                return;
            end

            dataPos = this.DataModel.getSheetDimensions();

            % Pull out valid ranges from the user entered text.  Valid ranges
            % are in the pattern (letters)(numbers):(letters)(numbers)
            rangeFromPattern = extract(string(excelRange), lettersPattern + digitsPattern + ":" + lettersPattern + digitsPattern);
            if ~isempty(rangeFromPattern)
                excelRange = rangeFromPattern;
            end
            excelRange = internal.matlab.importtool.server.ImportUtils.makeValidExcelRange(excelRange, dataPos);
            % if the range after validation is the same as the old then
            % send a peer event indicating the selection range should be
            % reverted
            if strcmp(excelRange, oldSelection) || isequal(excelRange, oldSelection)
                eventObj = struct('type', 'errorSelectionRange', 'status', 'error', 'dispValue', oldSelection);
                this.Provider.dispatchEventToClient(this, eventObj, this.viewID);
            end

            % get the range selection and update the cell model properties
            if isempty(excelRange)
                this.setSelection([], [], source);
            else
                [newRows, newCols] = internal.matlab.importtool.server.ImportUtils.getRowsColsFromExcel(excelRange);
                % set the new selection on view
                this.setSelection(newRows, newCols, source);
            end

            % update the table model property if its a new selection range,
            % this should trigger a full tableMetaData update that would
            % updateSelectionMetaInfo. Do this after the setSelection so that
            % the client has the updated selection on refresh
            this.setTableModelProperty('excelSelection', excelRange);
        end

        function varargout = setSelection(this, rows, cols, selectionSource, selectionArgs)
            arguments
                this
                rows
                cols
                selectionSource = 'server'% This is an optional parameter to indicate the source of the selection change.
                selectionArgs.selectedFields = []
                selectionArgs.updateFocus (1,1) logical = true
            end
            import internal.matlab.importtool.server.ImportUtils;

            % If the 'Has Variable Names' checkbox is selected, and the
            % selection includes content above and below the variable names row,
            % reset the selection to be under it.  This is to address an issue
            % where users unexpectedly import the variable names row, or content
            % above it, along with their table data.
            hasVarNameRow = this.getTableModelProperty("IncludesVariableNamesRow");
            if ~isempty(hasVarNameRow) && hasVarNameRow && ~isempty(rows) && ~isempty(cols) && ...
                    size(rows,2) == 2 && ~any(rows == 0, "all") && ~any(cols == 0, "all")
                rows = sortrows(rows);
                varNamesRow = this.getTableModelProperty("VariableNamesRow");
                if rows(1) <= varNamesRow && rows(2) > varNamesRow
                    % Reset the selection by moving the selection to be below
                    % the variable names row.
                    rows(1) = varNamesRow + 1;
                    excelRange = ImportUtils.getExcelRangeArray(rows, cols);
                    this.setImportSelection(excelRange, "server", true);
                    varargout{1} = {rows, cols};
                    return;
                end
            end

            % Override setSelection to set the excelSelection range TableModelProperty
            % g2001118: Pass in the selectionArgs so that the RemoteArrayViewModel
            % knows the event source.
            % Ignoring this will default the event source to be 'server'
            % which can create an infinite loop for client generated
            % selection events
            args = namedargs2cell(selectionArgs);
            varargout{1} = this.setSelection@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                rows, cols, selectionSource, args{:});

            if isempty(rows) || isempty(cols) || any(rows < 1, 'all') || any(cols < 1, 'all')
                % Handle empty rows or rows/cols of 0 (which means them
                % selection was cleared)
                excelRange = '';
            else
                startRows = rows(:, 1);
                endRows = rows(:, 2);

                startCols = cols(:, 1);
                endCols = cols(:, 2);

                excelRange = strings(0);
                requiresRedisplayForRules = false;
                rulesStrategy = this.DataModel.getRulesStrategy();
                hasRowOrColumnExclusionRules = rulesStrategy.hasRowOrColumnExclusionRules();
                for r = 1:length(startRows)
                    for c = 1:length(startCols)
                        excelRange(end+1) = ImportUtils.toExcelRange(...
                            startRows(r), endRows(r), startCols(c), endCols(c)); %#ok<AGROW>

                        if hasRowOrColumnExclusionRules && ~isempty(rulesStrategy.CellExclusionsMap)
                            k = keys(rulesStrategy.CellExclusionsMap);
                            for idx = 1:length(k)
                                ruleid = k{idx};
                                s = rulesStrategy.CellExclusionsMap(ruleid);
                                exclusions = s.excludedCells;
                                if any(any(exclusions))
                                    requiresRedisplayForRules = true;
                                end
                            end
                        end
                    end
                end

                excelRange = strjoin(excelRange, ",");

                if requiresRedisplayForRules || rulesStrategy.ExclusionRulesDisplayed || ...
                        (selectionSource == "force")

                    % Dispatch dataChange to refresh data on the client for the entire dataModel
                    this.dispatchRefreshAllEvent();
                end
            end
            this.forceUpdateSelection(excelRange);

            if isempty(this.ViewportStartRow)
                s = this.DataModel.getSheetDimensions();
                this.ViewportStartColumn = 1;
                this.ViewportStartRow = 1;
                this.ViewportEndColumn = this.WindowBlockRows;
                this.ViewportEndRow = this.WindowBlockColumns;

                if ~isempty(this.ViewportEndColumn) && ~isempty(this.ViewportEndRow)
                    this.ViewportEndColumn = min(this.ViewportEndColumn, s(4));
                    this.ViewportEndRow = min(this.ViewportEndRow,s(2));
                end
            end
            this.updateCellModelInformation(this.ViewportStartRow, this.ViewportEndRow,...
                this.ViewportStartColumn, this.ViewportEndColumn);

            % Update the row times that may be displayed for timetable output.
            % This changes when the selection changes (because, especially for
            % generated times, the times only apply to the selected rows,
            % because that is what you will see as a result of the import)
            this.updateRowTimesInTable();

            try
                changeEventData = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                dims = this.DataModel.getSheetDimensions();
                changeEventData.Row = 1:dims(2);
                this.notify('RowMetaDataChanged', changeEventData);
            catch e
                disp (e);
            end
        end

        function setState(this, varargin)
            arguments
                this
            end

            arguments (Repeating)
                % Use varargin because some of these may be file-specific
                % arguments that we don't want to hard-code here.
                varargin
            end

            NameValueArgs = struct(varargin{:});

            if isfield(NameValueArgs, "OutputVariableType")
                % If the output type is table/timetable, then the IncludesVariableNamesRow is enabled, so
                % save the current state
                currOutputType = this.getTableModelProperty("OutputVariableType");
                currOutputSupportsTypes = false;
                if any(strcmp(currOutputType, this.OUTPUT_WITH_VAR_NAMES))
                    % Save the state as a TableModelProperty.  This should only be set for table/timetable
                    % output because the checkbox is only enabled for them.
                    this.setTableModelProperty("IncludesVariableNamesRowPrev", ...
                        this.getTableModelProperty("IncludesVariableNamesRow"));
                    currOutputSupportsTypes = true;
                end
                newValue = NameValueArgs.OutputVariableType;

                newOutputSupportsTypes = false;
                if any(strcmp(newValue.value, this.OUTPUT_WITH_VAR_NAMES))
                    % If we're changing to table or timetable, set
                    % includesVarName based on its previous value, or use
                    % the default (true)
                    prevIncludeVarName = this.getTableModelProperty("IncludesVariableNamesRowPrev");
                    if ~isempty(prevIncludeVarName)
                        includesVarName = prevIncludeVarName;
                    else
                        includesVarName = true;
                    end
                    newOutputSupportsTypes = true;
                else
                    % IncludesVarName is not an option if the output type
                    % is not table or timetable
                    includesVarName = false;
                end

                % Pass in the new value to the ViewModel
                this.setOutputVariableType(newValue.value);

                % Create the output type class from the factory
                outputClass = internal.matlab.importtool.server.OutputTypeFactory.getOutputTypeFromText(newValue.value);

                % Get the current class types and options
                state = this.DataModel.getState();
                updateNames = true;
                if currOutputSupportsTypes && newOutputSupportsTypes
                    % Use current types since both the previous and the new type
                    % support types (for example, when switching from table to
                    % timetable)
                    newClasses = this.ColumnClasses;
                    newClassOptions = this.ColumnClassOptions;

                    if state.ValidMatlabVarNames
                        currVarNames = state.CurrentValidVariableNames;
                    else
                        currVarNames = state.CurrentArbitraryVariableNames;
                    end
                    tmpNames = currVarNames;
                    tmpNames(~ismissing(this.EditedColNames)) = this.EditedColNames(~ismissing(this.EditedColNames));
                    columnNames = outputClass.getColumnNames(tmpNames);

                    updateNames = false;
                else
                    % Reset to initial classes
                    newClasses = state.InitialColumnClasses;
                    newClassOptions = state.InitialColumnClassOptions;

                    % Update the variable name based on the output type.  (This can
                    % change, for example, for table/timetable vs. column vector, where
                    % you can have shadowed or arbitrary variable names for
                    % table/timetable, but not for column vectors.
                    varNameRow = this.getTableModelProperty("VariableNamesRow");
                    this.DataModel.FileImporter.resetStoredNames();
                    avoidShadow = struct('isAvoidSomeShadows', true, 'isAvoidAllShadows', false);
                    initialColumnNames = this.DataModel.FileImporter.getDefaultColumnNames(varNameRow, avoidShadow, []);
                    columnNames = outputClass.getColumnNames(initialColumnNames);
                    columnNames(~ismissing(this.EditedColNames)) = this.EditedColNames(~ismissing(this.EditedColNames));
                end

                % Get the new column classes, options, and names from the output
                % type.  (For example, numeric array output will set all of the
                % column classes to double)
                sz = this.getSize();
                columnClasses = outputClass.getColumnClasses(newClasses);
                columnClassOptions = outputClass.getColumnClassOptions(newClassOptions);

                % Update the view model with the new column names and types.
                % Only update the names if it is needed, otherwise there may be
                % a flash as this triggers other UI updates.
                if updateNames || ~isequal(columnNames, currVarNames)
                    if includesVarName
                        this.setImportColumnNames((1:sz(2)), columnNames);
                    else
                        this.setDefaultColumnNames();
                    end
                end
                this.setImportColumnClass((1:sz(2)), columnClasses, columnClassOptions);

                if newValue.value == "timetable"
                    % When timetable is selected, check to see if there are
                    % currently any datetime or duration columns
                    timeColOptions = arrayfun(@(x) x == "datetime" || x == "duration", ...
                        columnClasses);

                    if any(timeColOptions)
                        % If there are any datetime or duration columns, use the
                        % first one as the row times column for the timetable
                        dtDurationColNames = columnNames(timeColOptions);
                        this.setTableModelProperties(...
                            "RowTimesType", "column", ...
                            "RowTimesColumn", dtDurationColNames(1));
                    else
                        % If the file doesn't contain any datetime or duration
                        % columns, open the configure row times dialog

                        % Get the offset dialog position, and show it
                        [offsetX, offsetY] = internal.matlab.importtool.Actions.DialogImportAction.getDialogPosition(newValue);

                        this.configureRowTimes(offsetX, offsetY);
                    end

                    % IncludesVariableNamesRow is enabled for timetable, so use the last value it was set to
                    % when it was enabled
                    this.setTableModelProperties("IncludesVariableNamesRow", includesVarName);
                elseif any(newValue.value == this.OUTPUT_WITH_VAR_NAMES)
                    % IncludesVariableNamesRow is enabled for table, so use the last value it was set to
                    % when it was enabled
                    this.setTableModelProperties("IncludesVariableNamesRow", includesVarName);
                else
                    % IncludesVariableNamesRow is disabled for this output type, so make sure it is unchecked
                    this.setTableModelProperties("IncludesVariableNamesRow", false);
                end

                % Resolve the current selection with the Variable Names Row and the "No Variable Names" 
                % checkbox value.  This will adjust the table's selection if needed.
                this.resolveVarNameRowAndSelection();

                % Update the row names -- this can change based off of timetable
                % selection vs other types.
                this.updateRowTimesInTable();
                NameValueArgs = rmfield(NameValueArgs, "OutputVariableType");
            end

            if ~isempty(NameValueArgs)
                args = namedargs2cell(NameValueArgs);
                this.DataModel.setState(args{:});
                this.reevaluateTimetableSettings();
            end
        end

        function refreshSelection(this, forceUpdate, forceColClassUpdate)
            this.getNewDataModel(forceColClassUpdate);
            this.updateClient();
            pause(0.1);
            refreshSelection@internal.matlab.importtool.server.TabularImportViewModel(this, forceUpdate, forceColClassUpdate);

            if forceUpdate
                excelRange = this.getTableModelProperty('excelSelection');
                if isempty(excelRange)
                    % For empty selection, revert to the initial selection (which is
                    % the initial selection for the newly selected file type --
                    % fixed width or delimited).
                    initialSelection = this.DataModel.getInitialSelection();
                    this.setSelection([initialSelection(1) initialSelection(3)], ...
                        [initialSelection(2) initialSelection(4)], 'server');
                else
                    % Otherwise, use the current selection and update
                    [newRows, newCols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(excelRange);
                    this.setSelection([newRows(1) newRows(end)], [newCols(1) newCols(end)], 'server');
                end
            end
        end

        function setImportVariableNamesRow(this, variableNamesRow)
            currentVariableNamesRow = this.getTableModelProperty('VariableNamesRow');
            if ~isequal(variableNamesRow, currentVariableNamesRow)
                % Use sendTableModelInformationDebounced to force the client update quickly, without
                % waiting for the debounce to happen
                this.setTableModelProperty('VariableNamesRow', variableNamesRow, false);
                this.sendTableModelInformationDebounced();
                setImportVariableNamesRow@internal.matlab.importtool.server.TabularImportViewModel(this, variableNamesRow);
            end
        end
    end

    methods(Static)
        function inside = cellIsOutsideSelection(row, col, selectedRows, selectedCols)
            inside = true;

            % Check if the row is within any of the row intervals
            for i = 1:size(selectedRows, 1)
                if row >= selectedRows(i, 1) && row <= selectedRows(i, 2)
                    % Check if the column is within any of the column intervals
                    for j = 1:size(selectedCols, 1)
                        if col >= selectedCols(j, 1) && col <= selectedCols(j, 2)
                            % If both row and column are within an interval, set result to false
                            inside = false;
                            return;
                        end
                    end
                end
            end
        end
    end

    methods(Access = protected)
        %%% REMOTE LAYER %%%

        function viewSize = getViewSize(this)
            viewSize = [this.ViewportStartRow, this.ViewportEndRow, this.ViewportStartColumn, this.ViewportEndColumn];
        end

        %%%

        function handleRedrawStyles(this)
            this.updateCellModelInformation(this.ViewportStartRow, this.ViewportEndRow, ...
                this.ViewportStartColumn, this.ViewportEndColumn, ...
                1:this.DocumentSize(1), 1:this.DocumentSize(2));
        end

        function updateSelectionMetaInfo(this)
            [selectionClass, selectionClassOption, selectionTypeList] = deal([]);
            excelSelection = this.getTableModelProperty('excelSelection');
            % g2104369: Ensure the hover selection is set if the
            % property exists. Else, set it to empty
            hoverSelection = this.getTableModelProperty('HoverSelection');
            if isempty(hoverSelection)
                hoverSelection = [];
            end
            if ~isempty(excelSelection) && ~isempty(this.ColumnClasses)
                try
                    [~, cols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(excelSelection);
                    underlyingTypes = this.DataModel.getUnderlyingColumnTypes();
                    selectionTypeList = internal.matlab.importtool.server.ImportToolColumnTypes.getSelectionDataTypeList(underlyingTypes(cols));
                    selectionClasses = unique(this.ColumnClasses(cols));
                    selectionClassOptions = unique(this.ColumnClassOptions(cols));
                    if isscalar(selectionClasses)
                        selectionClass = selectionClasses{1};
                        if isscalar(selectionClassOptions)
                            selectionClassOption = selectionClassOptions{1};
                        end
                    end
                catch
                end
            end
            this.setTableModelProperties('selectionDataTypeList', ...
                selectionTypeList, 'selectionClass', selectionClass, ...
                'selectionClassOption', selectionClassOption, ...
                'DataSource', reverse(extractBefore(reverse(this.DataModel.FileImporter.FileName), filesep)), ...
                'unimportableCellRules', this.DataModel.getRulesStrategy.Rules, 'HoverSelection', hoverSelection);

            tableModelProps = internal.matlab.variableeditor.peer.PeerUtils.toJSON(this.MetaDataStore.getTabularTableMetaData());
            this.setProperty('TableModelProperties', tableModelProps);
            this.sendTableModelInformationDebounced();
        end


        function updateColumnModelInformation(this, startCol, endCol, fullColumns)
            arguments
                this (1,1)
                startCol (1,1) double {mustBeNonnegative}
                endCol (1,1) double {mustBeNonnegative}
                fullColumns (1,:) double = startCol:endCol
            end

            % set the column model properties (column names, column classes)
            [props, vals] = this.getColumnModelPropertiesForUpdate(startCol, endCol);

            % Set the column model properties, unless they are empty (which can
            % happen in transition states where the column data isn't available
            % yet)

            if ~all(cellfun(@isempty, vals))
                this.setColumnModelProperties(startCol:endCol, props, vals);

                % Force the metadata to update immediately since it alters the display
                this.sendColumnMetaData(startCol, endCol, fullColumns);
            end
        end

        function [props, vals] = getColumnModelPropertiesForUpdate(this, startCol, endCol)
            import internal.matlab.importtool.server.ImportUtils;
            import internal.matlab.importtool.server.ImportToolColumnTypes;

            % Limit the cols to a valid range
            currentVariableNames = this.getCurrentColumnVarNames;
            if endCol > length(currentVariableNames)
                endCol = length(currentVariableNames);
            end
            cols = startCol: endCol;

            colNames = cellstr(currentVariableNames(cols));
            colClasses = this.ColumnClasses(cols);
            colClassOptions = this.ColumnClassOptions(cols);

            editValues = repmat({'NaN'}, 1, length(cols));
            valueTypes = repmat({''}, 1, length(cols));
            toolTips = repmat({''}, 1, length(cols));

            underlyingTypes = this.DataModel.getUnderlyingColumnTypes();
            excelHeaders = arrayfun(@ImportUtils.intToColumnString, cols, 'UniformOutput', false);
            colVariableTypes = cellfun(@ImportToolColumnTypes.getColumnTypeForDisplay, colClasses, 'UniformOutput', false);
            columnListTypes = cellfun(@ImportToolColumnTypes.getColumnListType, underlyingTypes(cols), 'UniformOutput', false);

            props = {'HeaderName', 'class', 'classOption', 'editValue', ...
                'valueType', 'toolTip', 'excelHeader', 'columnVariableType', ...
                'columnListType'};
            vals = {colNames, colClasses, colClassOptions, editValues, ...
                valueTypes, toolTips, excelHeaders, colVariableTypes, ...
                columnListTypes};

            state = this.DataModel.getState();
            if isfield(state, "ColumnWidths") && isfield(state, "FixedWidth")
                this.setTableModelProperty("ColumnWidth", 0);
                if state.FixedWidth
                    % Switching to Fixed Width.  Save the current column
                    % widths, so they can be restored if the user switches
                    % back to delimited.
                    props{end+1} = 'ColumnWidth'; 
                    vals{end+1} = state.ColumnWidths(cols);

                    for idx = 1:length(this.ColumnModelProperties)
                        if this.hasColumnModelProperty(idx, "ColumnWidth")
                            w = this.getColumnModelProperty(idx, "ColumnWidth");
                            this.ColumnWidths(idx) = w{1};
                        end
                    end
                elseif ~isempty(this.ColumnModelProperties)
                    % Restore the previous column widths if the
                    % ColumnWidths property is set.
                    resetWidths = ~isempty(this.ColumnWidths) && ~all(this.ColumnWidths == 0);
                    if ~resetWidths
                        this.ColumnWidths = zeros(1, length(colNames));
                    end

                    for idx = 1:length(colNames)
                        if ~resetWidths && this.hasColumnModelProperty(idx, "ColumnWidth")
                            w = this.getColumnModelProperty(idx, "ColumnWidth");
                            this.ColumnWidths(idx) = w{1};
                        end
                    end

                    if resetWidths
                        % Add in the widths to the column model properties
                        % being set
                        props{end+1} = "ColumnWidth"; 
                        ex = lasterror;
                        try
                            vals{end+1} = num2cell(this.ColumnWidths(cols));
                        catch
                            vals{end+1} = repmat({0}, 1, length(cols));
                        end
                        lasterror(ex)
                    end
                end
            end
        end

        function updateInitialTableMetaInfo(this, initialSelection)
            underlyingTypes = this.DataModel.getUnderlyingColumnTypes();
            listTypes = cellfun(@(x) internal.matlab.importtool.server.ImportToolColumnTypes.getColumnListType(x), unique(underlyingTypes), 'UniformOutput', false);
            for i = 1:length(listTypes)
                dataTypeLists.(listTypes{i}) = internal.matlab.importtool.server.ImportToolColumnTypes.getDataTypeList(listTypes{i});
            end

            this.setTableModelProperties(...
                'initialSelection', initialSelection, ...
                'ShowColumnHeaderLabels', true, ...
                'OutputVariableNameWarning', [], ...
                'dataTypeLists', dataTypeLists);
        end

        function updateTableModelInformation(this)
            % Selection MetaInfo needs to be updated before every table
            % model update
            this.updateSelectionMetaInfo();
            this.updateTableModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel();
        end

        function updateCellModelInformation(this, startRow, endRow,...
                startColumn, endColumn, fullRows, fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                startColumn (1,1) double {mustBeNonnegative}
                endColumn (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
                fullColumns (1,:) double = startColumn:endColumn
            end

            try
                this.updateCellStyles(startRow, endRow, startColumn, endColumn);
                this.updateCellModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startRow, endRow, startColumn, endColumn, fullRows, fullColumns);
            catch
            end
        end

        function updateRowModelInformation(this, startRow, endRow, fullRows)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
            end

            outputType = this.getTableModelProperty("OutputVariableType");
            if ~strcmp(outputType, "timetable")
                this.setRowModelProperties(startRow:endRow, "RowName", NaN);
            else
                % Sort to make sure the rows are ascending
                rows = sort([startRow, endRow]);
                r = this.getRowTimesProperties();
                excelSelection = this.getTableModelProperty("excelSelection");

                if r.rowTimesType == "column" && ~isempty(excelSelection)
                    [selectedRows, ~] = internal.matlab.importtool.server.ImportUtils.getRowsColsFromExcel(excelSelection);
                    colIdx = find(strcmp(this.getCurrentColumnVarNames(), r.rowTimesColumn));
                    colType = this.ColumnClasses(colIdx);

                    numIntervals = size(rows, 1);
                    for interval = 1:numIntervals
                        [~, editValues, dateValues] = this.DataModel.getData(rows(interval,1), rows(interval,2), colIdx, colIdx);
                        rowNames = string(editValues);
                        if colType == "duration"
                            invalidIdx = ~contains(rowNames, ":");
                            rowNames(invalidIdx) = "NaN";
                        elseif colType == "datetime"
                            emptyIdx = cellfun('isempty', dateValues);
                            if all(emptyIdx)
                                dtFormat = this.ColumnClassOptions{colIdx};
                                try
                                    dateValues = datetime(editValues, "InputFormat", dtFormat, "Format", dtFormat);
                                catch
                                    dateValues = cellfun(@this.convertEmptyDatetimes, ...
                                        editValues, "ErrorHandler", @(x,y) NaT);
                                end
                                rowNames = string(dateValues);
                                rowNames(ismissing(rowNames)) = "NaT";
                            else
                                rowNames(emptyIdx) = "NaT";
                            end
                        end

                        intervalStartRow = rows(interval, 1);
                        intervalEndRow = rows(interval, 2);

                        % It is possible we got back less data than the range is
                        % for (empty rows, for example).  Pad the rowNames if
                        % needed.  This is a no-op if the sizes match.
                        rowNames(end+1:(intervalEndRow - intervalStartRow) + 1) = "";

                        fullSelection = [];
                        numSelectedIntervals = size(selectedRows, 1);
                        for selectedIndex = 1:numSelectedIntervals
                            fullSelection = [fullSelection, selectedRows(selectedIndex,1):selectedRows(selectedIndex,2)]; %#ok<AGROW>
                        end
                        for idx = startRow:endRow
                            rowNamesIdx = idx - rows(1) + 1;
                            if any(idx == fullSelection)
                                this.setRowModelProperty(idx, "RowName", rowNames(rowNamesIdx), false);
                            else
                                this.setRowModelProperty(idx, "RowName", "", false);
                            end
                        end
                    end
                else
                    % Update the row times which may be displayed.
                    for idx = startRow:endRow
                        this.setRowModelProperty(idx, "RowName", this.RowNames(idx));
                    end
                end
            end

            this.updateRowModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                startRow, endRow, fullRows);
        end

        function updateClient(this)
            try
                eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                dataSize = this.getTabularDataSize();
                % Setting to entire size will ensure that databuffer is
                % cleared and view is updated
                endColumn = this.DataModel.getColumnCount;
                eventdata.StartRow = 1;
                eventdata.EndRow = dataSize(1);
                eventdata.StartColumn = 1;
                eventdata.EndColumn = endColumn;

                eventdata.SizeChanged = true;
                % DataChange event takes care of a full refresh
                this.notify('DataChange', eventdata);

                % The meta data may have also changed because the column
                % datatypes may be different.  See g1953156
                changeEventData = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                changeEventData.Column = 1:endColumn;
                this.notify('TableMetaDataChanged',changeEventData);
                this.notify('ColumnMetaDataChanged',changeEventData);
            catch e
                disp (e);
            end
        end

        function getNewDataModel(this, forceColClassUpdate)
            arguments
                this
                forceColClassUpdate (1,1) logical = false;
            end
            currSelection = this.getTableModelProperty('excelSelection');
            if isempty(currSelection)
                cols = 0;
            else
                [~, cols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(currSelection);
            end
            if(cols(end)> this.DataModel.getColumnCount)
                initialSelection = this.DataModel.getInitialSelection();
                newSelection = internal.matlab.importtool.server.ImportUtils.toExcelRange(initialSelection(1), initialSelection(3), initialSelection(2), this.DataModel.getColumnCount);
                this.setImportSelection(newSelection, "server");
            end

            headerRow = this.getTableModelProperty('VariableNamesRow');
            avoidShadow = this.getAvoidShadowForOutputType();
            this.DataModel.getColumnNames(headerRow, avoidShadow);
            dmColClasses = this.DataModel.getColumnClasses();
            if ~isequal(length(this.ColumnClasses), length(dmColClasses)) || forceColClassUpdate
                this.ColumnClasses = dmColClasses;
                this.ColumnClassOptions = this.DataModel.getColumnClassOptions();
            end

            t = internal.matlab.importtool.server.OutputTypeFactory.getOutputTypeFromText(this.getTableModelProperty('OutputVariableType'));
            this.setImportColumnClass(1:this.DataModel.getColumnCount(), t.getColumnClasses(this.ColumnClasses), t.getColumnClassOptions(this.ColumnClassOptions));

            %             state = this.DataModel.getState();
            %             this.ColumnWidths = num2cell(state.VariableWidths * this.SingleCharWidth);
        end
    end

    methods (Access = {?internal.matlab.importtool.peer.RemoteTabularImportViewModel, ?matlab.unittest.TestCase})
        function d = convertEmptyDatetimes(this, val)
            d = this.DataModel.convertEmptyDatetimes(val);
        end

        function triggerRowModelUpdate(this, startRow, endRow, fullRows)
            this.updateRowModelInformation(startRow, endRow, fullRows);
        end

        function triggerColumnModelUpdate(this, startRow, endRow, fullCols)
            this.updateColumnModelInformation(startRow, endRow, fullCols);
        end

        function triggerTableModelUpdate(this)
            this.updateTableModelInformation();
        end

        function triggerUpdateSelectionMetaInfo(this)
            this.updateSelectionMetaInfo();
        end

        function resetCellBackgroundColor(this, row, col)
            if any([row,col] > size(this.CellProperties))
                return
            end

            cellProperties = this.CellProperties{row, col};

            if (isfield(cellProperties, 'isReplacementValue') && cellProperties.isReplacementValue == true) || ...
                    (isfield(cellProperties, 'isExclusionValue') && cellProperties.isExclusionValue == true)

                this.setCellModelProperty(row, col, 'isReplacementValue', false, false);
                this.setCellModelProperty(row, col, 'isExclusionValue', false, false);

                this.CellProperties{row, col} = struct('isReplacementValue', false, ...
                    'isExclusionValue', false);
            end
        end

        function setCellReplacement(this, row, col)
            cellProperties = this.CellProperties{row, col};

            if ~isfield(cellProperties, 'isReplacementValue') || ...
                    cellProperties.isReplacementValue ~= true || ...
                    cellProperties.isExclusionValue ~= false

                this.setCellModelProperty(row, col, 'isReplacementValue', true, false);
                this.setCellModelProperty(row, col, 'isExclusionValue', false, false);

                this.CellProperties{row, col} = struct('isReplacementValue', true, ...
                    'isExclusionValue', false);
            end
        end

        function setCellExclusion(this, row, col)
            cellProperties = this.CellProperties{row, col};

            if ~isfield(cellProperties, 'isExclusionValue') || ...
                    cellProperties.isReplacementValue ~= false || ...
                    cellProperties.isExclusionValue ~= true

                this.setCellModelProperty(row, col, 'isReplacementValue', false, false);
                this.setCellModelProperty(row, col, 'isExclusionValue', true, false);

                this.CellProperties{row, col} = struct('isReplacementValue', false, ...
                    'isExclusionValue', true);
            end
        end

        function updateCellStyles(this, startRow, endRow, startColumn, endColumn)
            if ~isempty(startRow) && ...
                    ~isempty(endRow) && ...
                    ~isempty(startColumn) && ...
                    ~isempty(endColumn) && ...
                    ~isempty(this.DocumentSize)
                data = this.getRawRenderedData(startRow, endRow, startColumn, endColumn);

                selectionRows = this.SelectedRowIntervals;
                selectionColumns = this.SelectedColumnIntervals;

                for row = startRow:endRow
                    for col = startColumn:endColumn
                        if this.cellIsOutsideSelection(row, col, selectionRows, selectionColumns)
                            this.resetCellBackgroundColor(row, col);
                        else
                            thisOperation = data.valueType{row - startRow + 1, col - startColumn + 1};
                            if strcmp(thisOperation, 'isReplacedBy')
                                this.setCellReplacement(row, col);
                            elseif strcmp(thisOperation, 'isRowExcluded') || ...
                                    strcmp(thisOperation, 'isColExcluded')
                                this.setCellExclusion(row, col);
                            elseif strcmp(thisOperation, 'isConvertedTo')
                                this.resetCellBackgroundColor(row, col);
                            end
                        end
                    end
                end
            end
        end
    end

    methods
        % destructor called when the class object is deleted.
        % The delete method is overridden to ensure that the listeners are
        % deleted from the memory once the object is destroyed
        function delete(this)
            internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab('');
            this.delete@internal.matlab.importtool.server.TabularImportViewModel();
            delete(this.workspaceListener);
            delete(this.RedrawStylesListener);
        end
    end
end
