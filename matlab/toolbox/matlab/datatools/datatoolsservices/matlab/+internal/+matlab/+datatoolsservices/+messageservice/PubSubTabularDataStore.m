classdef PubSubTabularDataStore < internal.matlab.datatoolsservices.data.TabularDataStore
    %PubSubTabularDataStore A tabular datastore used to keep the backend and frontend representations of a table in sync.
    %   Detailed explanation goes here

    % TODO: Define the terms "debouncing", "throttling", and "coalescing" here for easy reference.

    % Copyright 2019-2024 The MathWorks, Inc.

    properties(Constant,Hidden)
        DEFAULT_PAGING_CHANNEL = "/DDT/PubSubPaging_";
        SRV_MSG_SIZE_CHANGED           (1,1) double = 1;
        SRV_MSG_DATA_CHANGED           (1,1) double = 2;
        SRV_MSG_META_TABLE_CHANGED     (1,1) double = 3;
        SRV_MSG_META_COL_CHANGED       (1,1) double = 4;
        SRV_MSG_META_ROW_CHANGED       (1,1) double = 5;
        SRV_MSG_META_CELL_CHANGED      (1,1) double = 6;
        SRV_MSG_CLEAR_DATA_BUFFER      (1,1) double = 7;
        SRV_MSG_CLEAR_METADATA_BUFFER  (1,1) double = 8;
        SRV_MSG_DATA_CHANGE_STATUS     (1,1) double = 9;
        SRV_MSG_THREAD_SAFETY_CHANGED  (1,1) double = 25;
 
        CLIENT_MSG_SET_VIEWPORT        (1,1) double = 10;
        CLIENT_MSG_GET_DATA            (1,1) double = 11;
        CLIENT_MSG_SET_DATA            (1,1) double = 12;
        CLIENT_MSG_GET_SIZE            (1,1) double = 13;
        CLIENT_MSG_GET_METADATA        (1,1) double = 14;
        CLIENT_MSG_SET_TABLE_METADATA  (1,1) double = 15;
        CLIENT_MSG_SET_COL_METADATA    (1,1) double = 16;
        CLIENT_MSG_SET_ROW_METADATA    (1,1) double = 17;
        CLIENT_MSG_SET_CELL_METADATA   (1,1) double = 18;
        CLIENT_MSG_SET_READY           (1,1) double = 19;

        CLIENT_MSG_GET_TABLE_METADATA  (1,1) double = 20;
        CLIENT_MSG_GET_COL_METADATA    (1,1) double = 21;
        CLIENT_MSG_GET_ROW_METADATA    (1,1) double = 22;
        CLIENT_MSG_GET_CELL_METADATA   (1,1) double = 23;

        BACKGROUNDPOOL_ROW_SIZE_LIMIT  (1,1) double = 100; % used by rowRangeInLimit
        BACKGROUNDPOOL_COL_SIZE_LIMIT  (1,1) double = 20;
        BACKGROUNDPOOL_DATA_SIZE_LIMIT (1,1) double = 2000;
        STR_NUMEL_CUTOFF_FOR_BACKGROUND_FETCHES (1,1) double = 250000;
        NUMEL_CUTOFF_FOR_BACKGROUND_FETCHES (1,1) double = 50000000;
        BACKGROUND_TRANSFER_TOLERANCE_CUTOFF = 0.25 % In seconds
        CAT_CUTOFF_FOR_BACKGROUND_FETCHES = 120000;

        % Ensure MessageService is constant. Making this an instance property will delete as soon as pubsubDS instance is deleted.
        MESSAGE_SERVICE_INSTANCE_NAME = 'DDTPubSubDataStore';
    end

    properties(SetAccess='protected', WeakHandle)
        MetaDataStore internal.matlab.datatoolsservices.data.DefaultTabularMetaDataStore;
    end

    properties(SetAccess={?internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore, ?matlab.unittest.TestCase})
        Channel;

        % Making the current range public
        ViewportStartRow = [];
        ViewportEndRow = [];
        ViewportStartColumn = [];
        ViewportEndColumn = [];
    end
    
    events
        ViewportPositionChanged; % Dispatched when the client view is scrolled
    end
    
    properties(Access={?internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore, ?matlab.unittest.TestCase}, Transient)
        LastRequestedStartRow = [];
        LastRequestedEndRow = [];
        LastRequestedStartColumn = [];
        LastRequestedEndColumn = [];
        
        % Server Model-Side Change Listeners
        DataChangeListener;
        CellModelChangeListener;
        TableModelChangeListener;
        RowModelChangeListener;
        ColumnModelChangeListener;

        ClientMessageListener;

        DS_UUID
    end

    properties(Access=protected)       
        % Property that is set once the client is ready to receive events
        ClientReady = false;
        % Buffer to hold events to be dispatched when the client is ready
        EventBufferForClient = {};
        % Buffer is always of size 3 to coalesce row, column and cell
        % requests in the buffer.
        RequestBuffer = {{};{};{}};

        % Can this send data in a background thread
        IsThreadSafe (1,1) logical = false;
    end

    methods
        function this = PubSubTabularDataStore(channel, metaDataStore, NVPairs)
            arguments
                channel (1,1) string =...
                    internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.DEFAULT_PAGING_CHANNEL +...
                    num2str(internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.getNextChannelID)

                metaDataStore (1,1) internal.matlab.datatoolsservices.data.TabularMetaDataStore =...
                    internal.matlab.datatoolsservices.data.DefaultTabularMetaDataStore

                NVPairs.EnableBreakpoints (1,1) logical = false
            end
            
            % Call superclass constructor
            this@internal.matlab.datatoolsservices.data.TabularDataStore();
            this.DS_UUID = matlab.lang.internal.uuid;

            this.Channel = channel;
            if isa(this, 'internal.matlab.datatoolsservices.data.TabularMetaDataStore')
                this.MetaDataStore = this;
            else
                this.MetaDataStore = metaDataStore;
            end
            this.ClientReady = false;

            % Update the Pad data requests flag by checking if the
            % threadpool is running
            this.getThreadpool();

            % Initialize Listeners
            try
                % This will fail in the backgroundPool
                this.DataChangeListener = event.listener(this, 'DataChange', @(es,ed)this.handleDataChange(ed));
                this.CellModelChangeListener = event.listener(this.MetaDataStore, 'CellMetaDataChanged', @(es,ed)this.handleCellModelUpdate(ed));
                this.TableModelChangeListener = event.listener(this.MetaDataStore, 'TableMetaDataChanged', @(es,ed)this.handleTableModelUpdate(ed));
                this.RowModelChangeListener = event.listener(this.MetaDataStore, 'RowMetaDataChanged', @(es,ed)this.handleRowModelUpdate(ed));
                this.ColumnModelChangeListener = event.listener(this.MetaDataStore, 'ColumnMetaDataChanged', @(es,ed)this.handleColumnModelUpdate(ed));
    
                % MessageService Listener
                this.ClientMessageListener = internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.getMessageService.subscribe(this.Channel, ...
                    @(msg)this.martialClientMessage(msg), ...
                    'enableDebugger', NVPairs.EnableBreakpoints || ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
                
            catch e
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::error", "e1: " + e.message);
            end
        end

        function martialClientMessage(this, msg)
            switch this.getStructValue(msg, 'eventType')
                case this.CLIENT_MSG_SET_VIEWPORT
                    this.handleSetViewportRange(msg);
                case this.CLIENT_MSG_GET_DATA
                    this.handleClientGetData(msg);
                case this.CLIENT_MSG_SET_DATA
                    this.handleClientSetData(msg);
                case this.CLIENT_MSG_GET_SIZE
                    this.sendSizeToClient();
                case this.CLIENT_MSG_GET_METADATA
                    this.handleClientGetMetaData(msg);
                case this.CLIENT_MSG_GET_TABLE_METADATA
                    this.handleClientGetTableMetaData(msg);
                case this.CLIENT_MSG_GET_COL_METADATA
                    this.handleClientGetColumnMetaData(msg);
                case this.CLIENT_MSG_GET_ROW_METADATA
                    this.handleClientGetRowMetaData(msg);
                case this.CLIENT_MSG_GET_CELL_METADATA
                    this.handleClientGetCellMetaData(msg);
                case this.CLIENT_MSG_SET_TABLE_METADATA
                    this.handleClientSetTableMetaData(msg);
                case this.CLIENT_MSG_SET_COL_METADATA
                    this.handleClientSetColumnMetaData(msg);
                case this.CLIENT_MSG_SET_ROW_METADATA
                    this.handleClientSetRowMetaData(msg);
                case this.CLIENT_MSG_SET_CELL_METADATA
                    this.handleClientSetCellMetaData(msg);
                case this.CLIENT_MSG_SET_READY
                    this.setClientReady();
            end
        end
        
        function fieldValue = getStructValue(~, s, field)
            fieldValue = [];            
            if isstruct(s) 
                if isfield(s, field)
                    fieldValue = s.(field);
                end
            elseif isobject(s)
                if isprop(s, field)
                    fieldValue = s.get(field);
                end
            else
                l = lasterror; %#ok<LERR>
                try
                    fieldValue = s.get(field);
                catch
                    % Clear last error because we don't want to hunt
                    % invalid error message when we could have just been u
                    if ~isempty(l)
                        lasterror(l); %#ok<LERR>
                    else
                        lasterror('reset'); %#ok<LERR>
                    end
                end
            end
        end

        function sendEvent(this, eventType, varargin)
            % Check for paired values
            if nargin<4 || rem(nargin-2, 2)~=0
                % TODO: add message catalog entry for this
                error('Arguments must be key value pairs.');
            end
            
            s = struct;
            s.type = eventType;  % Legacy property for existing view model usage

            for i=1:2:nargin-2
                s.(varargin{i}) = varargin{i+1};
            end
            if isnumeric(eventType) || strcmp(eventType, 'dataChangeStatus')
                if ~isnumeric(eventType)
                    eventType = this.SRV_MSG_DATA_CHANGE_STATUS;
                end
                s.eventType = eventType;
                this.messageserviceDispatchToClient(s);
            else
                % Certain usecases for errorStatus still have custom
                % MessageService channels
                message.publish(this.Channel + "/" + eventType, s, internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.MESSAGE_SERVICE_INSTANCE_NAME);
            end

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "sendEvent(" + eventType + ")");
        end

        function delete(this)
            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::delete", "started: " + this.Channel + "  isThreadSafe: " + this.IsThreadSafe);

            % Cleanup listeners
            this.deleteListener('DataChangeListener');
            this.deleteListener('CellModelChangeListener');
            this.deleteListener('TableModelChangeListener');
            this.deleteListener('RowModelChangeListener');
            this.deleteListener('ColumnModelChangeListener');          

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::delete", "executing: " + this.Channel);

            if ~isempty(this.ClientMessageListener)
                try
                    internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::delete", "unsubscribe");
                    % Turning off warnings for g3208443
                    % This warning is occurring because the test rapidly
                    % creates and destroys many uitables in a row and the
                    % timer in the eventcoalescer from the startup is
                    % allowing other deletes to happen in the middle of the
                    % current delete.  Since this issue doesn't cause any
                    % harm and is a bit of a pathological use case, for now
                    % we're going to suppress the warning and come back with
                    % a TODO to see if there is a better solution in the
                    % future.
                    % TODO: Revisit this in the future.
                    w = warning('off', 'all');

                    % Cancel any pending debounce timers for this object
                    matlab.internal.datatoolsservices.EventCoalescer.debounce("", 'scope', this.DS_UUID, 'cancelAll', true);

                    internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.getMessageService.unsubscribe(this.ClientMessageListener);
                    this.ClientMessageListener.delete;
                catch e
                    internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::delete", "unsubscribe failed(" + e.message + ")");
                end
                this.ClientMessageListener = [];
                warning(w);
            end
            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::delete", "ended: " + this.Channel);
        end
        
        function deleteListener(this, listener)
            if ~isempty(this.(listener)) && isvalid(this.(listener))
                delete(this.(listener));
                this.(listener) = [];
            end
        end
        
        function status = handlePropertySetFromClient(this, ~, ed)
            % Handles properties being set.  ed is the Event Data, and it
            % is expected that ed.data.key contains the property which
            % is being set.  Returns a status: empty string for success,
            % an error message otherwise.
            status = '';
            if isfield(ed.data,'source') && strcmp('server',ed.data.source)
                return;
            end
            
            if strcmpi(ed.data.key, 'TableModelProperties')
            elseif strcmpi(ed.data.key, 'TableModelProperty')
                property = this.getStructValue(ed.data.newValue,'property');
                value = this.getStructValue(ed.data.newValue,'value');
                this.TableModelChangeListener.Enabled = false;
                this.MetaDataStore.setTableModelProperty(property, value);
                % Update the JSON internal cache
                this.TableModelChangeListener.Enabled = true;
            elseif strcmpi(ed.data.key, 'CellModelProperties')
            elseif strcmpi(ed.data.key, 'CellModelProperty')
                property = this.getStructValue(ed.data.newValue,'property');
                value = this.getStructValue(ed.data.newValue,'value');
                row = this.getStructValue(ed.data.newValue,'row');
                column = this.getStructValue(ed.data.newValue,'column');
                this.CellModelChangeListener.Enabled = false;
                this.MetaDataStore.setCellModelProperty(row, column, property, value);
                % Update the JSON internal cache
                this.updateCellModelInformation(this.ViewportStartRow, this.ViewportEndRow, this.ViewportStartColumn, this.ViewportEndColumn);
                this.CellModelChangeListener.Enabled = true;
            elseif strcmpi(ed.data.key, 'ColumnModelProperties')
            elseif strcmpi(ed.data.key, 'ColumnModelProperty')
                column = this.getStructValue(ed.data.newValue,'column');
                property = this.getStructValue(ed.data.newValue,'property');       
                value = this.getStructValue(ed.data.newValue,'value');
                this.ColumnModelChangeListener.Enabled = false;
                this.MetaDataStore.setColumnModelProperty(column+1, property, value);
                % Update the JSON internal cache
                [~, ~, startColumn, endColumn] = this.getCurrentPage();
                if any(column+1 >= startColumn) && any(column+1 <= endColumn)
                    this.updateColumnModelInformation(startColumn, endColumn);
                end
                this.ColumnModelChangeListener.Enabled = true;
            elseif strcmpi(ed.data.key, 'RowModelProperties')
            elseif strcmpi(ed.data.key, 'RowModelProperty')
                row = this.getStructValue(ed.data.newValue,'row');
                property = this.getStructValue(ed.data.newValue,'property');
                value = this.getStructValue(ed.data.newValue,'value');
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

        function isThreadSafe = getThreadSafety(this)
            isThreadSafe = this.IsThreadSafe;
        end

    end

    methods(Access={?matlab.unittest.TestCase}, Static)
        function ms = getMessageService()
            mlock;
            persistent MessageService;
            if isempty(MessageService)
                MessageService = message.internal.MessageService(internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.MESSAGE_SERVICE_INSTANCE_NAME);
            end

            ms = MessageService;
        end

        function nextID = getNextChannelID()
            mlock;
            persistent lastID;
            if isempty(lastID)
                lastID = 0;
            end
            nextID = lastID+1;
            lastID = nextID;
        end

        function args = getArgsText(inputArgs)
            % defer converting args to text until needed, as this can take time.
            %  Called by executeInBackgroundIfPossible();
            c = inputArgs;
            % Check for scalars, we do not want to serialize arrays like fullRows, fullColumns
            argsCanConvert = cellfun(@(x) isscalar(x) && (isnumeric(x) || ischar(x) || islogical(x) || isstring(x) || isdatetime(x) || isduration(x) || iscategorical(x)), c);
            if all(argsCanConvert)
                args = matlab.io.text.internal.cell2text(c);
            elseif all(argsCanConvert(2:end))
                args = matlab.io.text.internal.cell2text(c(2:end));
            else
                c(~argsCanConvert) = {'<NA>'};
                args = matlab.io.text.internal.cell2text(c(2:end));
            end
        end

        function dispIfError(f, NVPairs)
            if ~isempty(f.Error)
                errorStr = sprintf("\n**************************************************\n");
                errorStr = errorStr + sprintf("* Error executing in background thread: %s%s\n** %s\n", func2str(NVPairs.fcn), ...
                    internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.getArgsText(NVPairs.inputArgs), ...
                    f.Error.message);
                if ~isempty(f.Error.stack)
                    errorStr = errorStr + sprintf("*** %s - %d\n", f.Error.stack(1).name, f.Error.stack(1).line);
                end
                errorStr = errorStr + sprintf("**************************************************\n");
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", errorStr);
            else
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", sprintf("Background Execution Successfull: %s(%s)\n", func2str(NVPairs.fcn),...
                    internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.getArgsText(NVPairs.inputArgs)));
            end
        end
    end

    methods(Static)
        function [backgrounPoolIsRunning] = isThreadpoolStarted(whichPool)
            arguments
                whichPool (1,1) parallel.internal.pool.PoolApiTag = parallel.internal.pool.PoolApiTag.Internal
            end

            % TODO:  revisit when a new API is available
            manager = parallel.internal.pool.PoolManager.getInstance;
            backgrounPoolIsRunning = ~isempty(getAllPools(manager, whichPool));
        end

        function pool = startPool(whichPool)
            arguments
                whichPool (1,1) parallel.internal.pool.PoolApiTag = parallel.internal.pool.PoolApiTag.Internal
            end

            pool = [];
            switch (whichPool)
                case parallel.internal.pool.PoolApiTag.Internal
                    pool = matlab.internal.threadPool();
                case parallel.internal.pool.PoolApiTag.Parpool
                    pool = gcp;
                case parallel.internal.pool.PoolApiTag.Background
                    pool = backgroundPool;
            end
        end
    end    
    
    methods(Access=protected)
        % Allows setting property on the View. Making this public to allow
        % our view actions and plugins to be able to set properties.
%         function setProperty(this, propertyName, propertyValues)
%             arguments
%                 this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
%                 propertyName (1,1) string
%                 propertyValues (1,1) struct
%             end
%             if isfield(propertyValues, "propertyName")
%                 propertyValues.propertyName = propertyName;
%             end
%             
%             message.publish(this.Channel + "/setViewProperty", propertyValues);
%         end

        function setThreadSafety(this, isThreadSafe)
            if isThreadSafe ~= this.IsThreadSafe
                this.IsThreadSafe = isThreadSafe;
                % Send this to the client to prevent any data padding
                % requests
                this.messageserviceDispatchToClient(struct(...
                    'eventType', this.SRV_MSG_THREAD_SAFETY_CHANGED, ...
                    'isThreadSafe', this.IsThreadSafe, ...
                    'source', 'server'));
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::setThreadSafety::", num2str(this.IsThreadSafe));
            end
        end

        function handleDataChange(this, ed)
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
                        % If sizeChanged, check if there is a viewport
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
                % If size changed in a way that it did not affect viewport
                % (could be that the server is yet to hear of the most
                % updated viewport from client), publish viewport data (g2532219)
                elseif ed.SizeChanged
                    startRow = min(max(startRow, this.ViewportStartRow), ed.StartRow);
                    endRow = min(max(endRow, this.ViewportEndRow), ed.EndRow);
                    startColumn = min(max(startColumn, this.ViewportStartColumn), ed.StartColumn);
                    endColumn = min(max(endColumn, this.ViewportEndColumn), ed.EndColumn);
                end
                % If we don't have a data range to update, short circuit.
                % (But do this only when viewport is unset, viewport can be unset for very first dataChange, 
                % We still want to senddata to client.
                if ~isempty(this.ViewportStartRow) && ~isempty(this.ViewportStartColumn)
                    if ((startRow == 0 && endRow == 0) || (startColumn == 0 && endColumn == 0)) && (this.ViewportStartRow ~=0 && this.ViewportStartColumn ~=0)
                        % Something outside the viewport has changed
                        this.clearClientBuffer(ed.StartRow, ed.EndRow, ed.StartColumn, ed.EndColumn, 'server')
                        return;
                    end
                end

                % Send the data to the client
                this.sendDataToClient(startRow, endRow, startColumn, endColumn, ...
                    ed.StartRow, ed.EndRow, ed.StartColumn, ed.EndColumn);
            end
        end      
        
        function clearClientBuffer(this, startRow, endRow, startColumn, endColumn, source)
            currentViewPort = struct('startRow', this.ViewportStartRow-1, 'endRow', this.ViewportEndRow-1, 'startColumn', this.ViewportStartColumn-1, 'endColumn', this.ViewportEndColumn-1);            
            this.sendEvent(this.SRV_MSG_CLEAR_DATA_BUFFER, 'startRow', startRow-1, 'endRow', endRow-1, 'startColumn', startColumn-1, 'endColumn', endColumn-1, 'source', source, 'CurrentViewport', jsonencode(currentViewPort));
        end
        
        function clearClientMetaDataBuffer(this, metaDataType, eventData)            
            this.sendEvent(this.SRV_MSG_CLEAR_METADATA_BUFFER, 'metaDataType', metaDataType, 'rows', eventData.Row, 'columns', eventData.Column);
        end
        
        function status = handleClientSetTableMetaData(this, ed)
            status = '';
            this.TableModelChangeListener.Enabled = false;

            tablePropValues = this.getStructValue(ed,'value');
            tableModelPropsLen = length(tablePropValues);
            tableMetaData = {};
            for i=1:tableModelPropsLen
                propVal = tablePropValues(i);
                tableMetaData{end+1} = propVal.name;
                tableMetaData{end+1} = propVal.value;
            end
            this.MetaDataStore.setTableModelProperties(tableMetaData{:});
            % Update the JSON internal cache
            this.updateTableModelInformation();
            this.TableModelChangeListener.Enabled = true;
        end
        
        function status = handleClientSetColumnMetaData(this, ed)
            status = '';
            if isfield(ed,'source') && strcmp('server',ed.source)
                return;
            end
            
            column = this.getStructValue(ed,'column');
            property = this.getStructValue(ed,'property');
            value = this.getStructValue(ed,'value');
            this.ColumnModelChangeListener.Enabled = false;
            this.MetaDataStore.setColumnModelProperty(column+1, property, value);
            % Update the JSON internal cache
            [~, ~, startColumn, endColumn] = this.getCurrentPage();
            if any(column+1 >= startColumn) && any(column+1 <= endColumn)
                this.updateColumnModelInformation(startColumn, endColumn);
            end
            this.ColumnModelChangeListener.Enabled = true;
        end
        
        function status = handleClientSetRowMetaData(this, ed)
            status = '';
            if isfield(ed,'source') && strcmp('server', ed.source)
                return;
            end
            
            row = this.getStructValue(ed,'row');
            property = this.getStructValue(ed,'property');
            value = this.getStructValue(ed,'value');
            this.RowModelChangeListener.Enabled = false;
            this.MetaDataStore.setRowModelProperty(row+1, property, value);
            % Update the JSON internal cache
            [startRow, endRow, ~, ~] = this.getCurrentPage();
            if any(row+1 >= startRow) && any(row+1 <= endRow)
                this.updateRowModelInformation(startRow, endRow);
            end
            this.RowModelChangeListener.Enabled = true;
        end
        
        function status = handleClientSetCellMetaData(this, ed)
            status = '';
            if isfield(ed,'source') && strcmp('server',ed.source)
                return;
            end
            
            property = this.getStructValue(ed,'property');
            value = this.getStructValue(ed,'value');
            row = this.getStructValue(ed,'row');
            column = this.getStructValue(ed,'column');
            this.CellModelChangeListener.Enabled = false;
            this.MetaDataStore.setCellModelProperty(row, column, property, value);
            % Update the JSON internal cache
            this.updateCellModelInformation(this.ViewportStartRow, this.ViewportEndRow, this.ViewportStartColumn, this.ViewportEndColumn);
            this.CellModelChangeListener.Enabled = true;
        end

        function sendSizeToClient(this)
            % Handles getSize from the client and dispatches a sizeChanged
            % event.
            s = this.getTabularDataSize;
            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "sendSizeToClient(" + s(1) + "," + s(2) + ")");
            this.messageserviceDispatchToClient(struct('source', 'server', ...
                'eventType', this.SRV_MSG_SIZE_CHANGED, ...
                'rowCount', s(1), 'columnCount', s(2)));
        end
        
        function handleClientGetData(this, eventData)
            % Converts client getData request to MCOS getData call
            startRow = this.getStructValue(eventData, 'startRow') + 1;
            endRow = this.getStructValue(eventData, 'endRow') + 1;
            startColumn = this.getStructValue(eventData, 'startColumn') + 1;
            endColumn = this.getStructValue(eventData, 'endColumn') + 1;
            evtSource = this.getStructValue(eventData, 'eventSource');
            isBackgroundRequest = strcmp(evtSource, 'BackgroundFetch');
            if ~this.isValidFetchRequest(isBackgroundRequest)
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::handleClientGetData", "returning on getData as we are no longer thread safe");
                return;
            end
            % disp("Client getdata!!"+  num2str(startRow)  + "****************" + num2str(endRow) );
            this.LastRequestedStartRow = startRow;
            this.LastRequestedEndRow = endRow;
            this.LastRequestedStartColumn = startColumn;
            this.LastRequestedEndColumn = endColumn;

            [startRow, endRow, startColumn, endColumn] = this.getAdjustedRange(startRow, endRow, startColumn, endColumn);
            s = this.getTabularDataSize;
            if startRow > s(1) || startColumn > s(2)
                % Request is outside data range, don't send anything
                return;
            end
            this.sendDataToClient(startRow, endRow, startColumn, endColumn);
        end
        
        function handleSetViewportRange(this, eventData)
            startRow = this.getStructValue(eventData, 'startRow') + 1;
            endRow = this.getStructValue(eventData, 'endRow') + 1;
            startColumn = this.getStructValue(eventData, 'startColumn') + 1;
            endColumn = this.getStructValue(eventData, 'endColumn') + 1;
            this.setCurrentPage(startRow, endRow, startColumn, endColumn);
        end
        
        function sendDataMessage(this, data, dims, startRow, ~, startColumn, ~, fullStartRow, fullEndRow, fullStartColumn, fullEndColumn)
            % Dispatch an event with the data
            % Use dimensions returned from formatDataForClient because it
            % may return less data than requested start + dims - 1
            % Since we're formatting for the client-side 0-based indexing
            % subtract 1.  (start+dims-1) - 1
            % startRow, endRow, startColum, and endColumn are for the
            % viewport update, these pertain to the data being sent
            % fullStartRow, fullEndRow, fullStartColumn, and fullEndColumn
            % are for the entire range of data affected, should be inclusive
            % of the startRow, endRow, startColumn, endColumn
            this.messageserviceDispatchToClient(struct(...
                'source', 'server', ...
                'eventType', this.SRV_MSG_DATA_CHANGED, ...
                'startRow', startRow-1, ...
                'endRow', (startRow+dims(1)-1)-1, ...
                'startColumn', startColumn-1, ...
                'endColumn', (startColumn+dims(2)-1)-1, ...
                'fullStartRow', fullStartRow-1, ...
                'fullEndRow', fullEndRow-1, ...
                'fullStartColumn', fullStartColumn-1, ...
                'fullEndColumn', fullEndColumn-1, ...
                'partialData', jsonencode(string(data)), ...
                'rowCount',dims(1), ...
                'columnCount',dims(2)));
        end

        function [this, data, dims, startRow, endRow, startColumn, endColumn] = formatAndSendDataMessage(this, startRow, endRow, startColumn, endColumn, fullStartRow, fullEndRow, fullStartColumn, fullEndColumn)
            % Get the rendered data and dimensions
            [data, dims] = formatDataForClient(this, ...
                startRow, endRow, startColumn, endColumn);
            sendDataMessage(this, data, dims, startRow, endRow, startColumn, endColumn, fullStartRow, fullEndRow, fullStartColumn, fullEndColumn);

            % Seeing columns of 0,0 logged here just means that the data is out
            % of range of the current viewport
            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore","Name::"+ this.Channel + ...
                ":formatAndSendDataMessage(rows=[" + startRow + "," + endRow + "]" + ...
                ",cols=[" + startColumn + "," + endColumn + "]" + ...
                ",fullrows=[" + fullStartRow + "," + fullEndRow + "]" + ...
                ",fullcols=[" + fullStartColumn + "," + fullEndColumn + "])");
        end

        function sendDataToClient(this,...
                startRow, endRow, startColumn, endColumn,...
                fullStartRow, fullEndRow, fullStartColumn, fullEndColumn)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
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

            affectsViewport = true;
            affectMoreThanViewport = false;
            if this.havePageSet
                [affectsViewport, affectMoreThanViewport] = this.rangeAffectsViewport(startRow, endRow, startColumn, endColumn);
            end

            this.executeInBackgroundIfPossible(fcn=@formatAndSendDataMessage,...
                numOutputArgs=0,...
                criteria=((affectsViewport && ~affectMoreThanViewport) || rangeInLimit(startRow, endRow, startColumn, endColumn)),...
                inputArgs={this, startRow, endRow, startColumn, endColumn, fullStartRow, fullEndRow, fullStartColumn, fullEndColumn});
        end

        function [pool, backgrounPoolIsRunning] = getThreadpool(this, forceStart, whichPool)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore %#ok<INUSA>
                forceStart (1,1) logical = false
                whichPool (1,1) parallel.internal.pool.PoolApiTag = parallel.internal.pool.PoolApiTag.Internal
            end

            backgrounPoolIsRunning = internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.isThreadpoolStarted(whichPool);

            pool = [];
            if backgrounPoolIsRunning || forceStart
                pool = internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.startPool(whichPool);
            end
        end

        function executeInBackgroundIfPossible(this, NVPairs)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                NVPairs.fcn (1,1) function_handle
                NVPairs.numOutputArgs (1,1) double {mustBeNonnegative, mustBeInteger}
                NVPairs.inputArgs cell = {}
                NVPairs.criteria (1,1) logical = true
                NVPairs.completionFcn function_handle = function_handle.empty
            end

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::executeInBackgroundIfPossible", sprintf("%s%s\n", func2str(NVPairs.fcn)));
            [pool, backgrounPoolIsRunning] = this.getThreadpool();
            runSynchronously = false;
            if ~this.IsThreadSafe || ~backgrounPoolIsRunning || NVPairs.criteria
                runSynchronously = true;
            else
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::executeInBackgroundIfPossible", sprintf("--> Executing in background thread: %s%s\n", func2str(NVPairs.fcn)));
                
                % Turn off warnings from threadpool attempt
                origWarningState = warning('off');
                
                try
                    if ~isempty(NVPairs.fcn)
                        fcn = NVPairs.fcn;
                        numOutArgs = NVPairs.numOutputArgs;
                        inArgs = NVPairs.inputArgs;
                        tic;f = parfeval(pool, fcn, numOutArgs, inArgs{:});endTime = toc;
                        if endTime > this.BACKGROUND_TRANSFER_TOLERANCE_CUTOFF
                            this.setThreadSafety(false);
                            % cancel(f);
                        end
                        if ~isempty(NVPairs.completionFcn)
                            compFcn = NVPairs.completionFcn;
                            afterEach(f, compFcn, 0);
                        end
        
                        params = NVPairs;
                        afterEach(f, @(f) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.dispIfError(f, params), 0, "PassFuture", true);
                    else
                        internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::executeInBackgroundIfPossible", sprintf("Exception --> Executing in background function: %s\n\tFalling back to synchronous execution", e.message));
                        runSynchronously = true;
                    end
                catch e
                    % Could not run in background pool, likely because
                    % object contained non-serializable content, run in
                    % main thread instead
                    internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::executeInBackgroundIfPossible", sprintf("Exception --> Executing in background thread: %s\n\tFalling back to synchronous execution", e.message));
                    runSynchronously = true;
                end

                % Restore warning state
                warning(origWarningState);
            end
            if runSynchronously
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::executeInBackgroundIfPossible", sprintf("Executing in main thread: %s: %s\n", func2str(NVPairs.fcn)));
                outputVals = {};
                if NVPairs.numOutputArgs > 0
                    outputVals = cell(1, NVPairs.numOutputArgs);
                    [outputVals{:}] = NVPairs.fcn(NVPairs.inputArgs{:});
                else
                    NVPairs.fcn(NVPairs.inputArgs{:});
                end
                if ~isempty(NVPairs.completionFcn)
                    NVPairs.completionFcn(outputVals{:});
                end

                % Force the startup of the thread pool if not already
                % started and we have a sufficiently large dataset to
                % warrant fetching data in the background
                if ~backgrounPoolIsRunning && this.IsThreadSafe && ~NVPairs.criteria
                    internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::executeInBackgroundIfPossible", sprintf("Starting thread pool\n"));
                    poolStartCmd = "[~] = internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.startPool;";
                    internal.matlab.datatoolsservices.executeCmd(poolStartCmd);
                end
            end
        end
        
        % formatDataForClient
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = formatDataForClient(this,startRow,endRow,startColumn,endColumn)
            % If viewport has no rows, do not attempt fetching data
            data = [];      
            if startRow > 0
                data = this.getTabularDataRange(startRow, endRow, startColumn, endColumn);
            end
            renderedData = cell(size(data));
            cellOrTable = iscell(data) || istable(data);
            for row=1:min(size(renderedData,1),size(data,1))
                for col=1:min(size(renderedData,2),size(data,2))
                    if cellOrTable
                        value = data{row, col};
                    else
                        value = data(row, col);
                    end
                    jsonData = jsonencode(value);
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
            metaDataConfig = this.getStructValue(eventData, 'metaDataConfig');
            evtSource = this.getStructValue(eventData, 'eventSource');
            [startRow, endRow, startColumn, endColumn] = this.getAdjustedRange(startRow, endRow, startColumn, endColumn);

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "handleClientGetMetaData([" + startRow + "," + endRow + "], [" + startColumn + "," + endColumn + ")");


            this.updateMetaDataModels(startRow, endRow, startColumn, endColumn, metaDataConfig, evtSource);
        end

        function handleClientGetTableMetaData(this, ~)
            this.updateTableModelInformation();
        end

        function handleClientGetColumnMetaData(this, eventData)
            % Converts client getData request to MCOS getData call
            startRow = this.getStructValue(eventData, 'startRow') + 1;
            endRow = this.getStructValue(eventData, 'endRow') + 1;
            startColumn = this.getStructValue(eventData, 'startColumn') + 1;
            endColumn = this.getStructValue(eventData, 'endColumn') + 1;

            [~, ~, startColumn, endColumn] = this.getAdjustedRange(startRow, endRow, startColumn, endColumn);
            
            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "handleClientGetColumnMetaData(" + startColumn + "," + endColumn + ")");

            hasColumns = startColumn > 0 & endColumn > 0;
            if (hasColumns)
                this.updateColumnModelInformation(startColumn, endColumn);
            end
        end

        function handleClientGetRowMetaData(this, eventData)
            % Converts client getData request to MCOS getData call
            startRow = this.getStructValue(eventData, 'startRow') + 1;
            endRow = this.getStructValue(eventData, 'endRow') + 1;
            startColumn = this.getStructValue(eventData, 'startColumn') + 1;
            endColumn = this.getStructValue(eventData, 'endColumn') + 1;

            [startRow, endRow, ~, ~] = this.getAdjustedRange(startRow, endRow, startColumn, endColumn);
            hasRows = startRow > 0 & endRow > 0;
            if (hasRows)
                this.updateRowModelInformation(startRow, endRow);
            end
        end

        function handleClientGetCellMetaData(this, eventData)
            % Converts client getData request to MCOS getData call
            startRow = this.getStructValue(eventData, 'startRow') + 1;
            endRow = this.getStructValue(eventData, 'endRow') + 1;
            startColumn = this.getStructValue(eventData, 'startColumn') + 1;
            endColumn = this.getStructValue(eventData, 'endColumn') + 1;

            [startRow, endRow, startColumn, endColumn] = this.getAdjustedRange(startRow, endRow, startColumn, endColumn);
            hasRows = startRow > 0 & endRow > 0;
            hasColumns = startColumn > 0 & endColumn > 0;
            if (any(hasRows) && any(hasColumns))
                this.updateCellModelInformation(startRow, endRow, startColumn, endColumn);
            end
        end

        function handleClientSetData(this, eventData)
            % Handles setData from the client and calls MCOS setData.  Also
            % fires a dataChangeStatus e.
            data = this.getStructValue(eventData, 'data');
            row = this.getStructValue(eventData, 'row');
            column = this.getStructValue(eventData, 'column');

            origValue = this.formatDataForClient(row, row, column, column);

            try
                this.setTabularDataValue(row, column, data);
                this.sendEvent(this.SRV_MSG_DATA_CHANGE_STATUS, 'status', 'success', 'message', '', 'row', row, 'column', column, 'newValue', data, 'origValue', origValue);
            catch e
                % Send data change event.
                this.sendEvent(this.SRV_MSG_DATA_CHANGE_STATUS, 'status', 'error', 'message', e.message, 'row', row, 'column', column, 'newValue', data, 'origValue', origValue);
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

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "setCurrentPage(rows=[" + startRow + "," + endRow + "]" + ",cols=[" + startColumn + "," + endColumn + "])");

            % Broadcast the new viewport position
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.StartRow = this.ViewportStartRow;
            eventdata.EndRow = this.ViewportEndRow;
            eventdata.StartColumn = this.ViewportStartColumn;
            eventdata.EndColumn = this.ViewportEndColumn;
            this.notify('ViewportPositionChanged', eventdata);
            % Flush the request buffer to ensure that any metadata requests
            % issued during page unset are queued and executed.
            for i=1:length(this.RequestBuffer)
                if ~isempty(this.RequestBuffer{i})
                    this.RequestBuffer{i,1}(this.RequestBuffer{i,2});
                end
            end
            this.RequestBuffer = {};
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
        
        function handleCellModelUpdate(this, ed)
             if ~isempty(ed.Row) && ~isempty(ed.Column)
                 if this.havePageSet
                    % Refresh up to the viewport boundaries, any additional
                    % range will be sent as fullRows, fullColumns to clear
                    % buffer on client.
                    [startRow, endRow, startColumn, endColumn] = this.getAdjustedRange(...
                        max(this.ViewportStartRow, min(ed.Row)),...
                        min(this.ViewportEndRow, max(ed.Row)),...
                        max(this.ViewportStartColumn, min(ed.Column)),...
                        min(this.ViewportEndColumn, max(ed.Column)));
                    this.updateCellModelInformation(...
                        startRow, endRow, startColumn, endColumn, ed.Row, ed.Column);
                 else
                     % If Page Unset, Queue cellmodelupdate requests.
                    this.updateRequestBuffer(ed);
                 end                
            end
        end
        
        function handleTableModelUpdate(this, ~)
            this.updateTableModelInformation();
        end
        
        function handleRowModelUpdate(this, ed)            
            if ~isempty(ed.Row)
                if this.havePageSet 
                    this.updateRowModelInformation(...
                        max(this.ViewportStartRow, min(ed.Row)),...
                        min(this.ViewportEndRow, max(ed.Row)), ed.Row);
                else
                    % If Page Unset, Queue rowmodelupdate requests.
                   this.updateRequestBuffer(ed);
                end
            end
        end
        
        function handleColumnModelUpdate(this, ed)
            if ~isempty(ed.Column)
                if this.havePageSet
                    this.updateColumnModelInformation(...
                        max(this.ViewportStartColumn, min(ed.Column)),...
                        min(this.ViewportEndColumn, max(ed.Column)),...
                        ed.Column);
                else
                    % If Page Unset, Queue columnmodelupdate requests.
                   this.updateRequestBuffer(ed);
                end
            end
        end
        
        % When page is unset, this method queues all the metadata requests.
        % If request in the buffer index does not, queue the request,
        % else just update the event data indices.(g2512616)
        % RequestBuffer = {{rowFnHandle, ed}, {colFnHandle, ed} {cellFnHandle, ed}}
        function updateRequestBuffer(this,ed)
            switch ed.EventName
                case 'RowMetaDataChanged'
                    rEntry = this.RequestBuffer{1};
                    ed.('Row') = reshape(ed.('Row').',1,[]);
                    if isempty(rEntry)
                        this.RequestBuffer{1,1}=@this.handleRowModelUpdate;
                        this.RequestBuffer{1,2}=ed;
                    else
                        ed.('Row') = unique([this.RequestBuffer{1,2}.('Row') ed.('Row')]);
                        this.RequestBuffer{1,2} = ed;
                    end
                case 'ColumnMetaDataChanged'
                    rEntry = this.RequestBuffer{2};
                    ed.('Column') = reshape(ed.('Column').',1,[]);
                    if isempty(rEntry)
                        this.RequestBuffer{2,1}=@this.handleColumnModelUpdate;
                        this.RequestBuffer{2,2}=ed;
                    else
                        ed.('Column') = unique([this.RequestBuffer{2,2}.('Column') ed.('Column')]);
                        this.RequestBuffer{2,2} = ed;
                    end
                case 'CellMetaDataChanged'
                    rEntry = this.RequestBuffer{3};
                    % Ensure that Row and column are row vectors for horzconcat.
                    ed.('Row') = reshape(ed.('Row').',1,[]);
                    ed.('Column') = reshape(ed.('Column').',1,[]);
                    if isempty(rEntry)
                        this.RequestBuffer{3,1}=@this.handleCellModelUpdate;
                        this.RequestBuffer{3,2}=ed;
                    else
                        ed.('Row') = unique([this.RequestBuffer{3,2}.('Row') ed.('Row')]);
                        ed.('Column') = unique([this.RequestBuffer{3,2}.('Column') ed.('Column')]);
                        this.RequestBuffer{3,2} = ed;
                    end
            end
        end
        
        % Sets the client as ready and dispatches all events currently in
        % the client buffer;
        function setClientReady(this)
            this.ClientReady = true;
            for i = 1:length(this.EventBufferForClient)
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::setClientReady", "Dispatching buffered event");
                this.messageserviceDispatchToClient(this.EventBufferForClient{1});
                this.EventBufferForClient(1) = [];
            end

            % Update the Pad data requests flag by checking if the
            % threadpool is running
            this.getThreadpool();
        end
       
        % Update metadatamodels only when there is data for the
        % corresponding metadata, else this will result in erroneous
        % indexing.
        function updateMetaDataModels(this, startRow, endRow, startColumn, endColumn, metadataConfig, evtSource)
            arguments
                this
                startRow        double = 1
                endRow          double = 1
                startColumn     double = 1
                endColumn       double = 1
                metadataConfig  struct = struct.empty
                evtSource       string = string.empty
            end
            hasRows = startRow > 0 & endRow > 0;
            hasColumns = startColumn > 0 & endColumn > 0;
            noMetaDataConfigProvided = isempty(metadataConfig);
            isBackgroundRequest = strcmp(evtSource, 'BackgroundFetch');
            if (any(hasRows) && any(hasColumns))
                if noMetaDataConfigProvided || ~isfield(metadataConfig, 'fetchCells') || (isfield(metadataConfig, 'fetchCells') && metadataConfig.fetchCells)
                    this.updateCellModelInformation(startRow, endRow, startColumn, endColumn);
                end
            end
            % Sometimes updateCellModelInformation can be slow enough to
            % turn off background fetches, if isThreadSafe was updated
            % after a backfground request came in, do not update any
            % further
            if ~this.isValidFetchRequest(isBackgroundRequest)
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::updateMetaDataModels", "returning on getMetaData as we are no longer thread safe");
                return;
            end
            if noMetaDataConfigProvided || ~isfield(metadataConfig, 'fetchTables') || (isfield(metadataConfig, 'fetchTables') && metadataConfig.fetchTables)
                this.updateTableModelInformation();
            else
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::updateMetaDataModels", "Not going to fetch tablemetadata");

            end
            if (hasRows)
                if noMetaDataConfigProvided || ~isfield(metadataConfig, 'fetchRows') || (isfield(metadataConfig, 'fetchRows') && metadataConfig.fetchRows)
                    this.updateRowModelInformation(startRow, endRow);
                end
            end
            if (hasColumns)
                 if noMetaDataConfigProvided || ~isfield(metadataConfig, 'fetchColumns') || (isfield(metadataConfig, 'fetchColumns') && metadataConfig.fetchColumns)
                    this.updateColumnModelInformation(startColumn, endColumn);
                 end
            end
        end

        function isSupported = isValidFetchRequest(this, isBackgroundRequest)
            isSupported = true;
            if isBackgroundRequest
                isSupported = this.IsThreadSafe;
            end
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

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "updateCellModelInformation(" + startRow + "," + endRow + "," + startColumn + "," + endColumn + ")");

            % Ensure that we adjust ranges to cap this to a max of
            % dataSize(g1969329)
            [startRow, endRow, startColumn, endColumn] = this.getAdjustedRange(...
                startRow, endRow, startColumn, endColumn);

            affectsViewport = true;
            affectMoreThanViewport = false;
            if this.havePageSet
                [affectsViewport, affectMoreThanViewport] = this.rangeAffectsViewport(startRow, endRow, startColumn, endColumn);
            end

            this.executeInBackgroundIfPossible(fcn=@sendCellMetaData,...
                numOutputArgs=0,...
                criteria=((affectsViewport && ~affectMoreThanViewport) || rangeInLimit(startRow, endRow, startColumn, endColumn)),...
                inputArgs={this, startRow, endRow, startColumn, endColumn, fullRows, fullColumns});
        end

        function sendCellMetaData(this, startRow, endRow,...
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

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "sendCellMetaData(rows=[" + startRow + "," + endRow + "]" + ", cols=[" + startColumn + "," + endColumn + "])");

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
                    % Cannot do struct concatenation, hence encoding it
                    % here
                    cmpca{column-startColumn+1} = jsonencode(cellMetaData);
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
            this.messageserviceDispatchToClient(struct(...
                'eventType', this.SRV_MSG_META_CELL_CHANGED, ...
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

        function sendTableModelInformationDebounced(this)
            try
                if ~isvalid(this) || ~isvalid(this.MetaDataStore)
                    return;
                end
                tableModelProps = jsonencode(this.MetaDataStore.getTabularTableMetaData());

                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "Sending Table Model Properties(" + tableModelProps + "), channel(" + this.Channel + ")");

                this.messageserviceDispatchToClient(struct(...
                    'eventType', this.SRV_MSG_META_TABLE_CHANGED, ...
                    'metaDataType', 'TableModelProperties', ...
                    'source', 'server', ...
                    'properties', tableModelProps));
            catch ex
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "Error in sendTableModelInformationDebounced: " + ex.message);
            end
        end

        function updateTableModelInformation(this)
            % Coalesce updates of table model information
            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "updateTableModelInformation");
            matlab.internal.datatoolsservices.EventCoalescer.throttleDebounce('updateTableModelInformation', @this.sendTableModelInformationDebounced, 'scope', this.DS_UUID, 'throttleDuration', 2, 'debouceDuration', 1);
        end
        
        function updateRowModelInformation(this, startRow, endRow, fullRows)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
            end

            [startRow, endRow, ~, ~] = this.getAdjustedRange(...
                startRow, endRow, -1, -1);

            affectsViewport = true;
            affectMoreThanViewport = false;
            if this.havePageSet
                [affectsViewport, affectMoreThanViewport] = this.rangeAffectsViewport(startRow, endRow, this.ViewportStartColumn, this.ViewportEndColumn);
            end

            this.executeInBackgroundIfPossible(fcn=@sendRowMetaData,...
                numOutputArgs=0,...
                criteria=((affectsViewport && ~affectMoreThanViewport) || rowRangeInLimit(startRow, endRow)),...
                inputArgs={this, startRow, endRow, fullRows});
        end
        
        function sendRowMetaData(this, startRow, endRow, fullRows)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
            end

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "sendRowMetaData(" + startRow + "," + endRow + ")");


            rmpca = cell(1,endRow-startRow+1);
            for row=startRow:endRow
                rowMetaData = this.MetaDataStore.getTabularRowMetaData(row);
                % TODO: Only if metadata is available, add RowNumber field to the JSON.                
                rowMetaData.RowNumber = row;
                rmpca{row-startRow+1} = jsonencode(rowMetaData);                
            end
            rowModelProps = '[';
            if ~isempty(rmpca) && ~any(cellfun(@(x)isempty(x), rmpca))
                rowModelProps = [rowModelProps strjoin(rmpca,',')];
            end
            rowModelProps = [rowModelProps ']'];
            this.messageserviceDispatchToClient(struct(...
                    'eventType', this.SRV_MSG_META_ROW_CHANGED, ...
                    'metaDataType', 'RowModelProperties', ...
                    'source', 'server', ...
                    'startRow', startRow-1, ...
                    'endRow', endRow-1, ...
                    'fullStartRow', min(fullRows)-1, ...
                    'fullEndRow', max(fullRows)-1, ...
                    'properties', rowModelProps));
        end

        function sendColumnModelInformationThrottled(this,...
                startColumn,...
                endColumn, ...
                fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startColumn
                endColumn
                fullColumns
            end

            try
                if ~isvalid(this)
                    return;
                end

                [~, ~, startColumn, endColumn] = this.getAdjustedRange(...
                    -1, -1, startColumn, endColumn);

                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "sendColumnModelInformationThrottled(" + startColumn + "," + endColumn + ")");

                affectsViewport = true;
                affectMoreThanViewport = false;
                if this.havePageSet
                    [affectsViewport, affectMoreThanViewport] = this.rangeAffectsViewport(this.ViewportStartRow, this.ViewportEndRow, startColumn, endColumn);
                end

                this.executeInBackgroundIfPossible(fcn=@sendColumnMetaData,...
                    numOutputArgs=0,...
                    criteria=((affectsViewport && ~affectMoreThanViewport) || columnRangeInLimit(startColumn, endColumn)),...
                    inputArgs={this, startColumn, endColumn, fullColumns});
            catch ex
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "Error in sendColumnModelInformationThrottled");
            end
        end

        function sendColumnModelInformationDebounce(this, debounceQueue)
            % Start column and end column should be the same for all events
            startColumn = debounceQueue{1}{1};
            endColumn = debounceQueue{1}{2};

            % Find the largest overlapping full-columns range
            c = cellfun(@(v)v{3}, debounceQueue, 'UniformOutput', false);
            c = [c{:}];
            fullColumns = min(c):max(c);

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "sendColumnModelInformationDebounce(" + startColumn + "," + endColumn + ")");

            this.sendColumnModelInformationThrottled(startColumn, endColumn, fullColumns);
        end

        % Update column model information (i.e., send updated metadata to the frontend).
        % The message sent within this function is throttled and debounced; if you must instantly send information over,
        % use "sendColumnMetaData()" instead.
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


            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "updateColumnModelInformation(" + startColumn + "," + endColumn + ")");

            eventName = "updateColumnModelInformation(" + startColumn + "," + endColumn + ")";

            matlab.internal.datatoolsservices.EventCoalescer.throttleDebounce(eventName, @this.sendColumnModelInformationThrottled, ...
                'scope', this.DS_UUID, 'throttleDuration', 2, 'debouceDuration', 1,...
                'callbackArguments', {startColumn, endColumn, fullColumns},...
                'debounceCallback', @(dq)this.sendColumnModelInformationDebounce(dq));
        end

        % Instantly update the frontend's column meta data.
        function sendColumnMetaData(this, startColumn, endColumn, fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startColumn (1,1) double {mustBeNonnegative}
                endColumn (1,1) double {mustBeNonnegative}
                fullColumns (1,:) double = startColumn:endColumn
            end

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore", "sendColumnMetaData(" + startColumn + "," + endColumn + ")");

            cmpca = cell(1,endColumn-startColumn+1);
            for column=startColumn:endColumn
                columnMetaData = this.MetaDataStore.getTabularColumnMetaData(column);
                % TODO: Only if metadata is available, add ColumnNumber field to the JSON.                
                columnMetaData.ColumnNumber = column;
                cmpca{column-startColumn+1} = jsonencode(columnMetaData);
            end
            columnModelProps = '[';
            if ~isempty(cmpca) && ~any(cellfun(@(x)isempty(x), cmpca))
                columnModelProps = [columnModelProps strjoin(cmpca,',')];
            end
            columnModelProps = [columnModelProps ']'];

            this.messageserviceDispatchToClient(struct(...
                    'eventType', this.SRV_MSG_META_COL_CHANGED, ...
                    'metaDataType', 'ColumnModelProperties', ...
                    'source', 'server', ...
                    'startColumn', startColumn-1, ...
                    'endColumn', endColumn-1, ...
                    'fullStartColumn', min(fullColumns)-1, ...
                    'fullEndColumn', max(fullColumns)-1, ...
                    'properties', columnModelProps));
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
        
        function messageserviceDispatchToClient(this, eventData)
            if (this.ClientReady)
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::messageserviceDispatchToClient::" + this.Channel, "sending now eventType: " + eventData.eventType);
                message.publish(this.Channel, eventData, internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.MESSAGE_SERVICE_INSTANCE_NAME);
            else
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::pubsubdatastore::messageserviceDispatchToClient::" + this.Channel, "buffering eventType: " + eventData.eventType);
                this.EventBufferForClient{end + 1} = eventData;
            end
        end
    end

    methods(Hidden)
        function pauseListener(this, listenerName)
            if isprop(this, listenerName)
                this.(listenerName).Enabled = false;
            end
        end

        function resumeListener(this, listenerName)
            this.(listenerName).Enabled = true;
        end
    end
end

function rs = rangeSize(startRow, endRow, startColumn, endColumn)
    rs = (endRow - startRow + 1) * (endColumn - startColumn + 1);
end

function ril = rangeInLimit(startRow, endRow, startColumn, endColumn)
    ril = rangeSize(startRow, endRow, startColumn, endColumn) <= internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.BACKGROUNDPOOL_DATA_SIZE_LIMIT;
end

function rril = rowRangeInLimit(startRow, endRow)
    rril = endRow - startRow + 1 <= internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.BACKGROUNDPOOL_ROW_SIZE_LIMIT;
end

function cril = columnRangeInLimit(startColumn, endColumn)
cril = endColumn - startColumn + 1 <= internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore.BACKGROUNDPOOL_COL_SIZE_LIMIT;
end

% LocalWords:  pubsubdatastore viewport
