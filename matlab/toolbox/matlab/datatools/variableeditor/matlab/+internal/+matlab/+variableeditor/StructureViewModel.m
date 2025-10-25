classdef StructureViewModel < ...
        internal.matlab.variableeditor.ArrayViewModel
    %STRUCTUREVIEWMODEL base view model class for scalar structs

    % Copyright 2013-2024 The MathWorks, Inc.

    properties (SetObservable=false, SetAccess='protected', GetAccess='protected', Dependent=false, Hidden=false)
        MetaData = [];
    end

    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=false, Hidden=false)
        % Here ColumnIndex is the ColumnIndex of the fieldCol w.r.t Data,
        % not the visible column index w.r.t to view.
        SortedColumnInfo = struct('ColumnIndex',[],'SortOrder',[]);
        SortedColumnViewIndex = [];
    end

    properties(SetAccess='protected')
        FieldColumnList containers.Map
        VisibleFieldColumnList containers.Map
        OrderedFields;
        SortedIndices = [];
    end

    properties(SetAccess='protected', Transient)
        SettingsListener;
    end

    properties(Access='private')
        FieldColumnsBuffer containers.Map
    end

    properties(SetObservable=true, Hidden=true)
        NumColumnsShown;
    end

    properties (SetObservable=true, SetAccess={?matlab.unittest.TestCase, ?internal.matlab.variableeditor.StructureViewModel}, GetAccess='public', Dependent=false, Hidden=false)
        SelectedFields string = [];
    end

    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = StructureViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
            this.FieldColumnList = containers.Map('KeyType', 'double', 'ValueType', 'any');
            this.VisibleFieldColumnList = containers.Map('KeyType', 'double', 'ValueType', 'any');
            % All removed columns will be added to buffer, in case user
            % adds back these columns.
            this.FieldColumnsBuffer = containers.Map;
        end

        % getSize for struct view. Number of columns will be the columns
        % that are visible.
        function s = getSize(this)
            s = this.DataModel.getSize();
            numOutputColumns = this.VisibleFieldColumnList.Count;
            % If fieldColumnList is empty, fetch from settingsController.
            % This can happen when the view initFieldColumns is not yet
            % triggered, but document needs row|column count to publish.
            if isempty(this.VisibleFieldColumnList)
                settingsController = this.getSettingsController(this.userContext);
                cols = internal.matlab.variableeditor.StructureViewModel.getVisibleColumns(settingsController);
                numOutputColumns = length(cols);
            end
            s = double([(s(1)) numOutputColumns]);
        end

        % Adds the provided fieldColumn to the current viewmodel.
        function addFieldColumn(this, fieldColumn)
            % Function argument checking removed as it doesn't provide much
            % value, but it does affect performance slightly
            % arguments
            %     this (1,1) internal.matlab.variableeditor.StructureViewModel;
            %     fieldColumn (1,1) internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
            % end
            this.FieldColumnList(fieldColumn.ColumnIndex) = fieldColumn;
            if fieldColumn.Visible
                this.VisibleFieldColumnList(fieldColumn.ColumnIndex) = fieldColumn;
            end
        end

        % Removes field column from viewModel
        function removeFieldColumn(this, columnIndex)
            % Note: Does not delete the field column, cycles it back to
            % buffer
            if (isKey(this.FieldColumnList, columnIndex))
                fCol = this.FieldColumnList(columnIndex);
                this.FieldColumnsBuffer(fCol.HeaderName) = fCol;
                remove(this.FieldColumnList, columnIndex);
            end
            if (isKey(this.VisibleFieldColumnList, columnIndex))
                remove(this.VisibleFieldColumnList, columnIndex);
            end
        end

        function fieldCol = createFieldColumn(this, fieldColumnName)
            settingsController = this.getSettingsController(this.userContext);
            fieldCol = this.evaluateFieldCol(settingsController, fieldColumnName);
            this.DataModel.NumberOfColumns = this.FieldColumnList.Count;
            % TODO: Make NumberOfColumns an observable property
            this.DataModel.updateCachedSize();
        end

        % Fetches field that was previously unavailable on the view
        function fieldCol = fetchRemovedFieldColumn(this, columnName)
            fieldCol = [];
            if (isKey(this.FieldColumnsBuffer, columnName))
                fieldCol = this.FieldColumnsBuffer(columnName);
            end
        end

        % Names of all unavailable fields on the view
        function removedFields = getRemovedFields(this)
            removedFields = keys(this.FieldColumnsBuffer);
        end

        % Finds field by their columnIndex. NOTE: To find by ColumnNumber,
        % use findVisibleField.
        function fieldColumn = findField(this, columnIndex)
            fieldColumn = [];
            if (isKey(this.FieldColumnList, columnIndex))
                fieldColumn = this.FieldColumnList(columnIndex);
            end
        end

        % Finds field by ColumnNumber from the set of visible columns.
        function fieldColumn = findVisibleField(this, columnIndex)
            fieldColumn = [];
            indices = keys(this.VisibleFieldColumnList);
            if (columnIndex <= length(indices)) && (isKey(this.VisibleFieldColumnList, indices{columnIndex}))
                fieldColumn = this.VisibleFieldColumnList(indices{columnIndex});
            end
        end

        % Given headerName, finds the field from FieldColumnList.
        % Optional Param: findIfHidden will find from unavailable fields if
        % set to true.
        function fieldColumn = findFieldByHeaderName(this, HeaderName, findIfHidden)
            arguments
                this
                HeaderName
                findIfHidden = false;
            end
            fieldColumn = [];
            fieldKeys = keys(this.FieldColumnList);
            for index = 1:length(fieldKeys)
                fCol = this.FieldColumnList(fieldKeys{index});
                if strcmp(fCol.getHeaderName(), HeaderName)
                    fieldColumn = fCol;
                    break;
                end
            end
            if findIfHidden && isempty(fieldColumn)
                fieldColumn = this.fetchRemovedFieldColumn(HeaderName);
            end
        end
        
        function [renderedData, renderedDims, classValues, columnFields, accessValues] = getRenderedData(...
                this, startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims, classValues, columnFields, accessValues] = this.getDisplayData(...
                startRow, endRow, startColumn, endColumn);
        end

        % In addition to renderedData and renderedDims, this also returns
        % classValues computed (needed for icons on Name column) and
        % fieldColumns of fields visible.
        function [renderedData, renderedDims, classValues, columnFields, accessValues] = getDisplayData(...
                this, startRow, endRow, startColumn, endColumn)
            % This method always returns all columns of data, since there
            % is only a predefined number of columns.
            % Returns renderedData which is a cell array with each row
            % being a field in the structure, and the columns are:
            % 1 - field name
            % 2 - displayed value
            % 3 - size
            % 4 - class
            classValues = {};
            accessValues = {};
            columnFields = {};
            data = this.getData();
            fieldNames = this.getFields(data);
            endRow = min(endRow, length(fieldNames));
            numRows = min(endRow - startRow + 1, length(fieldNames));
            numColsToCompute = endColumn - startColumn + 1;
            renderedData = cell([numRows numColsToCompute]);
            if numRows > 0
                [cellData, virtualVals, accessValues] = this.getRenderedCellData(data, fieldNames);
                if ~isempty(this.SortedIndices)
                    fieldNames = fieldNames(this.SortedIndices);
                    cellData = cellData(this.SortedIndices);
                end
                % TODO: Compute once and cache until data changes in dm
                this.OrderedFields = fieldNames;

                columnFields = cell([1, numColsToCompute]);
                curColumnIdx = 1;
                for col = startColumn: endColumn
                    fieldColumn = this.findVisibleField(col);
                    curColumn = col;
                    % FormatAsSingleCell to get display data for a single
                    % cell.
                    if this.FormatAsSingleCell
                        curColumn = curColumnIdx;
                    end
                    renderedData(:, curColumn) = fieldColumn.getData(startRow, endRow, cellData, fieldNames, virtualVals, data);
                    hName = fieldColumn.getHeaderName();
                    if strcmp(hName, internal.matlab.variableeditor.FieldColumns.ClassCol.COLUMN_NAME)
                        classValues = renderedData(:, curColumn);
                    end
                    columnFields{curColumn} = fieldColumn;
                    curColumnIdx = curColumnIdx + 1;
                end

                % If classcol is hidden, we still want to compute classes to
                % update the right icons in the name column
                if isempty(classValues)
                    % Find class column even if unavailable on the view
                    classCol = this.findFieldByHeaderName(internal.matlab.variableeditor.FieldColumns.ClassCol.COLUMN_NAME, true);
                    classValues = classCol.getData(startRow, endRow, cellData, fieldNames, virtualVals, data);
                end
            end
            renderedDims = size(renderedData);
        end

        % setData
        function varargout = setData(this,varargin)
            % Simple case, all of data replaced
            if nargin == 2
                varargout{1} = this.setData@internal.matlab.variableeditor.ArrayViewModel(varargin{:});
                return;
            end
            % Check for paired values.  varargin should be triplets, or
            % triplets with an error message string at the end
            if rem(nargin-1, 3)~=0 && ...
                    (rem(nargin-2, 3)==0 && ~ischar(varargin{nargin-1}))
                error(message('MATLAB:codetools:variableeditor:UseNameRowColTriplets'));
            end

            s = this.getData();
            fn = this.getFields(s);
            sortedFn = fn;
            if ~isempty(this.SortedIndices)
                sortedFn = fn(this.SortedIndices);
            end

            % Range(s) specified (value-range pairs)
            args = cell(nargin-1,1);
            for i=3:3:nargin
                newValue = varargin{i-2};
                row = varargin{i-1};
                column = varargin{i};

                % row number here will be w.r.t sorted view, we need to
                % find this index in fn for datamodel update.
                row = find(matches(fn, sortedFn{row}));
                args{i} = column;
                args{i-1} = row;
                args{i-2} = newValue;
            end
            args{end} = varargin{end};
            varargout{1} = this.setData@internal.matlab.variableeditor.ArrayViewModel(args{:});
        end

        function varargout = setSelection(this,selectedRows,selectedColumns,selectionSource,selectionArgs)
            arguments
                this
                selectedRows
                selectedColumns
                selectionSource = 'server'% This is an optional parameter to indicate the source of the selection change.
                selectionArgs.selectedFields = []
                selectionArgs.updateFocus (1,1) logical = true
            end
            args = namedargs2cell(selectionArgs);
            varargout{1} = this.setSelection@internal.matlab.variableeditor.ArrayViewModel(selectedRows, selectedColumns, ...
                selectionSource, args{:});
            this.setSelectedFields(this.SelectedRowIntervals);
        end

        function varargout = getFormattedSelection(this, varargin)
            selectionString = '';
            fields = this.getFields(this.DataModel.Data);

            % used to eval the expression below to make sure it is valid
            data = this.DataModel.Data; %#ok<NASGU>
            rowIntervals = this.SelectedRowIntervals;
            name = this.DataModel.Name;
            if ~isempty(fields)
                % In case of a sort, update fields to be in the sorted
                % order.
                if ~isempty(this.SortedIndices)
                    fields = fields(this.SortedIndices);
                end

                if ~isempty(rowIntervals)
                    for i=1:size(rowIntervals,1)
                        if i > 1
                            selectionString = [selectionString ';']; %#ok<AGROW>
                        end
                        % case when individual disjoint fields are selected
                        if (rowIntervals(i,1) == rowIntervals(i,2))
                            try
                                eval('data.(fields{rowIntervals(i,1)});');
                                selectionString = [selectionString name '.' ...
                                    char(fields(rowIntervals(i,1)))]; %#ok<AGROW>
                            catch
                            end
                        else
                            % case when a range of subsequent fields are selected
                            for j=(rowIntervals(i,1)):(rowIntervals(i,2))
                                try
                                    if j > rowIntervals(i,1)
                                        selectionString = [selectionString ';']; %#ok<AGROW>
                                    end
                                    eval('data.(fields{j});');
                                    selectionString = [selectionString name '.' ...
                                        char(fields(j))]; %#ok<AGROW>
                                catch
                                end
                            end
                        end
                    end
                end
            end
            varargout{1} = selectionString;
        end

        % Public API to show/hide a column. fieldColumnName is a required
        % argument.
        % isVisible is optional and by default, the API sets visibility of
        % the column to be true.
        function setColumnVisible(this, fieldColumnName, isVisible)
            if nargin < 3
                isVisible = true;
            end
            fieldCol = this.findFieldByHeaderName(fieldColumnName);
            % The column has not yet been created, lazily create the
            % column.
            if isempty(fieldCol)
                fieldCol = this.createFieldColumn(fieldColumnName);
            end
            % If isVisible is different from that of field column's
            % 'Visible' state, update
            if ~isequal(fieldCol.Visible, isVisible)
                fieldCol.Visible = isVisible;
                this.handleShowHideField(fieldCol);
            end
        end

        function handleShowHideField(this, fieldColumn)
            columnIndex = fieldColumn.ColumnIndex;
            isCurrentlyVisible = isKey(this.VisibleFieldColumnList, columnIndex);
            % flipping from hidden to visible
            if fieldColumn.Visible
                if ~isCurrentlyVisible
                    this.VisibleFieldColumnList(columnIndex) = fieldColumn;
                end
            elseif isCurrentlyVisible % flipping from visible to hidden
                remove(this.VisibleFieldColumnList, columnIndex);
            end
            this.NumColumnsShown = this.VisibleFieldColumnList.Count;
        end

        % Handles Column Re-ordering by swapping out subsequent columns
        % from sourceIndex to targetIndex in the correct direction
        % FieldColumnList and VisibleFieldColumnList will have the updated
        % fieldColumns.
        function handleColumnReorder(this, sourceIndex, targetIndex)
            if targetIndex > sourceIndex
                inc = 1;
            else
                inc = -1;
            end
            for i=sourceIndex:inc:(targetIndex-inc)
                j=i+inc;
                try
                    col1 =  this.findVisibleField(i);
                    col2 = this.findVisibleField(j);
                    temp = col1.ColumnIndex;
                    col1.ColumnIndex = col2.ColumnIndex;
                    col2.ColumnIndex = temp;
                    this.FieldColumnList(col1.ColumnIndex)=col1;
                    this.FieldColumnList(col2.ColumnIndex)=col2;
                    this.VisibleFieldColumnList(col1.ColumnIndex)=col1;
                    this.VisibleFieldColumnList(col2.ColumnIndex)=col2;
                catch e
                    % Something went wrong on column swap.
                end
            end
        end

        % API to refresh data for a column range (startCol:endCol)
        function refreshColumnRange(this, startCol, endCol, sizeChange)
            size = this.getSize();
            % Update data and metadata for the affected viewport
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.StartRow = 1;
            eventdata.EndRow = size(1);
            eventdata.StartColumn = startCol;
            eventdata.EndColumn = endCol;
            eventdata.SizeChanged = sizeChange;
            this.notify('DataChange',eventdata);
        end

        function selectedFields = getSelectedFields(this)
            selectedFields = this.SelectedFields;
        end

        function fieldData = getFieldData(~, data, fn)
            try
                fieldData = data.(fn);
            catch e
                fieldData = [];
            end
        end


        % cleanup listener
        function delete(this)
            if ~isempty(this.SettingsListener)
                delete(this.SettingsListener);
                this.SettingsListener = [];
            end
        end
    end

    methods (Access = protected)

        function isEditable = isColumnEditable(~, fieldColumn)
            isEditable = fieldColumn.Editable;
        end

        % Determine if the given column is custom. A custom column is not
        % included in the base Variable Editor; instead, it is created by
        % a separate team that needs their own columns suitable for their
        % use cases.
        %
        % This is intended to be overridden.
        % Argument 1: this
        % Argument 2: columnNumber
        function isField = isCustomColumn(~, ~)
            isField = false;
        end

        % Returns the SettingsController for the view if registered for the
        % current view's context, else returns [].
        function controller = getSettingsController(this, userContext)
            settingsRegnMap = this.getSettingRegistrationMap();
            if isKey(settingsRegnMap, userContext) && settingsRegnMap(userContext)
                controller = this.getFieldSettingsInstance();
                if ~isempty(controller) && isempty(this.SettingsListener)
                    this.SettingsListener = event.listener(controller, 'StatSettingChange',@(es,ed)this.handleSettingChange);
                end
            else
                controller = [];
            end
        end

        % Whenever settings change, refresh the viewport that affect stat columns.
        function handleSettingChange(this)
            fieldKeys = keys(this.VisibleFieldColumnList);
            statColIndices = [];
            for index = 1:length(fieldKeys)
                fCol = this.VisibleFieldColumnList(fieldKeys{index});
                if isa(fCol, 'internal.matlab.variableeditor.FieldColumns.StatColumn')
                    statColIndices(end+1) = index;
                end
            end
            if ~isempty(statColIndices)
                this.refreshColumnRange(min(statColIndices), max(statColIndices), false);
            end
        end

        function fieldSettings = getFieldSettingsInstance(~)
            fieldSettings = internal.matlab.variableeditor.FieldColumns.StructFieldSettings.getInstance;
        end

        % This method updates SortIndices every time a sort action is
        % performed on the field columns.
        function handleSortAscending(this)
            if ~isempty(this.SortedColumnInfo.ColumnIndex)
                % On empty DataModel, clear SortedIndices and return.
                if isempty(this.getFields(this.DataModel.Data))
                    this.SortedIndices = [];
                    return;
                end
                data = this.getData();
                fieldNames = this.getFields(data);
                colIndex = this.SortedColumnInfo.ColumnIndex;
                % find field even if it's not visible, sortedIndices might
                % have to be computed even when a column is hidden
                fieldColumn = this.findField(colIndex);
                fieldColumn.setSortAscending(this.SortedColumnInfo.SortOrder);

                [cellData, virtualVals] = this.getRenderedCellData(data, fieldNames);
                this.SortedIndices = fieldColumn.getSortedIndices(cellData, fieldNames, virtualVals, data);

                if colIndex > 1
                this.setTableModelProperty('LastSorted', struct('index', colIndex -1, 'order', this.SortedColumnInfo.SortOrder), true);
                end
                this.SortedColumnViewIndex = colIndex - 1;
            end
        end

        % The view could have sorted fields. If there is
        % an incoming data change and we have a sort applied, publish
        % DataChange with the corrected indices.
        function handleDataChangedOnDataModel(this, es, ed)
            % Update SortedIndices in case of a sizeChanged
            sizeDiff = 0;
            if (ed.SizeChanged)
                % If there is a size changed, call the sortAscending method to
                % update the indices.  Compute the difference in size.  (If
                % sorted alphabetically by name, SortedIndices could be [], but
                % that's ok because we only need the sizeDiff if not sorted
                % alphabetically).
                sz = this.getSize();
                sizeDiff = length(this.SortedIndices) - sz(1);
                this.handleSortAscending();
            end
            this.handleDataChangedOnDataModel@internal.matlab.variableeditor.ArrayViewModel(es, ed);
        end

        function initFieldColumns(this, userContext)
            settingsController = this.getSettingsController(userContext);
            visibleCols = internal.matlab.variableeditor.StructureViewModel.getVisibleColumns(settingsController);
            for i=1:length(visibleCols)
                this.evaluateFieldCol(settingsController, visibleCols{i});
            end
            % Always ensure that Class column has been initialized. This is
            % used by Name Column for displaying the right icons. 
            classCol = internal.matlab.variableeditor.FieldColumns.ClassCol.COLUMN_NAME;
            if ~any(strcmp(visibleCols, classCol))
                this.evaluateFieldCol(settingsController, classCol);
            end
            this.NumColumnsShown = this.VisibleFieldColumnList.Count;
            this.DataModel.NumberOfColumns = this.FieldColumnList.Count;
            this.DataModel.updateCachedSize();
        end

        function col = evaluateFieldCol(this, settingsController, colName)
            fieldColsMap = internal.matlab.variableeditor.FieldColumns.StructFieldsList.FieldColumnsMap;
            className = fieldColsMap.(colName);
            constructor = str2func(className);
            col = constructor();
            if ~isempty(settingsController)
                col.SettingsController = settingsController;
            end
            this.addFieldColumn(col);
        end

        function fields = getFields(~, data)
            % Protected method to get the fields from the data.
            % Because objects reuse much of the structure code, they
            % can override this method to call properties instead of
            % fieldnames.
            fields = fieldnames(data);
        end

        function setSelectedFields(this, selectedRows, selectedColumns, selectionSource, selectedFields)
            arguments
                this
                selectedRows = []
                selectedColumns = [] 
                selectionSource = ''
                selectedFields = {}
            end
            s = this.getData();
            currFields = this.getFields(s);
            if ~isempty(this.SortedIndices)
                currFields = currFields(this.SortedIndices);
            end
            this.SelectedFields = [];
            for i=1:size(selectedRows,1)
                for j=selectedRows(i,1):selectedRows(i,2)
                    this.SelectedFields(end+1) = currFields{j};
                end
            end
        end

        function isValid = isValidFieldName(~, data)
            [~, isModified] = matlab.lang.makeValidName(data);
            isValid = ~isModified;
        end

        function [cellData, virtualVals, accessVals] = getRenderedCellData(~, data, fieldNames)
            % Return a cell array containing the values of the data
            if isstruct(data)
                cellData = struct2cell(data);
            else
                cellData = cellfun(@(x) data.(x), fieldNames, ...
                    'UniformOutput', false, ...
                    'ErrorHandler', @(~,~) []);
            end
            virtualVals = false(size(fieldNames));
            
            % For a struct, access is always considered public
            accessVals = repmat({'public'}, size(fieldNames));
        end
    end

    methods(Static, Access='protected')
        function visibleCols = getVisibleColumns(settingsController)
            if ~isempty(settingsController)
                visibleCols = settingsController.getVisibleCols();
            else
                visibleCols = internal.matlab.variableeditor.FieldColumns.StructFieldsList.DefaultVisibleCols;
            end
        end
    end

    methods(Access={?matlab.mock.TestCase})
        function fields = test_getFields(this, data)
            fields = this.getFields(data);
        end
    end
end
