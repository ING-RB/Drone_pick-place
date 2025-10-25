classdef MobileWorkspaceBrowser < handle
    %MOBILEWORKSPACEBROWSER Starts up the backend for the MATLAB Mobile
    % Workspace Browser Service
    % For details see https://confluence.mathworks.com/x/aVPrKg

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (Constant)
        ServerChannel (1,1) string = "/MobileWSB/ServerMsg";
        ClientChannel (1,1) string = "/MobileWSB/ClientMsg"

        WorkspaceBrowserStartedMessage (1,1) string = "WorkspaceBrowserStarted";
        DataChangedMessage (1,1) string = "DataChanged";
        SizeChangedMessage (1,1) string = "SizeChanged";
        ScopeChangedMessage (1,1) string = "ScopeChanged";

        DataResponseMessage (1,1) string = "Data";
        SizeResponseMessage (1,1) string = "Size";
        ColumnsResponseMessage (1,1) string = "Columns";
        ColumnSortResponseMessage (1,1) string = "ColumnSortResponse";
        ColumnVisibilityToggleResponseMessage (1,1) string = "ColumnVisibleResponse";

        ClientDataRequestMessage (1,1) string = "GetData";
        ClientSizeRequestMessage (1,1) string =  "GetSize";
        ClientSortRequestMessage (1,1) string =  "SortColumn";
        ClientGetColumnsRequestMessage (1,1) string = "GetVisibleColumns";
        ClientSetColumnsRequestMessage (1,1) string = "SetVisibleColumns";

        SuccessMessage (1,1) string = "Success";
        ErrorMessage (1,1) string = "InternalError";

        DEFAULT_AVAILABLE_COLS = ["Name", "Value", "Size", "Class", "Min", "Max", "Range", "Mean", "Median", "Mode", "Var", "Std", "Bytes"];
    end

    properties(Access={?internal.matlab.desktop_workspacebrowser.MobileWorkspaceBrowser, ?matlab.mock.TestCase})
        DataChangeListener
        ChannelListener

        PublishCallback % Used for testing perposes

        LastStack
    end

    methods (Access={?internal.matlab.desktop_workspacebrowser.MobileWorkspaceBrowser, ?matlab.mock.TestCase})
        function this = MobileWorkspaceBrowser()
            % Constructor internal only

            wsb = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, true);
            wsb.startup(true);

            this.initFieldColumns;

            this.setupViewModelListeners;
            this.setupCLientListeners;
        end

        function initFieldColumns(this)
            % Initializes all field columns for availability by Mobile WSB

            colsToInit = this.DEFAULT_AVAILABLE_COLS;
            wsb = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, true);

            view = wsb.WorkspaceDocument.ViewModel;
            for col=colsToInit
                % This check loops through all fieldCols, investigate if
                % this can be removed in the future.
                 if isempty(view.findFieldByHeaderName(col))
                    view.createFieldColumn(col);
                end
            end
        end

        function setupViewModelListeners(this)
            % Adds DataChange listener to WSB ViewModel
            wsb = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, true);
            this.DataChangeListener = event.listener(wsb.WorkspaceDocument.ViewModel, 'DataChange', @(e,d) this.handleDataChanged(e,d));
        end

        function setupCLientListeners(this)
            % Adds message service subscription for client requests

            this.ChannelListener = message.subscribe(this.ClientChannel, @(e) this.handleClientRequest(e), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
        end

        function handleDataChanged (this, ~, eventData)
            % Handler for DataChange events from View Model

            wsb = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, true);
            viewModel = wsb.WorkspaceDocument.ViewModel;

            % Check to see if the scope has changed, this needs to be done
            % asynchronously in the user's stack
            cmd = 'internal.matlab.desktop_workspacebrowser.MobileWorkspaceBrowser.updateScope;';
            internal.matlab.datatoolsservices.executeCmd(cmd);

            % Send Data Changed Message
            msgData = struct;
            msgData.type = this.DataChangedMessage;
            msgData.sizeChanged = eventData.SizeChanged;
            s = viewModel.getSize();
            msgData.rowCount = s(1);
            msgData.columnCount = s(2);

            this.publishMessage(msgData);
        end

        function checkScopeChange(this, currentStack)
            if length(currentStack) > 1
                currentStack = currentStack(1);
            end

            if isempty(this.LastStack)
                this.LastStack = struct('name', '');
            end

            if isempty(currentStack)
                currentStack = struct('name', '');
            end

            internal.matlab.datatoolsservices.logDebug("mobilewsb", "checkScopeChange(new: " + currentStack.name + ", prev: " + this.LastStack.name + ")");

            if ~strcmp(currentStack.name, this.LastStack.name)
                % Send scope changed event
                msgData = struct;
                msgData.type = this.ScopeChangedMessage;
                msgData.scope = currentStack.name;

                this.publishMessage(msgData);
            end

            % Set last stack
            this.LastStack = currentStack;
        end

        function handleClientRequest(this, event)
            % Martial's client request can calls appropriate method

            internal.matlab.datatoolsservices.logDebug("mobilewsb", "handleClientEvent");
            if ~isempty(event)
                requestID = "";
                if isfield(event, 'requestID')
                    requestID = event.requestID;
                end
                try
                    internal.matlab.datatoolsservices.logDebug("mobilewsb", sprintf("\thandleClientEvent(" + event.type + ")"));
                    switch(event.type)
                        case this.ClientDataRequestMessage
                            this.sendDataToClient(event.startRow, event.endRow, requestID);
                        case this.ClientSizeRequestMessage
                            this.sendSizeToClient(requestID);
                        case this.ClientSortRequestMessage
                            this.sortColumn(event.column, event.sortAscending, requestID);
                        case this.ClientGetColumnsRequestMessage
                            this.sendVisibleColumnsToClient(requestID);
                        case this.ClientSetColumnsRequestMessage
                            this.setVisibleColumns(event.columns, requestID);
                        otherwise
                            errorMsg = "Unknown type: " + event.type;
                            internal.matlab.datatoolsservices.logDebug("mobilewsb", errorMsg);
    
                            msgData = struct;
                            msgData.type = this.ErrorMessage;
                            msgData.message = errorMsg;
                            msgData.requestID = requestID;
    
                            this.publishMessage(msgData);
                    end
                catch e
                    errorMsg = "Unknown Error: " + e.message;
                    internal.matlab.datatoolsservices.logDebug("mobilewsb", errorMsg);
                    
                    msgData = struct;
                    msgData.type = this.ErrorMessage;
                    msgData.message = errorMsg;
                    msgData.requestID = requestID;
    
                    this.publishMessage(msgData);
                end
            end
        end

        function sendSizeToClient(this, requestID)
            arguments
                this
                requestID (1,1) string
            end
            % Sends size to client in response to GetSize request

            wsb = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, true);
            viewModel = wsb.WorkspaceDocument.ViewModel;

            msgData = struct;
            msgData.type = this.SizeResponseMessage;
            s = viewModel.getSize();
            msgData.rowCount = s(1);
            msgData.columnCount = s(2);
            msgData.requestID = requestID;
            this.publishMessage(msgData);
        end

        function sendDataToClient(this, startRow, endRow, requestID)
            % Sends data to client in response to GetData request
            arguments
                this
                startRow (1,1) double {mustBePositive}
                endRow (1,1) double {mustBePositive}
                requestID (1,1) string
            end

            msgData = struct;
            msgData.type = this.DataResponseMessage;
            [data, sr, er] = this.getDataForClient(startRow, endRow);
            msgData.startRow = sr;
            msgData.endRow = er;
            msgData.data = data;
            msgData.requestID = requestID;
            this.publishMessage(msgData);
        end

        function [data, sr, er] = getDataForClient(~, startRow, endRow)
            % Calls getRenderedData and structures output for client packet

            wsb = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, true);
            viewModel = wsb.WorkspaceDocument.ViewModel;
            size = viewModel.getSize();

            sr = min(startRow, size(1));
            er = min(endRow, size(1));

            wsb = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, true);
            rd = wsb.WorkspaceDocument.ViewModel.getRenderedData(sr, er, 1, size(2));
            % When there is no data in the workspace, return empty data and
            % set startRow and endRow to 0
            if height(rd) < 1
                data = [];
                sr = 0;
                er = 0;
                return;
            end
            for row=1:height(rd)
                s = struct("rowNum", (row-1) + sr);
                s.data = string.empty(0,size(2));
                for col=1:size(2)
                    colData = jsondecode(rd{row, col});
                    s.data(col) = colData.value;
                    if isfield(colData, "class")
                        s.class = colData.class;
                    end
                    if isfield(colData, "isMetaData")
                        s.isMetaData = colData.isMetaData;
                    end
                    if isfield(colData, "editorValue")
                        s.editorValue = colData.editorValue;
                    end
                end
                data(row) = s; %#ok<AGROW> 
            end
            % Package scalar structs as cell so that this gets serialized
            % as an array.
            if isscalar(data)
                data = {data};
            end
        end

        function sendVisibleColumnsToClient(this, requestID)
            arguments
                this
                requestID (1,1) string
            end
            % Send Visible Columns to client in response to
            % GetVisibleColumns request

            wsb = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, true);
            vc = wsb.WorkspaceDocument.ViewModel.VisibleFieldColumnList;
            k = vc.keys;

            msgData = struct;
            msgData.type = this.ColumnsResponseMessage;
            msgData.requestID = requestID;
            for col = 1:length(k)
                colData = vc(k{col});
                isSorted = wsb.WorkspaceDocument.ViewModel.SortedColumnInfo.ColumnIndex == colData.ColumnIndex;
                % Always return logical for isSorted
                if isempty(isSorted)
                    isSorted = false;
                end
                s = struct(...
                    "index", colData.ColumnIndex,...
                    "column", colData.HeaderName,...
                    "sortable", colData.Sortable,...
                    "isSorted", isSorted,...
                    "sortAscending", false...
                    );
                if isSorted
                    sortDir = wsb.WorkspaceDocument.ViewModel.SortedColumnInfo.SortOrder;
                    s.sortAscending = sortDir;
                end
                msgData.columns(col) = s;
            end

            this.publishMessage(msgData);
        end

        function setVisibleColumns(this, columns, requestID)
            arguments
                this
                columns
                requestID (1,1) string
            end
            % Sets the Visible Columns in response to the SetVisibleColumns
            % request

            wsb = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, true);
            view = wsb.WorkspaceDocument.ViewModel;

            fieldColumns = view.FieldColumnList;
            for i=keys(fieldColumns)
                fieldColumn = fieldColumns(i{:});
                % If the field column is not previously visible then set
                % ColumnVisible to true
                headerName = fieldColumn.HeaderName;
                if matches(headerName, columns)
                    if ~fieldColumn.Visible
                        view.setColumnVisible(headerName, true);
                    end
                % If the field column is already visible, but is not part
                % of 'columns' toggle Visible to false
                elseif fieldColumn.Visible
                    view.setColumnVisible(headerName, false);
                end
            end
            msgData = struct;
            msgData.type = this.ColumnVisibilityToggleResponseMessage;
            msgData.status = this.SuccessMessage;
            msgData.requestID = requestID;
            this.publishMessage(msgData);
        end

        function sortColumn(this, column, sortDirection, requestID)
            arguments
                this
                column
                sortDirection
                requestID (1,1) string
            end
            % Sorts by a column in response to a SortColumn request

            wsb = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, true);

            fieldCol = wsb.WorkspaceDocument.ViewModel.findFieldByHeaderName(column);
            wsb.WorkspaceDocument.ViewModel.SortedColumnInfo = struct("ColumnIndex", fieldCol.ColumnIndex, "SortOrder", sortDirection);

            msgData = struct;
            msgData.type = this.ColumnSortResponseMessage;
            msgData.status = this.SuccessMessage; 
            msgData.requestID = requestID;
            this.publishMessage(msgData);
        end

        function publishMessage(this, msgData)
            % Generic publish method, adds logging, and and callback used
            % for testing purposes

            internal.matlab.datatoolsservices.logDebug("mobilewsb::publish", jsonencode(msgData));

            message.publish(this.ServerChannel, msgData)

            if ~isempty(this.PublishCallback)
                try
                    this.PublishCallback(msgData);
                catch
                end
            end
        end

        function delete(this)
            % Destructor
            if ~isempty(this.DataChangeListener)
                delete(this.DataChangeListener);
                this.DataChangeListener = [];
            end
            if ~isempty(this.ChannelListener)
                message.unsubscribe(this.ClientChannel, @(e) this.handleClientRequest(e));
                this.ChannelListener = [];
            end
        end
    end

    methods(Access=public, Static)
        function wsb = getInstance()
            % Fetches the static instance of the MobileWorkspaceBrowser

            mlock;
            persistent wsbInstance;

            if isempty(wsbInstance)
                wsbInstance = internal.matlab.desktop_workspacebrowser.MobileWorkspaceBrowser;
            end

            wsb = wsbInstance;
        end

        function startup()
            % Starts up the MobileWorkspaceBrowser Instance if not already
            % started
            wsbInstance = internal.matlab.desktop_workspacebrowser.MobileWorkspaceBrowser.getInstance;

            % Send WorkspaceBrowser Started Message whenever getInstance is called.
            msgData = struct;
            msgData.type = wsbInstance.WorkspaceBrowserStartedMessage;
            wsbInstance.publishMessage(msgData);
        end
    end

    methods(Access=public, Static, Hidden)
        function updateScope()
            % Static method used to get user's scope and check if it needs
            % to be sent to client

            currentStack = evalin('debug', 'dbstack(2)');
            mwsb = internal.matlab.desktop_workspacebrowser.MobileWorkspaceBrowser.getInstance();
            mwsb.checkScopeChange(currentStack);
        end
    end
end

