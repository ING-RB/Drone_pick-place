classdef RemoteStructureViewModel < internal.matlab.variableeditor.peer.RemoteArrayViewModel & internal.matlab.variableeditor.StructureViewModel
    % REMOTESTRUCTUREVIEWMODEL Remote Model Structure View Model for scalar structures

    % Copyright 2013-2025 The MathWorks, Inc.

    properties (Access='protected', Transient)
        SortAscendingListener;
    end

    methods
        function this = RemoteStructureViewModel(document, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.StructureViewModel(variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(document, variable, 'viewID', viewID);

            % Add Listener to Set Property
            this.SortAscendingListener = event.proplistener(this, this.findprop('SortedColumnInfo'), 'PostSet', @(es, ed) this.handleSortAscending());

            this.initFieldColumns(userContext);
        end

        % just set class as table metadata for structs.
        function initTableModelInformation(this)
            this.setTableModelProperty('class', 'char', false);
        end

        % Handles remote events from client. On ColumnReordered, handle
        % reordering on the view.
        function handleEventFromClient(this, es, ed)
            this.handleEventFromClient@internal.matlab.variableeditor.peer.RemoteArrayViewModel(es, ed);
            if strcmp(ed.data.type, 'ColumnReordered')
                this.handleColumnReorder(ed.data.sourceIndex, ed.data.targetIndex);
            end
        end


        % This is to force refresh and update the column headers when
        % they are turned on/off via context menu
        function handleShowHideField(this, fieldColumn)
            this.handleShowHideField@internal.matlab.variableeditor.StructureViewModel(fieldColumn);

            % If the column is hidden and is Sorted, remove LastSorted
            % property, else update LastSorted property
             if ~isempty(this.SortedColumnInfo.ColumnIndex) && (this.SortedColumnInfo.ColumnIndex == fieldColumn.ColumnIndex)
                if ~fieldColumn.Visible
                    % Set LastSorted to -1 so the sort indicator can be cleared on the client.
                    this.setTableModelProperty('LastSorted', struct('index', -1, 'order', this.SortedColumnInfo.SortOrder), false);
                else
                    this.setTableModelProperty('LastSorted', struct('index', this.SortedColumnViewIndex , 'order', this.SortedColumnInfo.SortOrder), false);
                end
                this.sendTableModelInformationDebounced();
             end
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.SizeChanged = true;
            this.notify('DataChange',eventdata);

            % Update columnMetaData as well
            this.updateColumnModelInformation(1, this.NumColumnsShown);
        end

        % NOOP Override from RemoteArrayViewModel, Do not update selection
        % ranges
        function updateSelectionRange(~)
        end

        % ON Column re-order, call superclass to update internal
        % data structures referencing fieldColumns
        % Update metadata and data for the range within which re-order took place.
        function handleColumnReorder(this, sourceIndex, targetIndex)
            if iscell(sourceIndex)
                sourceIndex = str2double(sourceIndex{1});
            end
            sortedColumnField = [];
            if ~isempty(this.SortedColumnInfo.ColumnIndex)
                sortedColumnField = this.findField(this.SortedColumnInfo.ColumnIndex);
            end
            this.handleColumnReorder@internal.matlab.variableeditor.StructureViewModel(sourceIndex, targetIndex);
            startColRange = min(sourceIndex, targetIndex);
            endColRange = max(sourceIndex, targetIndex);
            this.refreshColumnRange(startColRange, endColRange);
            % If sorted column index exists, always compute newer index and reset. (The column placement could be affected by the move)
            if ~isempty(sortedColumnField)
                % ColumnIndex is the underlying index (Not visible index)
                this.SortedColumnInfo.ColumnIndex = sortedColumnField.ColumnIndex;
                for visibleFieldIndex=startColRange:endColRange
                    % To find the visible column index on view, find the column with this sorted ColumnIndex within the updated range.
                    field = this.findVisibleField(visibleFieldIndex);
                    if field.ColumnIndex == sortedColumnField.ColumnIndex
                        this.setTableModelProperty('LastSorted', struct('index', visibleFieldIndex - 1, 'order', this.SortedColumnInfo.SortOrder), false);
                        this.SortedColumnViewIndex = visibleFieldIndex - 1;
                        this.sendTableModelInformationDebounced();
                        break;
                    end
                end
            end
        end
        
        function refreshColumnRange(this, startCol, endCol, sizeChange)
            arguments
                this
                startCol
                endCol
                sizeChange = false;
            end
            this.refreshColumnRange@internal.matlab.variableeditor.StructureViewModel(startCol, endCol, sizeChange);
            this.updateColumnModelInformation(startCol, endCol);
        end
        
        % NOOP, arguments are: this, startCol, endCol
        function updateColumnWidths(~, ~, ~)
        end
    end

    methods(Access='protected')

        function handleDataChangedOnDataModel(this, es ,ed)
            this.handleDataChangedOnDataModel@internal.matlab.variableeditor.StructureViewModel(es, ed);
            this.updateSelection();
        end

        % Updates headers and editability with columnmetadata update.
        function updateColumnModelInformation (this, startCol, endCol, fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startCol (1,1) double {mustBeNonnegative}
                endCol (1,1) double {mustBeNonnegative}
                fullColumns (1,:) double = startCol:endCol
            end
            this.ColumnModelChangeListener.Enabled = false;
            for col = startCol: endCol
                fieldColumn = this.findVisibleField(col);
                columnWidth = this.getColumnModelProperty(col, 'ColumnWidth');
                widthToSet = fieldColumn.ColumnWidth;
                % If columnWidth has changed in our metadata (via a column resize),
                % update fieldColumn's ColumnWidth.
                if ~isempty(columnWidth{1}) && ~isequal(columnWidth{1}, widthToSet)
                    fieldColumn.ColumnWidth = columnWidth{1};
                    widthToSet = fieldColumn.ColumnWidth;
                end
                if ~isempty(fieldColumn)
                    this.setColumnModelProperties(col,...
                        'HeaderName', fieldColumn.getHeaderTagName(),...
                        'DataAttributes', fieldColumn.getDataAttributes(),...
                        'IsSortable', fieldColumn.Sortable, ...
                        'editable', this.isColumnEditable(fieldColumn), ...
                        'ColumnWidth', widthToSet);
                end
            end
            this.ColumnModelChangeListener.Enabled = true;
            this.updateColumnModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startCol, endCol, fullColumns);
        end

        % NOTE: Not updating remote property here, send over
        % sortedIndex and sortOrder remotely if need be.
        % Handle sort on any of the field columns by computing SortIndices
        % and updating selection.
        function handleSortAscending(this)
            % Update sortIndices even on empty fields data, in case we have
            % stale sort indices on a sizeChanged.
            this.handleSortAscending@internal.matlab.variableeditor.StructureViewModel;
            if isempty(this.getFields(this.DataModel.Data))
                % Short circuit for empty struts
                return;
            end
            this.updateSelection();
        end

        function [renderedData, renderedDims] = renderData(this, data, classValues, fields, accessValues, ...
                startRow, endRow, startColumn, endColumn)
            rawData = this.getData();
            isVirtual = isa(rawData, "internal.matlab.variableeditor.VariableEditorPropertyProvider");
            numColumnsRequested = endColumn - startColumn + 1;
            renderedData = cell(size(data,1), numColumnsRequested);
            this.CellModelChangeListener.Enabled = false;
            CellMetaDataColIndices = [];

            % For each of the rows of rendered data, create the json object
            % string for each column's data.
            iterableRows = startRow: endRow;
            for row = 1:size(renderedData, 1)
                varName = this.OrderedFields{iterableRows(row)};
                isEditable = this.isFieldEditable(varName);
                for col = startColumn:endColumn
                    val = data{row,col};
                    dataObj = struct('value', val);
                    classVal = classValues{row};
                    fName = fields{col}.getHeaderName();
                    if any(strcmp(fName, ["Name", "Value"]))
                        if fName == "Name"
                            dataObj.class = classVal;
                            if ~isempty(accessValues)
                                dataObj.access = accessValues(row);
                            end
                            % For tall variables, fetch the underlying data
                            % and format in order to update icon with
                            % underlyingClass.
                            if strcmp(classVal, 'tall')
                                editVal = this.getFormattedData(rawData.(varName));
                                dataObj.class = internal.matlab.datatoolsservices.FormatDataUtils.formattedClassValue(editVal{1}, 'tall');
                            elseif any(strcmp(classVal, ["distributed", "codistributed", "gpuArray", "dlarray"]))
                                % For gpuArrays/distributed and co-distributed, we want to display the
                                % in-memory datatype icons on client, send over the underlying datatype.
                               underlyingtype = this.getUnderlyingDataType(rawData.(varName));
                               dataObj.class = internal.matlab.datatoolsservices.FormatDataUtils.formattedClassValue(underlyingtype, classVal);
                            end
                            % this clause is for a value class, send over
                            % additional info for editing.
                        else
                            if isVirtual && isVariableEditorVirtualProp(rawData, varName)
                                dataObj.isMetaData = true;
                                isEditable = true;
                            else
                                if strcmp(classVal,'string')
                                    dataObj.class = classVal;
                                end
                                dataValue = this.getFieldData(rawData, varName);
                                [val, editVal] = fields{col}.getEditValue(row, dataValue, val, this.DisplayFormatProvider.LongNumDisplayFormat);
                                if ~isequal(val, editVal)
                                    dataObj.editValue = editVal;
                                end
                                dataObj.editable = isEditable;
                                dataObj.isMetaData = fields{col}.isMetaData(row);
                            end

                            if ~isEditable
                                this.setCellModelProperty(row, col,...
                                    'editable', false);
                                CellMetaDataColIndices = union(CellMetaDataColIndices, col);
                            end
                        end
                        dataObj.editorValue = this.getSubVarName(this.DataModel.Name, varName);
                    else
                        dataObj.editable = fields{col}.Editable;
                    end

                    try
                        renderedData{row, col} = jsonencode(dataObj);
                    catch e
                        % There's a chance jsonencode throws an error, in which case it's handy
                        % to capture the error when logging.
                        internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteStructureViewModel", "error with jsonencode: " + e.identifier);
                    end
                end
            end

            this.CellModelChangeListener.Enabled = true;
            if ~isempty(CellMetaDataColIndices)
                this.updateCellModelInformation(startRow, endRow, min(CellMetaDataColIndices), max(CellMetaDataColIndices));
            end
            renderedDims = size(renderedData);
        end

        function isEditable = isFieldEditable(~, ~)
            % arguments are: this, fieldName
            isEditable = true;
        end

        % Fetch formattedData for a single cell from the rawData fetched from DataModel.
        function formattedData = getFormattedData(this, rawData)
            formattedData = this.formatSingleDataForMixedView(rawData);
        end
    end

    methods(Access = public)
        function [renderedData, renderedDims] = getRenderedData(this, ...
                startRow, endRow, startColumn, endColumn)
            % Get the rendered data from the StructureViewModel, and
            % reformat it for display in JS.
            renderedData = [];
            renderedDims = [];
            % onSizeChange, we could get requests for 0:0
            % startColumn:endColumn ranges as server does not have updated
            % viewport yet.
            if (startColumn > 0 && endColumn > 0)
                % Rendered data returns classValues and fieldColumns so
                % that they do not have to be re-computed at the remote
                % layer.
                [data, ~, classValues, fieldColumns, accessValues] = this.getRenderedData@internal.matlab.variableeditor.StructureViewModel(...
                    startRow, endRow, startColumn, endColumn);

                [renderedData, ~] = this.renderData(data, classValues, fieldColumns, accessValues, ...
                    startRow, endRow, startColumn, endColumn);

                % For editing use case, we might just get a cell range,
                % send back renderedData of correct dimensions for
                % getFormattedData call, the DataModel later updates necessary
                % data.
                renderedData = renderedData(:, startColumn:endColumn);
                renderedDims = size(renderedData);
            end
        end

        function subVarName = getSubVarName(~, Name, varName)
            subVarName = sprintf('%s.%s', Name, varName);
        end

        function varargout = setSelection(this,selectedRows,selectedColumns,selectionSource,selectionArgs)
            arguments
                this
                selectedRows
                selectedColumns
                selectionSource = 'server' % This is an optional parameter to indicate the source of the selection change.
                selectionArgs.selectedFields = []
                selectionArgs.updateFocus (1,1) logical = true
            end
            this.setSelectedFields(selectedRows, selectedColumns, selectionSource, selectionArgs.selectedFields);
            args = namedargs2cell(selectionArgs);
            varargout{1} = this.setSelection@internal.matlab.variableeditor.peer.RemoteArrayViewModel(selectedRows, selectedColumns, ...
                selectionSource, args{:});

            % updates the selected fields property which is used in drag
            % and drop
            if (ismember(selectionSource,["client","action"]))
                selectedFields = this.getSelectedFieldsForPropertySet(this.SelectedFields);
                this.setTableModelProperty('SelectedFields', selectedFields);
            end
        end
    end

    methods(Access='protected')

        % This formats SelectedFields to be set as TableModelProperty
        % Here, SelectedFileds is ',' separated list of field names of the struct.
        function formattedFields = getSelectedFieldsForPropertySet(this, ~)
            arguments
                this
                ~ % selection; unused since we manually grab selection
            end

            % Set the list of selected variables/fieldnames here
            selection = this.getFormattedSelection();
            selection = strjoin(strsplit(selection, {[this.DataModel.Name '.'], ';'}), ',');
            % Remove leading ',' (NOTE: Delimiter is appended from the client, 
            % It would be nice if delimiter was passed along with selection as well to avoid assumptions)
            formattedFields = selection(:, 2:end);
        end

        % This function is meant to be overridden by this class's children.
        % The second argument is the event data.
        function oldValue = getOldValueFromRenameEventData(this, ~)
            % Getting the old value this way slows down the more variables
            % there are within the workspace. Is there a way to get the old
            % value in a constant time?
            oldValue = this.getFields(this.getData());
            oldValue = oldValue{:};
        end

        % Handles Single Cell Data Edit from Client for a field name or field value.
        % 1. If this is a field name edit, check for valid field names and
        % process the edit. 
        % 2. Else, if value column edit, use superclass handleClientSetData
        % to check for valid data/quotes and process the edit.
        function handleClientSetData(this, eventData)
            % Get variables from event data.
            rawData = this.getStructValue(eventData, 'data');
            row = this.getStructValue(eventData, 'row');
            column = this.getStructValue(eventData, 'column');
            if ischar(row)
                row = str2double(row);
            end
            if ischar(column)
                column = str2double(column);
            end

            if this.isFieldNameColumn(column) % Rename action
                this.handleRenameAction(eventData, rawData, @this.isValidFieldName, row, column);
            else % Other actions
                this.handleClientSetData@internal.matlab.variableeditor.peer.RemoteArrayViewModel(eventData);
            end
        end

        % Handle a rename action (i.e., the user renames a variable).
        % The validation function is passed by the caller, since different
        % data types may be named. For example, invalid struct field names
        % are valid table variable names (tables are handled by
        % RemoteStructureTreeViewModel.m and similar files).
        function handleRenameAction(this, eventData, rawData, fieldNameValidationFn, row, column)
            oldValue = '';
            try
                if fieldNameValidationFn(rawData)
                    oldValue = this.getOldValueFromRenameEventData(eventData);
                    newValue = rawData;
                    code = this.handleFieldNameEdit(rawData, row, column);
                    this.notifyOnVariableEdit(row, column, oldValue, newValue, code);
                else
                    msgPrefix = this.getErrorOnInvalidRename(rawData);
                    msgSuffix = message('MATLAB:codetools:structArray:InvalidRenameMsgOnEdit', namelengthmax);
                    error(msgPrefix.string + msgSuffix.string);
                end
            catch e
                this.notifyOnEditError(e.message, row, column, oldValue, rawData);
            end
        end
        
        function notifyOnVariableEdit(this, row, column, currentValue, newValue, code)
            if iscell(code)
                % g2409560: The format of the "code" may be different
                % (string vs cell) for the WSB and VE.
                code = code{:};
            end
            if ~isempty(code)
                this.notifyVariableEdit('SingleCellEdit', row, column, currentValue, newValue, code);
            end
        end

        function notifyOnEditError(this, errorMsg, row, column, ~, newValue)
            errorMsg = internal.matlab.variableeditor.peer.PeerUtils.getSanitizedText(errorMsg);
            % Send data change event.
            this.sendEvent('dataChangeStatus', ...
                'status', 'error', ...
                'message', errorMsg, ...
                'title', getString(message('MATLAB:codetools:structArray:EditFailedTitle')), ...
                'errorType', 'warning', ...
                'row', row, ...
                'column', column, ...
                'newValue', newValue, ...
                'source', 'server');
        end

        function classType = getClassType(varargin)
            % Return container class type (struct), not the individual
            % field from the specified struct.  Decisions made on the class
            % type returned here only depend on the container type.
            classType = 'struct';
        end

        function updateSelection(this)
            if ~isempty(this.SelectedRowIntervals)
                % Only update the selection if the current selection isn't empty
                this.updateSelectedFields();
                selectedRowIntervals = this.SelectedRowIntervals;
                this.updateSelectedRowIntervals();

                % If intervals are different, update selection (unless they are
                % both empty)
                if ~(isempty(selectedRowIntervals) && isempty(this.SelectedRowIntervals)) && ~isequal(selectedRowIntervals, this.SelectedRowIntervals)
                    this.setSelection(this.SelectedRowIntervals, this.SelectedColumnIntervals);
                end
            end
        end

        function updateSelectedFields(this)
            % update the selected fields property
            updatedData = this.getData();
            newFields = string(this.getFields(updatedData))';
            if ~isempty(this.SortedIndices)
                newFields = newFields(this.SortedIndices);
            end
            currentSelectedFields = this.SelectedFields;
            isSelectedField = ismember(newFields, currentSelectedFields);
            this.SelectedFields = newFields(isSelectedField);
        end

        %change the selectedRowIntervals property accordingly
        function updateSelectedRowIntervals(this)
            updatedData = this.getData();
            newFields = string(this.getFields(updatedData))';

            if ~isempty(this.SortedIndices)
                newFields = newFields(this.SortedIndices);
            end

            this.SelectedRowIntervals = [];

            % counter to increment the selectedRowIntervals property
            countSelectedRowIntervals = 0;

            % keeps tracks of the prev Index to preserve ranges for block
            % selection
            prevIndex = -1;
            for l=1:length(this.SelectedFields)
                for currIndex=1:length(newFields)
                    if strcmp(this.SelectedFields(l),newFields(currIndex))
                        % case where consecutive rows are selected. They
                        % can be combined to a block
                        if prevIndex > 0 && currIndex-prevIndex == 1
                            this.SelectedRowIntervals(countSelectedRowIntervals,2) = currIndex;
                            % case where disjoint rows are selected
                        else
                            countSelectedRowIntervals = countSelectedRowIntervals + 1;
                            this.SelectedRowIntervals(countSelectedRowIntervals,1) = currIndex;
                            this.SelectedRowIntervals(countSelectedRowIntervals,2) = currIndex;
                        end
                    end
                end
            end
        end

        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteStructureViewModel';
        end

        % Returns true if the column is a HeaderName column. NOTE: query by
        % Name will always fetch the name column, only the tagName is I18ned.
        function isField = isFieldNameColumn(this, columnNumber)
            fieldColumn = this.findFieldByHeaderName("Name");
            isField = strcmp(this.getColumnModelProperty(columnNumber, 'HeaderName'), ...
                fieldColumn.getHeaderTagName());
        end

        function isField = isFieldVisibilityColumn(this, columnNumber)
            fieldColumn = this.findFieldByHeaderName("Visible");
            isField = strcmp(this.getColumnModelProperty(columnNumber, 'HeaderName'), ...
                fieldColumn.getHeaderTagName());
        end

        function code = handleFieldNameEdit(this, data, row, column)
            code = this.executeCommandInWorkspace(data, row, column);
        end

        function msg =  getErrorOnInvalidRename(~, rawData)
            fieldName = internal.matlab.datatoolsservices.VariableUtils.getTruncatedIdentifier(rawData);
            msg = message('MATLAB:codetools:structArray:InvalidRenameFieldOnEdit', fieldName);
        end
         
        function type = getUnderlyingDataType(~, rawData)
            type = underlyingType(rawData);
        end
    end
end
