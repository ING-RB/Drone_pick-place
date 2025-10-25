classdef RemoteArrayViewModel < internal.matlab.variableeditor.ArrayViewModel & ...
                              internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
    %REMOTEARRAYVIEWMODEL Remote Model Array View Model

    % Copyright 2019-2025 The MathWorks, Inc.

    properties (Constant, Hidden)
        ROW_CUTOFF_FOR_WIDTH_CALC = 30;
        WindowBlockRows = 200;
        WindowBlockColumns = 200;
    end

    properties (Transient)
        PagedDataHandler = [];
        ActionStateHandler;
        Provider;
    end

    properties
        parentID;
        parentChannel;
    end

    properties(Hidden=true)
        UnclippedSelectedRows;
        UnclippedSelectedColumns;
        ClippedSelectedRows;
        ClippedSelectedColumns;
        CharacterWidth;
        RowCutOffForWidthCalc;
    end
    
    properties(Access=protected)
        FittedColumnWidths double = [];
    end

    events
        PropertySet;
        UserDataInteraction;
        DataEditFromClient;
    end

    properties(SetAccess='protected',GetAccess='protected')
        Plugins = internal.matlab.variableeditor.peer.plugins.PluginBase.empty;
    end

    methods
        function this = RemoteArrayViewModel(parentDocument, variable, varargin)
            this@internal.matlab.variableeditor.ArrayViewModel(variable.DataModel, '', '', parentDocument.DisplayFormat);
            this@internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore([parentDocument.Provider.Channel '_' parentDocument.DocID]);
            this.initializeThreadSafety();
            this.Provider = parentDocument.Provider;
            this.viewID = varargin{2};
            this.parentID = parentDocument.DocID;
            this.parentChannel = parentDocument.Provider.Channel;
            % This API will initialize CodePublishingChannel name
            this.handleNameChanged();
            viewInfo = this.getViewProperties(variable, varargin);
            this.Provider.addView(parentDocument.DocID, this.viewID, viewInfo);
            this.Provider.setUpProviderListeners(this, this.viewID);
            this.CharacterWidth = this.CHAR_WIDTH;
            this.calcRowWidthCutoff();
            this.Plugins = internal.matlab.variableeditor.peer.plugins.PluginBase.empty;
            this.initTableModelInformation();
            this.initializePlugins();

            % Instantiates the Action State Handler
            this.ActionStateHandler = internal.matlab.variableeditor.peer.RemoteActionStateHandler(this, variable);
        end

        % Initialize thread safety to control requests executed on
        % background thread.For very large datasets(>50000000 elements), do not allow
        % backgroundpool fetches.
        function handled = initializeThreadSafety(this)
            this.IsThreadSafe = true; % Allow sending of data in background threadpool
            handled = false;
            if internal.matlab.variableeditor.peer.PeerUtils.isLiveEditor(this.userContext)
                %Turn off thread safety for live editor outputs, No need to sync up on client
                this.IsThreadSafe = false;
                handled = true;
            elseif (numel(this.DataModel.Data) > this.NUMEL_CUTOFF_FOR_BACKGROUND_FETCHES)
                 this.setThreadSafety(false);
                 handled = true;
            end
        end

        function initTableModelInformation (~)
        end

        function initColumnModelInformation (~)
        end

        function initRowModelInformation (~)
        end

        function initCellModelInformation (~)
        end

        function viewProps = getViewProperties(~, adapter, nameValueProps)
            viewProps = struct('name', adapter.Name, nameValueProps{:});
        end

        function calcRowWidthCutoff(this)
            sz = this.getTabularDataSize;
            this.RowCutOffForWidthCalc = min(this.ROW_CUTOFF_FOR_WIDTH_CALC, sz(1));
            if (this.RowLimitForWidthCalc.isKey(this.userContext))
                this.RowCutOffForWidthCalc = min(this.RowLimitForWidthCalc(this.userContext), sz(1));
            end
        end

        % Leave this as is for now, add hooks for handlePropertyDeleted if
        % need be.
%         function status = handlePropertyDeleted(this, ~, ed)
%             this.logDebug('PeerArrayView','handlePropertyDeleted','');
%
%             % Handles properties being deleted.  ed is the Event Data, and
%             % it is expected that ed.EventData.key contains the property
%             % which is being deleted.  Returns a status: empty string for
%             % success, an error message otherwise.  Note - Currently there
%             % are no properties which can be deleted.
%             status = '';
%             if strcmpi(ed.EventData.key, 'Selection')
%                 this.sendErrorMessage(getString(message(...
%                     'MATLAB:codetools:variableeditor:RequiredPropertyDeleted', ...
%                     ed.EventData.key)));
%                 status = 'error';
%             end
%         end
%

        % Sets internal property UnclippedSelectedRows and
        % UnclippedSelectedColumns.
        function setUnclippedSelection(this, unclippedRows, unclippedColumns)
            this.UnclippedSelectedRows = unclippedRows;
            this.UnclippedSelectedColumns = unclippedColumns;
        end

        % setSelection
        function varargout = setSelection(this,selectedRows,selectedColumns,selectionSource,selectionArgs)
            arguments
                this
                selectedRows
                selectedColumns
                selectionSource = 'server'% This is an optional parameter to indicate the source of the selection change.
                selectionArgs.selectedFields = []
                selectionArgs.updateFocus (1,1) logical = true
            end
            this.logDebug('PeerArrayView','setSelection','');
            % Pass along selection source on selection changed.
            varargout{1} = this.setSelection@internal.matlab.variableeditor.ArrayViewModel(...
                selectedRows, selectedColumns, selectionSource);

            % If the selection just came from client, do not set this back.
            if ~strcmp(selectionSource, 'client')
                % Send a Selection property change
                selectedRowObjs = char("[" + strjoin(compose('{"start" : %d, "end" : %d}', this.SelectedRowIntervals-1),",") + "]");
                selectedColumnObjs = char("[" + strjoin(compose('{"start" : %d, "end" : %d}', this.SelectedColumnIntervals-1),",") + "]");
                props = struct('selectedRows', selectedRowObjs, ...
                'selectedColumns', selectedColumnObjs, ...
                'source','server', ...
                'updateFocus', selectionArgs.updateFocus, ...
                'selectionSource', selectionSource);
                this.setProperty('Selection', props);
            end
            this.updateSelectionRange();
        end
        
        function updateSelectionRange(this)
            s = this.getSelectionIndices();
            sz = this.getTabularDataSize();
            [rowRange, colRange] = internal.matlab.variableeditor.BlockSelectionModel.getSelectionRange(s, sz);       
            this.setProperties(struct('rowRange', rowRange, 'colRange', colRange));
        end
        
        % gets the selection indices to update rowRange and colRange for
        % the current selection
        function s = getSelectionIndices(this)
            s = this.getSelection();
        end

        % handleClientSelection
        function varargout = handleClientSelection(this,eventData)
            this.logDebug('PeerArrayView','handleClientSelection','');
            % Converts client selection event into MCOS selection call
            if strcmpi('server',this.getStructValue(eventData,'source')) || ...
                    (~isempty(this.getStructValue(eventData,'newValue')) && ...
                    strcmpi('server', this.getStructValue(this.getStructValue(eventData,'newValue'),'source')))
                % Ignore any events generated by the server
                return;
            end
            newVal = this.getStructValue(eventData, 'newValue');
            selectedRowsMap = this.getStructValue(newVal, 'selectedRows');
            selectedRowsMap = jsondecode(selectedRowsMap);
            selectedColumnsMap = this.getStructValue(newVal, 'selectedColumns');
            selectedColumnsMap = jsondecode(selectedColumnsMap);
            selectedFields = this.getStructValue(newVal, 'FieldIDs');
            selectedRows = zeros(length(selectedRowsMap),2);
            selectedColumns = zeros(length(selectedColumnsMap),2);
            unclippedRows = zeros(length(selectedRowsMap),2);
            unclippedColumns = zeros(length(selectedColumnsMap),2);

            inRangeRowSelection = true(1,length(selectedRowsMap));
            inRangeColSelection = true(1,length(selectedColumnsMap));

            s = this.getTabularDataSize;

            % Get the selected rows from the map
            for i=1:length(selectedRowsMap)
                % Any empty selectedRowsMap means the selection was set to
                % Infinity by the client, whic corresponds to the last row
                % of data.
                if isempty(selectedRowsMap(i).start)
                    selectedRows(i,1) = s(1);
                else
                    selectedRows(i,1) = this.getStructValue(...
                        selectedRowsMap(i), 'start') + 1;
                end

                if isempty(selectedRowsMap(i).end)
                    selectedRows(i,2) = s(1);
                else
                    selectedRows(i,2) = this.getStructValue(...
                        selectedRowsMap(i), 'end') + 1;
                end

                unclippedRows(i,:) = selectedRows(i, :);
                % Clip the selection to the data (i.e. remove infinite grid
                % portion)
                selectedRows(i,2) = min(selectedRows(i,2), s(1));
                if selectedRows(i,1) > s(1)
                    inRangeRowSelection(i) = false;
                end
            end

            % Get the selected columns from the map
            for i=1:length(selectedColumnsMap)
                % Any empty selectedColumnsMap means the selection was set
                % to Infinity by the client, whic corresponds to the last
                % column of data.
                if isempty(selectedColumnsMap(i).start)
                    selectedColumns(i,1) = s(2);
                else
                    selectedColumns(i,1) = this.getStructValue(...
                        selectedColumnsMap(i), 'start') + 1;
                end

                if isempty(selectedColumnsMap(i).end)
                    selectedColumns(i,2) = s(2);
                else
                    selectedColumns(i,2) = this.getStructValue(...
                        selectedColumnsMap(i), 'end') + 1;
                end

                unclippedColumns(i,:) = selectedColumns(i, :);
                % Clip the selection to the data (i.e. remove infinite grid
                % portion)
                selectedColumns(i,2) = min(selectedColumns(i,2), s(2));
                if selectedColumns(i,1) > s(2)
                    inRangeColSelection(i) = false;
                end
            end

            % Save the unclipped row and column range in
            % UnclippedSelectedRows/UnclippedSelectedColumns as Actions
            % like InsertAction will be using this to be the selection to
            % act on.
            this.setUnclippedSelection(unclippedRows, unclippedColumns);

            % Remove any selection outside of the data (i.e. infinite grid selections)
            selectedRows(~inRangeRowSelection, :) = [];
            selectedColumns(~inRangeColSelection, :) = [];

            % g2334107: Do not redispatch if the selection is already set on
            % the server.
            if ~(this.isSelectionEqual(selectedRows, selectedColumns, selectedFields))
                % Call setSelection with optional selection source parameter
                % set to client.
                varargout{:} = this.setSelection(selectedRows, selectedColumns, 'client', selectedFields=selectedFields);
            end
        end

        function isEqual = isSelectionEqual(this, selectedRows, selectedColumns, selectedFields)
            arguments
                this
                selectedRows
                selectedColumns
                selectedFields = [];
            end
            isEqual = isequal(selectedColumns, this.SelectedColumnIntervals) && ...
                    isequal(selectedRows, this.SelectedRowIntervals);
        end
        
        % When client sets rowRange or ColRange properties, evaluate the
        % clientSetRange and update the rowRange|colRange synchronized
        % properties.
        function handleClientRangeSet(this, ed)
            newVal = ed.newValue;
            rRange = this.getProperty('rowRange');
            cRange = this.getProperty('colRange');
            if strcmpi(ed.key, 'rowRange')
                rRange = ed.oldValue;
                dim = 'rows';
            else
                cRange = ed.oldValue;
                dim = 'cols';
            end
            % Selection is valid, convert to blockselection and update the
            % rowRange|colRange property.
            try
                updatedSelection = this.getRangeIntervals(newVal, dim);
                selection = this.getSelection();
                if strcmpi(ed.key, 'rowRange')
                    rowSelection = updatedSelection;
                    colSelection = selection{2};
                else
                    rowSelection = selection{1};
                    colSelection = updatedSelection;
                end
                this.setSelection(rowSelection, colSelection);
                minRow = min(rowSelection(:));
                minCol = min(colSelection(:));
                % Scroll to the start of the selction range on range update
                this.scrollViewOnClient(minRow, minCol);
            catch e
                % Revert back range values
                this.setProperties(struct('rowRange', rRange, 'colRange', cRange));
            end
        end

        function logDebug(~, class, method, message, varargin)
            internal.matlab.datatoolsservices.logDebug("variableeditor::" + class + "::" + method, message);
        end

        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            data = this.getRenderedData@internal.matlab.variableeditor.ArrayViewModel(startRow,endRow,startColumn,endColumn);
            [renderedData, renderedDims] = internal.matlab.datatoolsservices.FormatDataUtils.getJSONForArrayData(...
                data, startRow, endRow, startColumn, endColumn);
        end

        function addClassesToTable(this, newClassList)
            existingClasses = this.getTableModelProperty('classList');

            % ensure existingClasses is a cell array of class names
            existingClasses = this.wrapClassListAsOneLayeredCellArray(existingClasses);

            updatedClassList = this.prepareNewClassList(existingClasses,...
                newClassList, 'add');

            % check isequal to save firing unnecessary events
            if ~isempty(updatedClassList) && ...
                    (~isequal(existingClasses, updatedClassList))
                this.setTableModelProperty('classList', updatedClassList);
            end
        end

        function removeClassesFromTable(this, classListToRemove)
            existingClasses = this.getTableModelProperty('classList');
            existingClasses = this.wrapClassListAsOneLayeredCellArray(existingClasses);

            updatedClassList = this.prepareNewClassList(existingClasses,...
                classListToRemove, 'remove');

            % if lists are not equal, classes should be updated
            if (~isequal(existingClasses, updatedClassList))
                this.setTableModelProperty('classList', updatedClassList);
            end
        end

        function addClassesToRow(this, row, newClassList)
            for r = row
                existingClasses = this.getRowModelProperty(r, 'classList');
                existingClasses = this.wrapClassListAsOneLayeredCellArray(existingClasses);

                updatedClassList = this.prepareNewClassList(existingClasses,...
                    newClassList, 'add');

                % checking isequal to save firing unnecessary events
                if ~isempty(updatedClassList) && ...
                        (~isequal(existingClasses, updatedClassList))
                    this.setRowModelProperty(r, 'classList', updatedClassList);
                end
            end
        end

        function removeClassesFromRow(this, row, classListToRemove)
            for r = row
                existingClasses = this.getRowModelProperty(r, 'classList');
                existingClasses = this.wrapClassListAsOneLayeredCellArray(existingClasses);

                updatedClassList = this.prepareNewClassList(existingClasses,...
                    classListToRemove, 'remove');

                if (~isequal(existingClasses, updatedClassList))
                    this.setRowModelProperty(r, 'classList', updatedClassList);
                end
            end
        end

        function addClassesToColumn(this, column, newClassList)
            for c = column
                existingClasses = this.getColumnModelProperty(c, 'classList');
                existingClasses = this.wrapClassListAsOneLayeredCellArray(existingClasses);

                updatedClassList = this.prepareNewClassList(existingClasses,...
                    newClassList, 'add');

                if ~isempty(updatedClassList) && ...
                        (~isequal(existingClasses, updatedClassList))
                    this.setColumnModelProperty(c, 'classList', updatedClassList);
                end
            end
        end

        function removeClassesFromColumn(this, column, classListToRemove)
            for c = column
                existingClasses = this.getColumnModelProperty(c, 'classList');
                existingClasses = this.wrapClassListAsOneLayeredCellArray(existingClasses);

                updatedClassList = this.prepareNewClassList(existingClasses,...
                    classListToRemove, 'remove');

                if (~isequal(existingClasses, updatedClassList))
                    this.setColumnModelProperty(c, 'classList', updatedClassList);
                end
            end
        end

        function addClassesToCell(this, row, column, newClassList)
            for r = row
                for c = column
                    existingClasses = this.getCellModelProperty(r, c, 'classList');
                    existingClasses = this.wrapClassListAsOneLayeredCellArray(existingClasses);

                    updatedClassList = this.prepareNewClassList(existingClasses,...
                        newClassList, 'add');

                    if ~isempty(updatedClassList) &&...
                            (~isequal(existingClasses, updatedClassList))

                        this.setCellModelProperty(r, c, 'classList',...
                            updatedClassList);
                    end
                end
            end
        end

        function removeClassesFromCell(this, row, column, classListToRemove)
            for r = row
                for c = column
                    existingClasses = this.getCellModelProperty(r, c,...
                        'classList');
                    existingClasses = this.wrapClassListAsOneLayeredCellArray(existingClasses);

                    updatedClassList = this.prepareNewClassList(existingClasses,...
                        classListToRemove, 'remove');

                    if (~isequal(existingClasses, updatedClassList))
                        this.setCellModelProperty(r, c, 'classList',...
                            updatedClassList);
                    end
                end
            end
        end

        % public API for actions to update model properties
        function updateRowMetaData(this, startRow, endRow)
           arguments
               this
               startRow = 1
               endRow = []
           end
           if isempty(endRow)
              sz = this.getSize();
              endRow = sz(1);
           end
           md = this.MetaDataStore;
           eventdata = internal.matlab.datatoolsservices.data.ModelChangeEventData;
           
           eventdata.Row = startRow:endRow;
           md.notify('RowMetaDataChanged', eventdata);
        end
        
        % API to refresh data for a column range (startIndex:endIndex)
        function refreshColumnWidths(this, startIndex, endIndex)
             for i=startIndex:endIndex
                this.setColumnModelProperty(i, 'ColumnWidth', [], false);
            end
            this.FittedColumnWidths(startIndex:endIndex) = 0;
            this.updateColumnModelInformation(startIndex, endIndex);
        end

        % Calls into the provider to set a property on the client
        function setProperty(this, propertyName, propertyValue)
            this.Provider.setPropertyOnClient(propertyName, propertyValue, this, this.viewID);
        end

        % Returns the property value of the given property by accessing the
        % provider
        function propertyValue = getProperty(this, propertyName)
            propertyValue = this.Provider.getProperty(propertyName, this, this.viewID);
        end

        % Returns all the properties on the view by accessing the
        % provider
        function propertyValue = getProperties(this)
            propertyValue = this.Provider.getProperties(this, this.viewID);
        end

        % Returns all the properties on the view by accessing the
        % provider
        function setProperties(this, propertiesObj)
            this.Provider.setPropertiesOnClient(propertiesObj, this, this.viewID);
        end

        % Returns a unique id for the view
        function uid = getUID(this)
            uid = this.Provider.getUID(this, this.viewID);
        end

        % Calls into the provider to send an event to the client
        function dispatchEventToClient(this, eventObj)
            this.Provider.dispatchEventToClient(this, eventObj, this.viewID);
        end

        % Calls the provider to send an error event to client
        function sendErrorMessage(this, message)
            eventObj = struct('type','error','message',message,'source','server');
            this.Provider.dispatchEventToClient(this, eventObj, this.viewID);
        end

        function handleEventFromClient(this, ~, ed)
            if ~isvalid(this)
                return;
            end

            % Handles peer events from the client
            if isfield(ed.data, 'source') && strcmp('server', ed.data.source)
                % Ignore any events generated by the server
                return;
            end

            if ~isempty(this.Plugins)
                for i=1:length(this.Plugins)
                    p = this.Plugins(i);
                    if isa(p, 'internal.matlab.variableeditor.peer.plugins.ServerConnectedPlugin')
                        handled = p.handleEventFromClient(ed);
                        if handled
                            break;
                        end
                    end
                end
            end
        end

        function status = handlePropertySetFromClient(this, ~, ed)
            if ~isvalid(this) || ~isfield(ed, 'data')
                return;
            end

            % Handles properties being set.  ed is the Event Data, and it
            % is expected that ed.EventData.key contains the property which
            % is being set.  Returns a status: empty string for success,
            % an error message otherwise.
            status = '';
            if isfield(ed,'srcLang') && strcmp('CPP',ed.srcLang)
                return;
            end

            % TODO: make getSelection and setSelection part of a server
            % side selection plugin for views that do not want selection
            % turned on.
            if strcmpi(ed.data.key, 'Selection')
                this.handleClientSelection(ed.data);
            elseif strcmpi(ed.data.key, 'rowRange') || strcmpi(ed.data.key, 'colRange')
                this.handleClientRangeSet(ed.data);
            else
                this.handlePropertySetFromClient@internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore([], ed);
            end

            try
                propertySetEventData = internal.matlab.variableeditor.PropertyChangeEventData;
                propertySetEventData.Properties = ed.data.key;
                propertySetEventData.Values = ed.data.newValue;
                this.notify('PropertySet', propertySetEventData);
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::remotearrayviewmodel::error", e.message);
            end
        end
        
        function headerNames = getHeaderNames(~)
            headerNames = [];
        end

        function headerNames = getHeadersForRange(this, startColumn, endColumn, data)
            headerNames = this.getHeaderNames();
        end
        
        % Computes ColumnWidths for all the Array-like viewmodels.
        % ColumnWidths are computed upto a max of RowCutOffForWidthCalc and
        % once for every column based on a pre-set character width.
        % NOOP: Delete after tracking client-side computation changes
        function updateColumnWidths(this, startCol, endCol)
            import internal.matlab.variableeditor.VEColumnConstants;

            affectsViewport = true;
            affectMoreThanViewport = false;
            if this.havePageSet
                [affectsViewport, affectMoreThanViewport] = this.rangeAffectsViewport(this.ViewportStartRow, this.ViewportEndRow, startCol, endCol);
            end

            internal.matlab.datatoolsservices.logDebug("variableeditor::remotearrayviewmodel", sprintf('updateColumnWidths: [%d, %d]\n', startCol, endCol));

            criteria = ((affectsViewport && ~affectMoreThanViewport) || ...
                (endCol - startCol + 1 <= internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.BACKGROUNDPOOL_COL_SIZE_LIMIT));

            this.executeInBackgroundIfPossible(fcn=@computeWidths,...
                numOutputArgs=3,...
                criteria=criteria,...
                inputArgs={this, startCol, endCol},...
                completionFcn=@(cw, sc, ec)this.setColumnWidthsInModel(sc, ec, cw));
        end

        % NOOP: Delete after tracking client-side computation changes
        function setColumnWidthsInModel(this, startCol, endCol, colWidths)
            internal.matlab.datatoolsservices.logDebug("variableeditor::remotearrayviewmodel", sprintf('\nSetting column widths in model: [%d, %d](%s)\n', startCol, endCol, mat2str(colWidths)));
            if ~isvalid(this)
                % Short circuit in case variable closed
                return;
            end
            this.ColumnModelChangeListener.Enabled = false;
            for col=startCol:endCol
                colWidth = colWidths(col-startCol+1);
                if colWidth ~= 0
                    this.setColumnModelProperty(col, 'ColumnWidth', colWidth, false);
                end
            end
            this.ColumnModelChangeListener.Enabled = true;
        end

        % NOOP: Delete after tracking client-side computation changes
        function [colWidths, startCol, endCol] = computeWidths(this, startCol, endCol)
            arguments
                this
                startCol
                endCol
            end
            import internal.matlab.variableeditor.VEColumnConstants;
            if endCol > numel(this.FittedColumnWidths) || any(~this.FittedColumnWidths(startCol:endCol))
                try
                    dispData = this.getDisplayData(1, this.RowCutOffForWidthCalc, startCol, endCol);
                    if iscell(dispData)
                        allWidths = cellfun(@matlab.internal.display.wrappedLength, dispData, "ErrorHandler", @(~, ~) 0);
                    else
                        allWidths = arrayfun(@matlab.internal.display.wrappedLength, dispData);
                    end
                catch ex
                    internal.matlab.datatoolsservices.logDebug("variableeditor::remotearrayviewmodel::error", "Error in computeWidths: " + ex.message);
                    
                    % Setting widths to 1 so default width will get picked up
                    allWidths = ones(1, (endCol - startCol + 1));
                end
                dataWidths = max(allWidths)*this.CharacterWidth;
                headers = this.getHeadersForRange(startCol, endCol);
                if ~isempty(headers)                    
                    headerWidths = arrayfun(@this.computeHeaderWidthUsingLabels, headers);
                    dataWidths = max(dataWidths, headerWidths);
                end
                widths = min(dataWidths, VEColumnConstants.MAX_COL_WIDTH);
                this.FittedColumnWidths(startCol:endCol) = widths;
            end
            colWidths = this.FittedColumnWidths(startCol:endCol);
            colWidths(colWidths<=VEColumnConstants.defaultColumnWidth)=0;
        end

        function plugin = getPluginByName(this, pluginName)
            plugin = [];
            allPlugins = this.Plugins;
            pluginMatch = find(string([allPlugins.NAME]) == pluginName);
            if ~isempty(pluginMatch)
                plugin = allPlugins(pluginMatch);
            end
        end

        % For a given feature name, Get the Plugin class name from the
        % PluginToFeatureMap and instantiate. PluginToFeatureMap holds a mapping
        % from plugin name to their corresponding class names.
        function addToPlugins(this, featureName)
            pluginName = internal.matlab.variableeditor.peer.plugins.PluginToFeatureMap.GetPluginsForFeature(featureName);
            if ~isempty(pluginName)
                instance = feval(pluginName, this);
                this.Plugins(end+1)= instance;
            end
        end
    end

    methods(Static)

        function updateDataForRange(viewModel, row, column)
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.StartRow = row;
            eventdata.EndRow = row;
            eventdata.StartColumn = column;
            eventdata.EndColumn = column;
            viewModel.notify('DataChange',eventdata);
        end

        function removeQuotes = getRemoveQuotesFromView(viewModel, row, column)
            % Return the RemoveQuotedStrings value, assume false if it is not set.
            removeQuotes = viewModel.getCellPropertyValue(row, column, 'RemoveQuotedStrings');
            % If removeQuotes prop is set, use the property value, else return false
            if ~isempty(removeQuotes) && ~isempty(removeQuotes{1})
                removeQuotes = removeQuotes{1};
                removeQuotes = (islogical(removeQuotes) && removeQuotes) || ...
                    strcmp(removeQuotes, 'true') || ...
                    strcmp(removeQuotes, 'on');
            else
                removeQuotes = false;
            end
        end
    end

    methods(Access='protected')
        
        % Gets RangeIntervals (selectedRows and selectedColumns) from the
        % given rangeValue (rowRange or columnRange).
        function intervals = getRangeIntervals(this, rangeValue, dim)
            intervals = internal.matlab.variableeditor.BlockSelectionModel.getSelectionIntervals(this.DataModel.getCloneData, rangeValue, dim, this.getTabularDataSize);
        end
        
        % On DataModel Updates, when a size Changes, update the
        % selectionRanges to unclippedRanges. When user edits in
        % Infinitegrid, datasize changes and unclipped selection could now
        % be within data, call setSelection to update the rowRange and
        % colRange to reflect this, Or sizeChanged needs server side
        % update of UnclippedRange, trigger a setSelection.
        function handleDataChangedOnDataModel(this, es ,ed)
            if isa(ed, 'internal.matlab.datatoolsservices.data.DataChangeEventData')
                if ~isempty(ed.SizeChanged) && ed.SizeChanged
                    if ~isempty(this.UnclippedSelectedRows) && ...
                        ~isempty(this.UnclippedSelectedColumns)
                        % If size changes while in brushing mode (if users delete
                        % brushed data), do not update selection, this could toggle
                        % brushed indices.
                       isBrushingMode = this.getProperty("BrushingMode");
                       if isempty(isBrushingMode) || ~isempty(isBrushingMode) && ~isBrushingMode
                            this.setSelection(this.UnclippedSelectedRows, this.UnclippedSelectedColumns);
                       end
                       this.initializeThreadSafety();
                    end
                end
                this.handleDataChangedOnDataModel@internal.matlab.variableeditor.ArrayViewModel(es, ed);
            end
        end

        % Handles Single Cell Data Edit from Client for a row|column.
        % 1. Calls into processIncomingDataSet that checks for valid
        % quotes/string escapes and empty value replacemnets.
        % 2. Evaluates formatted data in workspace of incoming data was not empty. 
        % 3. If value set is equal to current value, we return as NOOP. 
        % 4. Calls setTabularData to construct code for the edit operation and notify datamodel to publish code. 
        % 5. Notifies SingleCellEdit for ML listeners like UI Components.
        function handleClientSetData(this, eventData)
            rawData = this.getStructValue(eventData, 'data');
            row = this.getStructValue(eventData, 'row');
            column = this.getStructValue(eventData, 'column');
            origValue = '';
            data = rawData;
            try
                if ~isempty(row)
                    if ischar(row)
                        row = str2double(row);
                    end
                    if ischar(column)
                        column = str2double(column);
                    end
                    [data, origValue, result, isStr] = this.processIncomingDataSet(row, column, rawData);

                    if isempty(result) && ~isempty(rawData)
                        [result] = evalin(this.DataModel.Workspace, data);  % Test for a valid expression.
                    end
                    if ~this.validateInput(result,row,column)
                        error(message('MATLAB:codetools:variableeditor:InvalidInputType'));
                    end
                    currentVal = this.getData(row, row, column, column);
                    % Check for isEqual values only when origValue
                    % is not empty(Edit was within Finite Grid)
                    if ~isempty(origValue) && this.isEqualDataBeingSet(result, currentVal, row, column)
                            % Even though the data has not changed we will fire
                            % a data changed event to take care of the case
                            % that the user has typed in a value that was to be
                            % evaluated in order to clear the expression and
                            % replace it with the value (e.g. pi with 3.1416)
                            this.updateDataForRange(this, row, column);
                            return;
                    end
                    code = this.setTabularData(row, column, data, origValue);
                else
                    error(message('MATLAB:codetools:variableeditor:invalidRow'));
                end
                this.notifyOnVariableEdit(row, column, currentVal, result, code);
            catch e
                this.notifyOnEditError(e.message, row, column, origValue, data);
            end
        end

        function notifyOnVariableEdit(this, row, column, currentValue, newValue, code)
            % Publish to any MATLAB listeners on the View
            if ~isempty(code)
                this.notifyVariableEdit('SingleCellEdit', row, column, currentValue, newValue, code{:});
            end
        end

        function notifyOnEditError(this, errorMsg, row, column, origValue, newValue)
            % Send data change event.
            this.sendEvent('dataChangeStatus', ...
                'status', 'error', ...
                'message', errorMsg, ...
                'row', row, ...
                'column', column, ...
                'origValue', origValue, ...
                'newValue', newValue, ...
                'source', 'server');
        end

        % Replaces data with empty value replacement or formats incoming
        % data such that we can eval the data to be set for the row/column
        % in the correct workspace.
        % row and column are the actual data row and column indices. Takes
        % in an additional viewIndex for views that have different view
        % mapping (For e.g grouped vars in tables)
        function [data, origValue, evalResult, isStr] = processIncomingDataSet(this, row, column, data, viewColumnIndex)
            arguments
                this
                row
                column
                data
                viewColumnIndex = column
            end
            import internal.matlab.variableeditor.peer.PeerUtils;
            origValue = '';
            evalResult = [];
            sz = this.getTabularDataSize(); % Returns the flattened size on a given view.
            if (row <= sz(1) && viewColumnIndex <= sz(2))
                % Compute origValue and string replacements only if we are editing within the current data grid.
                origValue = this.formatDataForClient(row, row, viewColumnIndex, viewColumnIndex);
            end
            % ClassType operates on actual datasize (Unflattened)
            classType = this.getClassType(row, column);
            isStr = strcmp(classType,'string');
            rawData = data;
            removeQuotes = this.getRemoveQuotesFromView(this, row, column);
            if ~isempty(data) && removeQuotes && ~isStr
                data = strrep(data,'''','''''');
                data = ['''' data ''''];
            end
            % Check for empty value passed from user and replace
            % with valid "empty" value
            if isempty(data)
                data = this.getEmptyValueReplacement(row,column);
                if ~ischar(data)
                    data = mat2str(data);
                end
            else
                % TODO: Code below does not test for expressions in terms
                % of variables in the current workspace (e.g. "x(2)") and
                % it allows expression in terms of local variables in this
                % workspace. We need a better method for testing validity.
                % LXE may provide this capability.
                if ~ischar(data)
                    try
                        data = mat2str(data);
                    catch
                        % Ignore exceptions, try to continue.  Not
                        % all input needs to go through mat2str
                    end
                end
                if isStr || (ischar(data) && startsWith(data, '"') && endsWith(data, '"'))
                    data = this.cleanStringData(data, rawData, removeQuotes);
                end
                % For timetables, time column can be datetime or duration,
                % we need to process the data for both accordingly.
                if strcmp(classType, 'datetime') || strcmp(classType, 'duration')
                    data = ['"' data '"'];
                end
                % evaluates the expression typed by the user to any
                % equivalent value for that data type
                [evalResult] = this.evaluateClientSetData(data, row, column);
            end
        end

        function isEqual = isEqualDataBeingSet(this, newValue, currentValue, row, column)
            % When a table sets a single cell, it is possible that
            % the data is a cell, in which case we need to get the
            % value from the cell.
            if iscell(currentValue)
                currentValue = currentValue{:};
            end
            isEqual = ~this.didValuesChange(newValue, currentValue, row, column);
        end

        function data = cleanStringData(~, data, rawData, removeQuotes)
            % Additional processing if the data is currently a
            % string, or if the user is entering a string by
            % wrapping the value in double-quotes
            import internal.matlab.variableeditor.peer.PeerUtils;
            if ~isequal(rawData, '''') && ~isequal(rawData, '"')
                % Escape quotes if datatype is of type string
                % to be able to evaluate in command line.
                data = PeerUtils.parseStringQuotes(data, 'string', ~removeQuotes);

                % Escape /n and /t if the input data contains these characters, checking for chars
                % as well to support inline editing of strings in struct arrays.
                data = PeerUtils.escapeSpecialCharsForStrings(data);
                if startsWith(data, '""') && ...
                        endsWith(data, '""') && ...
                        strlength(data) > 2
                    if ~startsWith(data, '"" +')
                        data = ['"' data];
                    end
                    if ~endsWith(data, '+ ""')
                        data = [data '"'];
                    end
                end
            else
                data = rawData;
            end
        end

        % Sets data on the DataModel and dispatches StatusChange to the
        % client.
        function varargout = setTabularData(this, row, column, data, origValue)
            varargout{1} = {};
             try
                msgOnError = this.getMsgOnError(row, column, 'dataChangeStatus');
                varargout{1} = this.setTabularDataValue(row, column, data, msgOnError);
                this.sendEvent('dataChangeStatus', ...
                    'status', 'success', ...
                    'message', '', ...
                    'row', row, ...
                    'column', column, ...
                    'newValue', data, ...
                    'origValue', origValue, ...
                    'source', 'server');
            catch e
                this.sendEvent('dataChangeStatus', ...
                    'status', 'error', ...
                    'message', e.message, ...
                    'row', row, ...
                    'column', column, ...
                    'newValue', data, ...
                    'origValue', origValue, ...
                    'source', 'server');
             end
        end

        function msgOnError = getMsgOnError(this, row, column, msg)
            % Constructs a function that can be called on error when the
            % command is evaluated in command window, but generates an error. The error
            % message will be constructed using the status returned from
            % the set properties call.  For example, if you try to do
            % something like:  set(lineObj, 'Marker', pi), it will return
            % an error message which will be conveyed as error status to
            % the dataStore.
            msgOnError = '';
            if ~strcmp(this.userContext, this.DataModel.MAIN_VE_USER_CONTEXT)
                return;
            end 
            idx = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance.PeerManager.documentIndex(this.DataModel.Name,...
                this.DataModel.Workspace);
            msgOnError = ['internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance.PeerManager.Documents(' ...
                num2str(idx) ').ViewModel.sendEvent(''' msg ''', ''status'', ''error'', ''message'', ' ...
                '''%1$s'', ' ...
                '''row'', ' ...
                num2str(row - 1) ', ''column'', ' ...
                num2str(column - 1) ' );'];
        end

        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteArrayViewModel';
        end

        function sendSizeToClient(this)
            this.sendSizeToClient@internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore();
            this.setProperty('DisplaySize', struct('source', 'server', ...
                'displaySize', this.getDisplaySize));
        end

        % This method initializes all the plugins during view startup.
        function initializePlugins(this)
            widgetRegistryInstance = internal.matlab.datatoolsservices.WidgetRegistry.getInstance();
            containerType = class(this.DataModel.Data);
            doGenericObjCheck = isobject(this.DataModel.Data) && ~isnumeric(this.DataModel.Data);
            veDataAttributes = internal.matlab.variableeditor.VEDataAttributes(this.DataModel.Data);
            [~,dataAttributes] = internal.matlab.datatoolsservices.WidgetRegistry.getDataAttributes(veDataAttributes);
            widgetEntry = widgetRegistryInstance.getWidgets(containerType,'', this.userContext, dataAttributes, doGenericObjCheck);
            if isfield(widgetEntry, 'Plugins') && ~isempty(widgetEntry.Plugins)
                features = widgetEntry.Plugins.featureList;
                cellfun(@(x)this.addToPlugins(x), features);
            end
        end

        function ed = handleDataChange(this, ed)
            if isprop(ed, 'StartRow') && ...
                    (isempty(ed.StartRow) && isempty(ed.StartColumn) &&...
                    isempty(ed.EndRow) && isempty(ed.EndColumn)) || ...
                    (isfield(ed, 'Range') && isempty(ed.Range))
                % This indicates all data has changed
                size = this.getTabularDataSize;
                ed.StartRow = 1;
                ed.EndRow = size(1);
                ed.StartColumn = 1;
                ed.EndColumn = size(2);
            end
            this.handleDataChange@internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore(ed);
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

            if ~isempty(this.Plugins)
                for i=1:length(this.Plugins)
                    p = this.Plugins(i);
                    if isa(p, 'internal.matlab.variableeditor.peer.plugins.MetaDataPlugin')
                        p.updateCellModelInformation(startRow, endRow, startColumn, endColumn);
                    end
                end
            end
           this.updateCellModelInformation@internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore(...
               startRow, endRow, startColumn, endColumn, fullRows, fullColumns);

        end

        function updateTableModelInformation(this)
            if ~isempty(this.Plugins)
                for i=1:length(this.Plugins)
                    p = this.Plugins(i);
                    if isa(p, 'internal.matlab.variableeditor.peer.plugins.MetaDataPlugin')
                        p.updateTableModelInformation();
                    end
                end
            end
           this.updateTableModelInformation@internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore();
        end

        function updateRowModelInformation(this, startRow, endRow, fullRows)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
            end
             if ~isempty(this.Plugins)
                for i=1:length(this.Plugins)
                    p = this.Plugins(i);
                    if isa(p, 'internal.matlab.variableeditor.peer.plugins.MetaDataPlugin')
                        p.updateRowModelInformation(startRow, endRow);
                    end
                end
            end
           this.updateRowModelInformation@internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore(...
               startRow, endRow, fullRows);
        end

        function updateColumnModelInformation(this,...
                startColumn,...
                endColumn, ...
                fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startColumn (1,1) double {mustBeNonnegative}
                endColumn (1,1) double {mustBeNonnegative}
                fullColumns (1,:) double = startColumn:endColumn
            end
            
            internal.matlab.datatoolsservices.logDebug("variableeditor::remotearrayviewmodel", "updateColumnModelInformation(" + startColumn + "," + endColumn + ")");

            % Update Plugins
            if ~isempty(this.Plugins)
                for i=1:length(this.Plugins)
                    p = this.Plugins(i);
                    if isa(p, 'internal.matlab.variableeditor.peer.plugins.MetaDataPlugin')
                        try
                            p.updateColumnModelInformation(startColumn, endColumn);
                        catch e
                            this.logDebug('RemoteArrayViewModel','updateColumnModelInformation',e.message);
                        end
                    end
                end
            end

            this.updateColumnModelInformation@internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore(...
               startColumn, endColumn, fullColumns);
        end

        function updatedClassList = prepareNewClassList(~,...
                oldClassList, newClassList, action)
            if strcmp(action, 'add')
                % avoid duplicates, but maintain the order
                updatedClassList = unique([oldClassList...
                    newClassList], 'stable');
            elseif strcmp(action, 'remove')
                updatedClassList = oldClassList(~ismember(oldClassList,...
                    newClassList));
            else
                error('This method only allows add or remove actions');
            end

            % remove empty class names like {'' 'a' 'b'} => {'a' 'b'}
            updatedClassList(cellfun('isempty', updatedClassList)) = [];
        end

        % Note: we need this because getTable/Row/Column/CellModelProperty
        % returns different output type including a cell array, or a cell
        % within a cell array, or an empty numeric array
        function classList = wrapClassListAsOneLayeredCellArray(~, classList)
            if ~iscell(classList)
                if isnumeric(classList)
                    if isempty(classList)   % []
                        classList = {};
                    end
                else    % '' or 'a'
                    classList = {classList};
                end
            elseif iscell(classList)
                % for empty cell and 1x0 empty cell
                if isequal(size(classList), [1 0]) || isempty(classList)
                    classList = {};
                elseif iscell(classList{1})
                    % for cell in a cell array: {{'a'}}
                    classList = classList{1};
                end
            end
        end

        % Specialized validation function to be optionally overridden in
        % subclasses
        function isValid = validateInput(varargin)
            isValid = true;
        end

        % Evaluates the expression entered by the  user. This is required for cases
        % like 'pi' where the cell data should evaluate to '3.1416'
        % Arguments are (this, data, row, column)
        function result = evaluateClientSetData(~, ~, ~, ~)
            result = [];
        end

        % Defining getClassType to be optionally overridden in subclasses
        % Arguments are (this, row, column, size)
        function classType = getClassType(varargin)
            classType='';
        end

        % Specialized empty value function to be optionally overridden in
        % subclasses
        function replacementValue = getEmptyValueReplacement(this,row,column, ~)
            this.logDebug('PeerArrayView','getEmptyValueReplacement','','row',row,'column',column);

            replacementValue = [];
        end

        % Check if the values are the same (using isequaln, but also
        % compare if one is a string and the user entered value is a char,
        % since it will convert to string in some assignments)
        function changed = didValuesChange(~, newValue, oldValue, ~, ~)
            arguments
                ~
                newValue % Any type
                oldValue % Any type
                ~
                ~
            end

            changed = true;

            bothValuesAreStringlike = (ischar(newValue) || isstring(newValue)) && ...
                (ischar(oldValue) || isstring(oldValue));

            try
                if bothValuesAreStringlike
                    % If the values aren't equal, but one is "test" and the
                    % user entered value is 'test', these will be considered
                    % equal since 'test' will convert to string when assigned.
                    changed = ~strcmp(newValue, oldValue);
                else
                    changed = ~strcmp(class(newValue), class(oldValue)) || ...
                        ~isequaln(newValue, oldValue);
                end
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::remotearrayviewmodel::error", e.message);
            end
        end

        function out = executeCommandInWorkspace(this, data, row, column)
            out = this.setData(data, row, column);
        end
    end

    % public utils
    methods
        function delete(this)
            if ~isempty(this.Provider) && isvalid(this.Provider)
                this.Provider.deleteView(this.parentID +  "_" + this.viewID);
            end
        end

        % Disable cell update and resume it somewhere later
        function oldStatus = disableCellModelUpdate(this)
            % return original update status for save and resume.
            oldStatus = this.CellModelChangeListener.Enabled;

            this.CellModelChangeListener.Enabled = false;
        end

        % resume cell update
        function resumeCellModelUpdate(this, status, forceUpdate)
            if nargin < 3
                forceUpdate = false;
            end

            if forceUpdate
                this.CellModelChangeListener.Enabled = true;
            else
                this.CellModelChangeListener.Enabled = status;
            end
        end

        % Disable column update and resume it somewhere later
        function oldStatus = disableColumnModelUpdate(this)
            % return original update status for save and resume.
            oldStatus = this.ColumnModelChangeListener.Enabled;

            this.ColumnModelChangeListener.Enabled = false;
        end

        % resume column update
        function resumeColumnModelUpdate(this, status, forceUpdate)
            if nargin < 3
                forceUpdate = false;
            end

            if forceUpdate
                this.ColumnModelChangeListener.Enabled = true;
            else
                this.ColumnModelChangeListener.Enabled = status;
            end
        end

        % API to update the cell focus on the client side.
        % This changes the cell focus in the table to the row and column numbers passed in.
        function setCellFocusOnClient(this, row, column)
            eventObj = struct('type','cellFocusClient', 'row',row, ...
                'column', column, 'source','server');
            this.Provider.dispatchEventToClient(this, eventObj, this.viewID);
        end

        % API to scroll the view on the client side.
        % This scrolls the table to the row and column numbers passed in.
        function scrollViewOnClient(this, row, column)
            eventObj = struct('type','scrollClient', 'row',row, ...
                'column', column, 'source','server');
            this.Provider.dispatchEventToClient(this, eventObj, this.viewID);
        end

        % API to notify listeners on MATLAB when a variable is edited
        function notifyVariableEdit(this, type, row, column, oldVal, newVal, code)
            % Publish the edit event to any MATLAB listeners on the View
            eventdata = internal.matlab.variableeditor.VariableEditEventData;
            eventdata.UserAction = type;
            eventdata.Position = struct('Row', row, 'Column', column);
            eventdata.OldValue = oldVal;
            eventdata.NewValue = newVal;
            eventdata.Code = code;
            try
                this.notify('DataEditFromClient', eventdata);
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::remotearrayviewmodel::error", e.message);
            end
        end

        % whenever name on the variable is set, initialize
        % CodePublishingDataModelChannel on the DataModel
        function handleNameChanged(this)
            if isprop(this.DataModel, "CodePublishingDataModelChannel")
                % Create code publishing channel with the manager's channel along with DocID of the document.
                codePublishChannel = internal.matlab.datatoolsservices.VariableUtils.createCodePublishingChannel(this.parentChannel, this.parentID);
                this.DataModel.setCodePublishingChannel(codePublishChannel)
            end
        end
    end
end
