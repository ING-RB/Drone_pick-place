classdef RemoteObjectViewModel < internal.matlab.variableeditor.peer.RemoteStructureViewModel & ...
        internal.matlab.variableeditor.ObjectViewModel
    % REMOTEOBJECTVIEWMODEL Remote Object View Model

    % Copyright 2014-2023 The MathWorks, Inc.

    methods
        function this = RemoteObjectViewModel(document, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end

            this@internal.matlab.variableeditor.ObjectViewModel(variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteStructureViewModel(...
                document, variable, viewID, userContext);
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
            % Override setSelection to handle virtual objects.  For these
            % objects, we don't want selection to be sent for the virtual
            % properties.  It can show in the UI, but we don't want the plots
            % tab (or any other listeners) to consider the property selected.
            % So here we remove the virtual property indices from the selection.
            if this.DataModel.IsVirtual 
                virtPropIndices = this.DataModel.VirtualPropIndices;
                if ~isempty(virtPropIndices)
                    selectedRows = setdiff(selectedRows, [virtPropIndices' virtPropIndices'], "rows");
                end
            end
            args = namedargs2cell(selectionArgs);
            varargout = this.setSelection@internal.matlab.variableeditor.peer.RemoteStructureViewModel(selectedRows, selectedColumns, ...
                selectionSource, args{:});
        end
    end

    methods (Access = protected)
        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteObjectViewModel';
        end

        % If the property
        % value doesn't have setAccess = public, it should be displayed
        % as read-only on the client.  (This is done by having no
        % editor for the cell).
        function isEditable = isFieldEditable(this, propertyName)
            isEditable = this.setAccessAllowed(propertyName);
        end

        function updateColumnModelInformation(this, startCol, endCol, fullColumns)
            arguments
                this
                startCol (1,1) double {mustBeNonnegative}
                endCol (1,1) double {mustBeNonnegative}
                fullColumns (1,:) double = startCol:endCol
            end

            updateColumnModelInformation@internal.matlab.variableeditor.peer.RemoteStructureViewModel(...
                this, startCol, endCol, fullColumns);

            if this.DataModel.objectBeingDebugged()
                this.ColumnModelChangeListener.Enabled = false;

                fieldColumn = this.findFieldByHeaderName("Name");
                this.setColumnModelProperty(fieldColumn.ColumnIndex, "DataAttributes", "IconLabelNameColumnAccess");

                this.ColumnModelChangeListener.Enabled = true;
                this.updateColumnModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                    startCol, endCol, fullColumns);
            end
        end

        % Turn off draggable for dependent properties as some dependent
        % properties could error.
        function updateRowModelInformation(this, startRow, endRow, fullRows)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
            end
            m = this.DataModel.getMetaClassInfo();
            isDependent = [m.PropertyList.Dependent];
            if any(isDependent)
                this.RowModelChangeListener.Enabled = false;
                if ~isempty(this.SortedIndices)
                    isDependent = isDependent(this.SortedIndices);
                end
                for row = startRow:endRow
                    if isDependent(row)
                        this.setRowModelProperty(row, 'draggable', false);
                    % Currently there is no easy way to remove model props.
                    else 
                        isDraggable = this.getRowModelProperty(row, 'draggable');
                        if ~isempty(isDraggable{1})
                            this.setRowModelProperty(row, 'draggable', '');
                        end
                    end
                end
                this.RowModelChangeListener.Enabled = true;
            end
            this.updateRowModelInformation@internal.matlab.variableeditor.peer.RemoteStructureViewModel(...
               startRow, endRow, fullRows);
        end

        function handleSortAscending(this)
            this.handleSortAscending@internal.matlab.variableeditor.peer.RemoteStructureViewModel;
            sz = this.getSize();
            this.updateRowMetaData(1, sz(1));
        end

        function b = didValuesChange(~, eValue, currentValue, ~, ~)
            b = ~isequaln(eValue, currentValue);
        end
    end
end

