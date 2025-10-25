classdef PeerTabularDataStore < internal.matlab.datatoolsservices.data.TabularDataStore
    %PEERTABULARDATASTORE Summary of this class goes here
    %   Detailed explanation goes here

    properties(Constant)
        DEFAULT_PAGING_CHANNEL = '/DatatoolsServices/Data/Paging_';
        DEFAULT_NODE_TYPE = 'DataPagingNode';
    end
    
    properties(SetAccess='protected')
        Channel;
        PeerNodeID;
        PeerNode;
        PeerNodeServer;
        PeerNodeIsGenerated;
        PeerServerIsGenerated;
        MetaDataStore;

        % Making the current range public
        ViewportStartRow = [];
        ViewportEndRow = [];
        ViewportStartColumn = [];
        ViewportEndColumn = [];

    end
    
    properties(SetAccess='protected',GetAccess='protected')
        LastRequestedStartRow = [];
        LastRequestedEndRow = [];
        LastRequestedStartColumn = [];
        LastRequestedEndColumn = [];
        
        % Peer Event Listeners
        PropertySetListener;
        PeerEventListener;

        % Server Model-Side Change Listeners
        DataChangeListener;
        CellModelChangeListener;
        TableModelChangeListener;
        RowModelChangeListener;
        ColumnModelChangeListener;
    end

    methods
        function this = PeerTabularDataStore(channel, peerNodeID, metaDataStore)
            % Call superclass constructor
            this@internal.matlab.datatoolsservices.data.TabularDataStore();

            narginchk(0,3);
            
            % Check for a channel otherwise create one
            this.PeerServerIsGenerated = false;
            if nargin < 1 || isempty(channel)
                channel = [this.DEFAULT_PAGING_CHANNEL num2str(this.getNextChannelID)];
                this.PeerServerIsGenerated = true;
            end
            this.Channel = channel;
            
            % Check for peer node id otherwise assume the root
            this.PeerNodeIsGenerated = false;
            if nargin < 2 || isempty(peerNodeID)
                peerNodeID = '';
            end

            % Check for metaDataStore otherwise create a default one
            if nargin < 3 || isempty(metaDataStore)
                if isa(this, 'internal.matlab.datatoolsservices.data.TabularMetaDataStore')
                    this.MetaDataStore = this;
                else
                    this.MetaDataStore = internal.matlab.datatoolsservices.data.DefaultTabularMetaDataStore;
                end
            else
                this.MetaDataStore = metaDataStore;
            end
            

            if isempty(peerNodeID)
                % Need to create the peer node (root)
                this.PeerNodeServer = peermodel.internal.PeerModelManagers.getServerManager(channel);
                this.PeerNodeServer.SyncEnabled = true;
                if ~this.PeerNodeServer.hasRoot
                    this.PeerNode = this.PeerNodeServer.createRoot(this.DEFAULT_NODE_TYPE);
                    this.PeerNodeIsGenerated = true;
                else
                    rootNode = this.PeerNodeServer.getRoot;
                    if ~strcmp(rootNode.Type, this.DEFAULT_NODE_TYPE)
                        this.PeerNode = this.PeerNode.addChild(this.DEFAULT_NODE_TYPE);
                        this.PeerNodeIsGenerated = true;
                    else
                        this.PeerNode = rootNode;
                    end
                end
            else
                peerNodeServer = peermodel.internal.PeerModelManagers.getClientManager(channel);
                this.PeerNode = peerNodeServer.getNodeById(peerNodeID);
                peerNodeServer.SyncEnabled = true;
            end
            this.PeerNodeID = this.PeerNode.Id;

            % Initialize Listeners
            this.DataChangeListener = event.listener(this, 'DataChange', @(es,ed)this.handleDataChange(es,ed));
            this.CellModelChangeListener = event.listener(this.MetaDataStore, 'CellMetaDataChanged', @(es,ed)this.handleCellModelUpdate(es,ed));
            this.TableModelChangeListener = event.listener(this.MetaDataStore, 'TableMetaDataChanged', @(es,ed)this.handleTableModelUpdate(es,ed));
            this.RowModelChangeListener = event.listener(this.MetaDataStore, 'RowMetaDataChanged', @(es,ed)this.handleRowModelUpdate(es,ed));
            this.ColumnModelChangeListener = event.listener(this.MetaDataStore, 'ColumnMetaDataChanged', @(es,ed)this.handleColumnModelUpdate(es,ed));
            this.PropertySetListener = event.listener(this.PeerNode,'PropertySet',@this.handlePropertySet);
            this.PeerEventListener = event.listener(this.PeerNode,'PeerEvent',@this.handlePeerEvents);
        end
       
        % Allows setting property on the View. Making this public to allow
        % our view actions and plugins to be able to set properties.
        function setProperty(this, propertyName, propertyValues)
            %TODO: Is there a way to eliminate the HashMap usage?  Would
            % require modifying the MCOS peer model API to allow a structure
            % for the setProperty method.
            
            if isempty(this.PeerNode)
                return;
            end
            
            if ~isstruct(propertyValues)
                if isa(propertyValues,'java.util.HashMap') && ~propertyValues.containsKey('source')
                    propertyValues.put('source', 'server');
                end
                this.PeerNode.setProperty(propertyName, propertyValues);
                return;
            end
            
            map = java.util.HashMap();
            fields = fieldnames(propertyValues);
            for i=1:length(fields)
                map.put(fields{i}, propertyValues.(fields{i}));
            end
            if ~map.containsKey('source')
                map.put('source', 'server');
            end
            
            this.PeerNode.setProperty(propertyName, map);
        end       

        function fieldValue = getStructValue(~, s, field)
            fieldValue = [];
            
            if isstruct(s) && isfield(s, field)
                fieldValue = s.(field);
            elseif isobject(s) && isprop(s, field)
                fieldValue = s.get(field);
            elseif isa(s,'java.util.HashMap') && s.containsKey(field)
                fieldValue = s.get(field);
            else
                l = lasterror; %#ok<LERR>
                try
                    fieldValue = s.get(field);
                catch
                    % Clear last error because we don't want to hunt
                    % invlaid error message when we could have just been u
                    if ~isempty(l)
                        lasterror(l); %#ok<LERR>
                    else
                        lasterror('reset'); %#ok<LERR>
                    end
                end
            end
        end         
          
        function jsonStr = toJSON(this, varargin)
            jsonStr = jsonencode(varargin);
            jsonStr = jsonStr(2:end-1);
        end
        
        function delete(this)
            % Cleanup listeners
            this.deleteListener('DataChangeListener');
            this.deleteListener('CellModelChangeListener');
            this.deleteListener('TableModelChangeListener');
            this.deleteListener('RowModelChangeListener');
            this.deleteListener('ColumnModelChangeListener');
            this.deleteListener('PropertySetListener');
            this.deleteListener('PeerEventListener');

            % Clean up peer node
            if this.PeerNodeIsGenerated
                if ~isempty(this.PeerNode) && isvalid(this.PeerNode)
                    delete(this.PeerNode);
                end
            end
            if this.PeerServerIsGenerated
                if ~isempty(this.PeerNodeServer)...
                        && isvalid(this.PeerNodeServer)
                    delete(this.PeerNodeServer);
                end
            end
        end
        
        function deleteListener(this, listener)
            if ~isempty(this.(listener)) && isvalid(this.(listener))
                delete(this.(listener));
            end
        end
    end
    
    methods(Access=protected)
        function nextID = getNextChannelID(~)
            mlock;
            persistent lastID;
            if isempty(lastID)
                lastID = 0;
            end
            nextID = lastID+1;
            lastID = nextID;
        end
        
        function handleDataChange(this, ~, ed)
            % Notify client if size changes
            if ed.SizeChanged
                this.sendSizeToClient;
            end

            if this.havePageSet
                affectsViewport = this.rangeAffectsViewport(ed.StartRow, ed.EndRow, ed.StartColumn, ed.EndColumn);

                startRow = 0;
                endRow = 0;
                startColumn = 0;
                endColumn = 0;

                if affectsViewport
                    if ed.SizeChanged 
                        % If sizeChanged, check ifthere is a viewport
                        % intersection, If yes, send just the viewport,
                        % else send nothing
                        if (ed.StartRow <= this.ViewportEndRow) && (ed.StartColumn <= this.ViewportEndColumn)
                            startRow = this.ViewportStartRow;
                            endRow = min(this.ViewportEndRow, ed.EndRow); % Need min in case data size shrinks g1957669
                            startColumn = this.ViewportStartColumn;
                            endColumn = min(this.ViewportEndColumn, ed.EndColumn); % Need min in case data size shrinks g1957669
                        else
                            % Nothing to do here, size changed already sent
                            % and the client side will respond and clear out
                            % any stale data based on the size adjustment
                            return;
                        end
                    else
                        startRow = max(this.ViewportStartRow, ed.StartRow);
                        startColumn = max(this.ViewportStartColumn, ed.StartColumn);
                        endRow = min(this.ViewportEndRow, ed.EndRow);
                        endColumn = min(this.ViewportEndColumn, ed.EndColumn);
                    end
                end

                % Send the data to the client
                this.sendDataToClient(startRow, endRow, startColumn, endColumn, ...
                    ed.StartRow, ed.EndRow, ed.StartColumn, ed.EndColumn);
            end
        end      
        
        function clearClientBuffer(this, startRow, endRow, startColumn, endColumn, source)
            currentViewPort = struct('startRow', this.ViewportStartRow, 'endRow', this.ViewportEndRow, 'startColumn', this.ViewportStartColumn, 'endColumn', this.ViewportEndColumn);            
            this.sendPeerEvent('clearBuffer', 'startRow', startRow, 'endRow', endRow, 'startColumn', startColumn, 'endColumn', endColumn, 'source', source, 'CurrentViewport', this.toJSON(currentViewPort));
        end
        
        function clearClientMetaDataBuffer(this, metaDataType, eventData)            
            this.sendPeerEvent('clearMetaDataBuffer', 'metaDataType', metaDataType, 'rows', eventData.Row, 'columns', eventData.Column);
        end
        
        function status = handlePropertySet(this, ~, ed)
            % Handles properties being set.  ed is the Event Data, and it
            % is expected that ed.EventData.key contains the property which
            % is being set.  Returns a status: empty string for success,
            % an error message otherwise.
            status = '';
            if isfield(ed.EventData,'source') && strcmp('server',ed.EventData.source)
                return;
            end
            
            if strcmpi(ed.EventData.key, 'TableModelProperties')
            elseif strcmpi(ed.EventData.key, 'TableModelProperty')
                property = this.getStructValue(ed.EventData.newValue,'property');
                value = this.getStructValue(ed.EventData.newValue,'value');
                this.TableModelChangeListener.Enabled = false;
                this.MetaDataStore.setTableModelProperty(property, value);
                % Update the JSON internal cache
                this.TableModelChangeListener.Enabled = true;
            elseif strcmpi(ed.EventData.key, 'CellModelProperties')
            elseif strcmpi(ed.EventData.key, 'CellModelProperty')
                property = this.getStructValue(ed.EventData.newValue,'property');
                value = this.getStructValue(ed.EventData.newValue,'value');
                row = this.getStructValue(ed.EventData.newValue,'row');
                column = this.getStructValue(ed.EventData.newValue,'column');
                this.CellModelChangeListener.Enabled = false;
                this.MetaDataStore.setCellModelProperty(row, column, property, value);
                % Update the JSON internal cache
                this.updateCellModelInformation(this.ViewportStartRow, this.ViewportEndRow, this.ViewportStartColumn, this.ViewportEndColumn);
                this.CellModelChangeListener.Enabled = true;
            elseif strcmpi(ed.EventData.key, 'ColumnModelProperties')
            elseif strcmpi(ed.EventData.key, 'ColumnModelProperty')
                column = this.getStructValue(ed.EventData.newValue,'column');
                property = this.getStructValue(ed.EventData.newValue,'property');
                value = this.getStructValue(ed.EventData.newValue,'value');
                this.ColumnModelChangeListener.Enabled = false;
                this.MetaDataStore.setColumnModelProperty(column+1, property, value);
                % Update the JSON internal cache
                [~, ~, startColumn, endColumn] = this.getCurrentPage();
                if any(column+1 >= startColumn) && any(column+1 <= endColumn)
                    this.updateColumnModelInformation(startColumn, endColumn);
                end
                this.ColumnModelChangeListener.Enabled = true;
            elseif strcmpi(ed.EventData.key, 'RowModelProperties')
            elseif strcmpi(ed.EventData.key, 'RowModelProperty')
                row = this.getStructValue(ed.EventData.newValue,'row');
                property = this.getStructValue(ed.EventData.newValue,'property');
                value = this.getStructValue(ed.EventData.newValue,'value');
                this.RowModelChangeListener.Enabled = false;
                this.MetaDataStore.setRowModelProperty(row+1, property, value);
                % Update the JSON internal cache
                [startRow, endRow, ~, ~] = this.getCurrentPage();
                if any(row+1 >= startRow) && any(row+1 <= endRow)
                    this.updateRowModelInformation(startRow, endRow);
                end
                this.RowModelChangeListener.Enabled = true;
            end
        end
        
        function handlePeerEvents(this, ~, ed)
            % Handles peer events from the client
            if isfield(ed.EventData, 'source') && strcmp('server', ed.EventData.source)
                % Ignore any events generated by the server
                return;
            end
            
            if isfield(ed.EventData,'type')
                switch ed.EventData.type
                    case 'getSize'
                        this.sendSizeToClient();
                    case 'getData'
                        this.handleClientGetData(ed.EventData);
                    case 'setData'
                        this.handleClientSetData(ed.EventData);
                    case 'getMetaData'
                        this.handleClientGetMetaData(ed.EventData);
                    case 'setViewportRange'
                        this.handleSetViewportRange(ed.EventData);
                end
            end
        end
        
        function sendSizeToClient(this)
            % Handles getSize from the client and dispatches a setSize peer
            % event.
            s = this.getTabularDataSize;
            this.setProperty('Size', struct('source', 'server', ...
                'rowCount', s(1), 'columnCount', s(2)));
        end
        
        function handleClientGetData(this, eventData)
            % Converts client getData request to MCOS getData call
            startRow = this.getStructValue(eventData, 'startRow') + 1;
            endRow = this.getStructValue(eventData, 'endRow') + 1;
            startColumn = this.getStructValue(eventData, 'startColumn') + 1;
            endColumn = this.getStructValue(eventData, 'endColumn') + 1;

            this.LastRequestedStartRow = startRow;
            this.LastRequestedEndRow = endRow;
            this.LastRequestedStartColumn = startColumn;
            this.LastRequestedEndColumn = endColumn;

            [startRow, endRow, startColumn, endColumn] = this.getAdjustedRange(startRow, endRow, startColumn, endColumn);
            this.sendDataToClient(startRow, endRow, startColumn, endColumn);
        end
        
        function handleSetViewportRange(this, eventData)
            startRow = this.getStructValue(eventData, 'startRow') + 1;
            endRow = this.getStructValue(eventData, 'endRow') + 1;
            startColumn = this.getStructValue(eventData, 'startColumn') + 1;
            endColumn = this.getStructValue(eventData, 'endColumn') + 1;
            this.setCurrentPage(startRow, endRow, startColumn, endColumn);
        end
        
        function sendDataToClient(this,...
                startRow, endRow, startColumn, endColumn,...
                fullStartRow, fullEndRow, fullStartColumn, fullEndColumn)
            arguments
                this (1,1) internal.matlab.datatoolsservices.peer.data.PeerTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                startColumn (1,1) double {mustBeNonnegative}
                endColumn (1,1) double {mustBeNonnegative}
                fullStartRow (1,1) double = startRow
                fullEndRow (1,1) double = endRow
                fullStartColumn (1,1) double = startColumn
                fullEndColumn (1,1) double = endColumn
            end
            
            % Adjust data down in case the request size is large than the
            % current size
            [startRow, endRow, startColumn, endColumn] = this.getAdjustedRange(startRow, endRow, startColumn, endColumn);
            
            % Get the rendered data and dimensions
            [data, dims] = this.formatDataForClient(...
                startRow, endRow, startColumn, endColumn);
            % Dispatch a peer event with the data
            % Use dimensions returned from formatDataForClient because it
            % may return less data than requested start + dims - 1
            % Since we're formatting for the client-side 0-based indexing
            % subtract 1.  (start+dims-1) - 1
            % startRow, endRow, startColum, and endColumn are for the
            % viewport update, these pertain to the data being sent
            % fullStartRow, fullEndRow, fullStartColumn, and fullEndColumn
            % are for the entire range of data affected, should be inclusive
            % of the startRow, endRow, startColumn, endColumn
            this.PeerNode.dispatchEvent(struct('type', 'setData', ...
                'source', 'server', ...
                'startRow', startRow-1, ...
                'endRow', (startRow+dims(1)-1)-1, ...
                'startColumn', startColumn-1, ...
                'endColumn', (startColumn+dims(2)-1)-1, ...
                'fullStartRow', fullStartRow-1, ...
                'fullEndRow', fullEndRow-1, ...
                'fullStartColumn', fullStartColumn-1, ...
                'fullEndColumn', fullEndColumn-1, ...
                'data', {data}, ...
                'rowCount',dims(1), ...
                'columnCount',dims(2)));
        end
        
        % formatDataForClient
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = formatDataForClient(this,startRow,endRow,startColumn,endColumn)
            data = this.getTabularDataRange(startRow, endRow, startColumn, endColumn);
            renderedData = cell(size(data));
            
            rowStrs = strtrim(cellstr(num2str((startRow-1:endRow-1)'))');
            colStrs = strtrim(cellstr(num2str((startColumn-1:endColumn-1)'))');
            
            for row=1:min(size(renderedData,1),size(data,1))
                for col=1:min(size(renderedData,2),size(data,2))
                    if iscell(data) || istable(data)
                        value = data{row, col};
                    else
                        value = data(row, col);
                    end
                    
                    if iscell(value)
                        value = this.toJSON(struct('value',value,...
                        'row',rowStrs{row},'col',colStrs{col}));
                     end
                    
                    jsonData = this.toJSON(struct('value',value,...
                        'row',rowStrs{row},'col',colStrs{col}));
                    
                    renderedData{row,col} = jsonData;
                end
            end
         
            renderedDims = size(renderedData);
        end
        
        function handleClientGetMetaData(this, eventData)
            % Converts client getData request to MCOS getData call
            startRow = this.getStructValue(eventData, 'startRow') + 1;
            endRow = this.getStructValue(eventData, 'endRow') + 1;
            startColumn = this.getStructValue(eventData, 'startColumn') + 1;
            endColumn = this.getStructValue(eventData, 'endColumn') + 1;

            [startRow, endRow, startColumn, endColumn] = this.getAdjustedRange(startRow, endRow, startColumn, endColumn);
            this.updateMetaDataModels(startRow, endRow, startColumn, endColumn);
        end
        
        function handleClientSetData(this, eventData)
            % Handles setData from the client and calls MCOS setData.  Also
            % fires a dataChangeStatus peerEvent.
            data = this.getStructValue(eventData, 'data');
            row = this.getStructValue(eventData, 'row');
            column = this.getStructValue(eventData, 'column');

            origValue = this.formatDataForClient(row, row, column, column);

            try
                this.setTabularDataValue(row, column, data);
                this.sendPeerEvent('dataChangeStatus', 'status', 'success', 'message', '', 'row', row, 'column', column, 'newValue', data, 'origValue', origValue);
            catch e
                % Send data change event.
                this.sendPeerEvent('dataChangeStatus', 'status', 'error', 'message', e.message, 'row', row, 'column', column, 'newValue', data, 'origValue', origValue);
            end
            
        end
        
        function [startRow, endRow, startColumn, endColumn] = getAdjustedRange(this, startRow, endRow, startColumn, endColumn)
            s = this.getTabularDataSize();
            startRow = min(max(1, startRow), s(1));
            endRow = max(min(s(1), endRow), startRow);
            startColumn = min(max(1, startColumn), startColumn);
            endColumn = max(min(s(2), endColumn), startColumn);
        end
        
        function setCurrentPage(this, startRow, endRow, startColumn, endColumn)
            % Converts client
            [this.ViewportStartRow, this.ViewportEndRow, this.ViewportStartColumn, this.ViewportEndColumn] = this.getAdjustedRange(startRow, endRow, startColumn, endColumn);
        end
        
        function [startRow, endRow, startColumn, endColumn] = getCurrentPage(this)
            startRow = this.ViewportStartRow;
            endRow = this.ViewportEndRow;
            startColumn = this.ViewportStartColumn;
            endColumn = this.ViewportEndColumn;
        end
        
        function pageSet = havePageSet(this)
            s = this.getTabularDataSize();
            pageSet = ~isempty(s) && ~isempty(this.ViewportStartColumn);
        end
        
        function handleCellModelUpdate(this, ~, ed)
            if this.havePageSet && ~isempty(ed.Row) && ~isempty(ed.Column)
                this.updateCellModelInformation(this.ViewportStartRow,...
                    this.ViewportEndRow, this.ViewportStartColumn,...
                    this.ViewportEndColumn, ed.Row, ed.Column);
            end
        end
        
        function handleTableModelUpdate(this, ~, ed)
            this.updateTableModelInformation();
        end
        
        function handleRowModelUpdate(this, ~, ed)
            if this.havePageSet && ~isempty(ed.Row)
                this.updateRowModelInformation(...
                    max(this.ViewportStartRow, min(ed.Row)),...
                    min(this.ViewportEndRow, max(ed.Row)), ed.Row);
            end
        end
        
        function handleColumnModelUpdate(this, ~, ed)
            if this.havePageSet && ~isempty(ed.Column)
                this.updateColumnModelInformation(...
                    max(this.ViewportStartColumn, min(ed.Column)),...
                    min(this.ViewportEndColumn, max(ed.Column)),...
                    ed.Column);
            end
        end
       
        % Update metadatamodels only when there is data for the
        % corresponding metadata, else this will result in erroneous
        % indexing.
        function updateMetaDataModels(this, startRow, endRow, startColumn, endColumn)
            hasRows = startRow > 0 & endRow > 0;
            hasColumns = startColumn > 0 & endColumn > 0;
            if (any(hasRows) && any(hasColumns))
                this.updateCellModelInformation(startRow, endRow, startColumn, endColumn);
            end
            this.updateTableModelInformation();
            if (hasRows)
                this.updateRowModelInformation(startRow, endRow);
            end
            if (hasColumns)
                this.updateColumnModelInformation(startColumn, endColumn);
            end
        end
        
        function updateCellModelInformation(this, startRow, endRow,...
                startColumn, endColumn, fullRows, fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.peer.data.PeerTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                startColumn (1,1) double {mustBeNonnegative}
                endColumn (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
                fullColumns (1,:) double = startColumn:endColumn
            end

            % Ensure that we adjust ranges to cap this to a max of
            % dataSize(g1969329)
            [startRow, endRow, startColumn, endColumn] = this.getAdjustedRange(...
                startRow, endRow, startColumn, endColumn);
            rmpca = cell(1,endRow-startRow+1);
            for row=startRow:endRow
                cmpca = cell(1,endColumn-startColumn+1);
                for column=startColumn:endColumn
                    cellMetaData = this.MetaDataStore.getTabularCellMetaData(row, column);
                    % Adding guard in case cellMetaData is not a struct
                    if ~isstruct(cellMetaData)
                        cellMetaData = struct();
                    end                    
                    cellMetaData.RowNumber = row;
                    cellMetaData.ColumnNumber = column;                    
                    % Always JSON for empty/non-empty data,else strjoin
                    % will fail.
                    cmpca{column-startColumn+1} = this.toJSON(cellMetaData);
                end
                rmpca{row-startRow+1} = '[';
                if ~isempty(cmpca) && ~isempty(cmpca{endColumn-startColumn+1})
                    rmpca{row-startRow+1} = [rmpca{row-startRow+1} strjoin(cmpca,',')];
                end
                rmpca{row-startRow+1} = [rmpca{row-startRow+1} ']'];
            end
            
            cellModelProps = '[';
            if ~isempty(rmpca)
                cellModelProps = [cellModelProps strjoin(rmpca,',')];
            end
            cellModelProps = [cellModelProps ']'];
            this.PeerNode.dispatchEvent(...
                struct('type', 'setCellMetaData', ...
                    'metaDataType', 'CellModelProperties', ...
                    'source', 'server', ...
                    'startRow', startRow-1, ...
                    'endRow', endRow-1, ...
                    'startColumn', startColumn-1, ...
                    'endColumn', endColumn-1, ...
                    'fullStartRow', min(fullRows)-1, ...
                    'fullEndRow', max(fullRows)-1, ...
                    'fullStartColumn', min(fullColumns)-1, ...
                    'fullEndColumn', max(fullColumns)-1, ...
                    'properties', cellModelProps));
        end
        
        function updateTableModelInformation(this)
            tableModelProps = this.toJSON(this.MetaDataStore.getTabularTableMetaData());
            this.PeerNode.dispatchEvent(...
                struct('type', 'setTableMetaData', ...
                    'metaDataType', 'TableModelProperties', ...
                    'source', 'server', ...
                    'properties', tableModelProps));
        end
        
        function updateRowModelInformation(this, startRow, endRow, fullRows)
            arguments
                this (1,1) internal.matlab.datatoolsservices.peer.data.PeerTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
            end
            [startRow, endRow, ~, ~] = this.getAdjustedRange(...
                startRow, endRow, -1, -1);
            rmpca = cell(1,endRow-startRow+1);
            for row=startRow:endRow
                rowMetaData = this.MetaDataStore.getTabularRowMetaData(row);
                % TODO: Only if metadata is available, add RowNumber field to the JSON.                
                rowMetaData.RowNumber = row;
                rmpca{row-startRow+1} = this.toJSON(rowMetaData);                
            end
            rowModelProps = '[';
            if ~isempty(rmpca) && ~any(cellfun(@(x)isempty(x), rmpca))
                rowModelProps = [rowModelProps strjoin(rmpca,',')];
            end
            rowModelProps = [rowModelProps ']'];
            this.PeerNode.dispatchEvent(...
                struct('type', 'setRowMetaData', ...
                    'metaDataType', 'RowModelProperties', ...
                    'source', 'server', ...
                    'startRow', startRow-1, ...
                    'endRow', endRow-1, ...
                    'fullStartRow', min(fullRows)-1, ...
                    'fullEndRow', max(fullRows)-1, ...
                    'properties', rowModelProps));
        end
        
        function updateColumnModelInformation(this,...
                startColumn,...
                endColumn, ...
                fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.peer.data.PeerTabularDataStore
                startColumn (1,1) double {mustBeNonnegative}
                endColumn (1,1) double {mustBeNonnegative}
                fullColumns (1,:) double = startColumn:endColumn
            end
            [~, ~, startColumn, endColumn] = this.getAdjustedRange(...
                -1, -1, startColumn, endColumn);
            cmpca = cell(1,endColumn-startColumn+1);
            for column=startColumn:endColumn
                columnMetaData = this.MetaDataStore.getTabularColumnMetaData(column);
                % TODO: Only if metadata is available, add ColumnNumber field to the JSON.                
                columnMetaData.ColumnNumber = column;
                cmpca{column-startColumn+1} = this.toJSON(columnMetaData);
                
            end
            columnModelProps = '[';
            if ~isempty(cmpca) && ~any(cellfun(@(x)isempty(x), cmpca))
                columnModelProps = [columnModelProps strjoin(cmpca,',')];
            end
            columnModelProps = [columnModelProps ']'];
            this.PeerNode.dispatchEvent(...
                struct('type', 'setColumnMetaData', ...
                    'metaDataType', 'ColumnModelProperties', ...
                    'source', 'server', ...
                    'startColumn', startColumn-1, ...
                    'endColumn', endColumn-1, ...
                    'fullStartColumn', min(fullColumns)-1, ...
                    'fullEndColumn', max(fullColumns)-1, ...
                    'properties', columnModelProps));
        end
        
        function sendPeerEvent(this, eventType, varargin)
            % Check for paired values
            if nargin<4 || rem(nargin-2, 2)~=0
                error(message('MATLAB:codetools:variableeditor:UseNameRowColTriplets'));
            end
            
            s = struct;
            s.source = 'server';
            s.type = eventType;

            for i=1:2:nargin-2
                s.(varargin{i}) = varargin{i+1};
            end
            this.PeerNode.dispatchEvent(s);
        end
        
        function [affectsViewport, affectsOtherRanges] = rangeAffectsViewport(this, StartRow, EndRow, StartColumn, EndColumn)
            r1 = [this.ViewportStartRow this.ViewportStartColumn this.ViewportEndRow-this.ViewportStartRow+1 this.ViewportEndColumn-this.ViewportStartColumn+1];
            r2 = [StartRow StartColumn EndRow-StartRow+1 EndColumn-StartColumn+1];

            if StartRow == EndRow && StartColumn == EndColumn
                otherRowsIntersect = ...
                    (StartRow < this.ViewportStartRow  || ...
                    StartRow > this.ViewportEndRow);

                otherColumnsIntersect = ...
                    (StartColumn < this.ViewportStartColumn  || ...
                    StartColumn > this.ViewportEndColumn);
            else
                otherRowsIntersect = ...
                    (StartRow < this.ViewportStartRow  || ...
                    StartRow > this.ViewportEndRow) || ...
                    (EndRow < this.ViewportStartRow  || ...
                    EndRow > this.ViewportEndRow);

                otherColumnsIntersect = ...
                    (StartColumn < this.ViewportStartColumn  || ...
                    StartColumn > this.ViewportEndColumn) || ...
                    (EndColumn < this.ViewportStartColumn  || ...
                    EndColumn > this.ViewportEndColumn);
            end

            affectsViewport = rectint(r1, r2) > 0;
            affectsOtherRanges = otherRowsIntersect || otherColumnsIntersect;

        end     
        
      
    end
end

