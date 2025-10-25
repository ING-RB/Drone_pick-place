classdef MobileVariableEditor < handle
    %MOBILEVARIABLEEDITOR Starts up the backend for the MATLAB Mobile
    % Variable Editor Service
    % For details see https://confluence.mathworks.com/x/aVPrKg

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (Constant,Hidden)
        ServerChannel (1,1) string = "/MobileVE/ServerMsg";
        ClientChannel (1,1) string = "/MobileVE/ClientMsg";
        ViewInteractionNotifyChannel (1,1) string = "/VE/interaction"; % Also defined in ViewEventEnums.js

        Workspace char = 'debug';
        UserContext char = 'UIVariableEditor';
        ActionManagerNamespace = '/MatlabMobileVEActionMgr';
        DataEditInteractionMessage (1,1) string = "DataEditInteraction";
        DataActionMessage (1,1) string = "DataAction";
        VariableEditorStartedMessage (1,1) string = "VariableEditorStarted";


        % Pub sub for openvar/closevar/closeAllVariables
        ClientOpenvarRequestMessage (1,1) string = "OpenVariable";
        ClientClosevarRequestMessage (1,1) string =  "CloseVariable";
        ClientCloseAllVarsRequestMessage (1,1) string =  "CloseAllVariables";

        OpenvarResponseMessage (1,1) string = "OpenVariableResponse";
        ClosevarResponseMessage (1,1) string =  "CloseVariableResponse";
        CloseAllVarsResponseMessage (1,1) string =  "CloseAllVariablesResponse";

        % Pub sub for view interactions
        CellFocusChangeMessage (1,1) string = "CellFocus";
        DoubleClickOnCellMessage (1,1) string = "DoubleClick";

        ErrorMessage (1,1) string = "InternalError";
        SuccessMessage (1,1) string = "Success";

        DisabledPlugins cell = {'CLEAN_CATEGORIES', 'COLUMN_FILTER', 'DATA_TYPE_CONVERSION', 'SEARCHABLE'}
    end

    properties(Access={?internal.matlab.desktop_variableeditor.MobileVariableEditor, ?matlab.mock.TestCase})
        ClientRequestListener
        ViewInteractionListener
        PublishCallback % Used for testing purposes
        Manager
    end

    properties(Access=?matlab.mock.TestCase)
        DataInteractionListenerList
        DataEditListenerList
    end

    methods (Access={?internal.matlab.desktop_variableeditor.MobileVariableEditor, ?matlab.mock.TestCase})
        function this = MobileVariableEditor()
            % Constructor internal only
            VEFactory = internal.matlab.variableeditor.peer.VEFactory.getInstance;
            this.Manager = VEFactory.createManager('/UIVariableEditor', false);
            this.DataInteractionListenerList = dictionary(string.empty, event.listener.empty);
            this.DataEditListenerList = dictionary(string.empty, event.listener.empty);

            this.setupClientListeners;
            this.initActionDataService();
        end

        function setupClientListeners(this)
            % Adds message service subscription for client requests
            this.ClientRequestListener = message.subscribe(this.ClientChannel, @(e) this.handleClientRequest(e), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.ViewInteractionListener = message.subscribe(this.ViewInteractionNotifyChannel, @(e) this.handleViewInteraction(e), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);

        end

        function initActionDataService(this)
            actionNamespace = this.ActionManagerNamespace;
            pathToScan = internal.matlab.desktop_variableeditor.DesktopVariableEditor.startPath;
            this.Manager.initActions(actionNamespace, pathToScan, 'internal.matlab.datatoolsservices.actiondataservice.Action', true);
        end

        function handleClientRequest(this, event)
            % Martial's client request and calls appropriate method

            internal.matlab.datatoolsservices.logDebug("mobileVE", "handleClientEvent");
            if ~isempty(event)
                try
                    requestID = "";
                    if isfield(event, 'requestID')
                        requestID = event.requestID;
                    end
                    internal.matlab.datatoolsservices.logDebug("mobileVE", sprintf("\thandleClientEvent(" + event.type + ")"));
                    switch(event.type)
                        case this.ClientOpenvarRequestMessage
                            this.openvar(event.variableName, requestID);
                        case this.ClientClosevarRequestMessage
                            this.closeVar(event.variableName, requestID);
                        case this.ClientCloseAllVarsRequestMessage
                            this.closeAllVariables(requestID);
                        otherwise
                            errorMsg = "Unknown type: " + event.type;
                            internal.matlab.datatoolsservices.logDebug("mobileVE", errorMsg);
                            msgData = struct;
                            msgData.type = this.ErrorMessage;
                            msgData.message = errorMsg;
                            msgData.requestID = requestID;
                            this.publishMessage(msgData);
                    end
                catch e
                    errorMsg = "Unknown Error: " + e.message;
                    internal.matlab.datatoolsservices.logDebug("mobileVE", errorMsg);

                    msgData = struct;
                    msgData.type = this.ErrorMessage;
                    msgData.message = errorMsg;
                    msgData.requestID = requestID;

                    this.publishMessage(msgData);
                end
            end
        end

        function handleViewInteraction(this, event)
            if ~isempty(event)
                internal.matlab.datatoolsservices.logDebug("mobileVE", sprintf("\t handleViewInteraction(" + event.type + ")"));
                switch(event.type)
                    case this.CellFocusChangeMessage
                        % Mgr could have multiple documents, fetch the
                        % curent document for which displayData is fetched.
                        idx = arrayfun(@(x) isequal(x.Name, event.parentName), this.Manager.Documents);
                        doc = this.Manager.Documents(idx);
                        if isfield(event, 'row') && isfield(event, 'column')
                            row = event.row + 1;
                            column = event.column + 1;
                            % If this is a struct document, call
                            % displayData with inPlace flag true, this will
                            % return single cell value (1-based)
                            if isa(doc.ViewModel, 'internal.matlab.variableeditor.ArrayViewModel')
                               doc.ViewModel.FormatAsSingleCell = true; 
                            end
                            event.cellValue = doc.ViewModel.getDisplayData(row, row, column, column);
                        end
                        this.publishMessage(event);
                    case this.DoubleClickOnCellMessage
                        this.publishMessage(event);
                end
            end
        end

        function publishMessage(this, msgData)
            % Generic publish method, adds logging, and and callback used
            % for testing purposes

            internal.matlab.datatoolsservices.logDebug("mobileVE::publish", jsonencode(msgData));

            message.publish(this.ServerChannel, msgData)
            if ~isempty(this.PublishCallback)
                this.PublishCallback(msgData);
            end
        end

        function openvarURL = openvar(this, varName, requestID)
            arguments
                this
                varName
                requestID (1,1) string = ""
            end
            varVal = evalin(this.Workspace, varName);
            doc = this.Manager.openvar(varName, this.Workspace, varVal, UserContext=this.UserContext);
            % Disable plugins that are not enabled for MLMobile
            doc.setProperty('DisabledPlugins', this.DisabledPlugins);
            % TODO: Update listeners on variableChanged
            % Add UserDataInteraction listener
            if ismember('UserDataInteraction', events(doc.ViewModel))
                this.DataInteractionListenerList(varName) = addlistener(doc.ViewModel, 'UserDataInteraction', @(es,ed) this.handleUserDataInteraction(varName, ed));
            end
            % Add DataEdit listener
            if ismember('DataEditFromClient', events(doc.ViewModel))
                this.DataEditListenerList(varName) = addlistener(doc.ViewModel, 'DataEditFromClient', @(es,ed) this.handleDataEdit(varName, ed));
            end

            ve_webview_baseurl = "toolbox/matlab/datatools/variableeditor/js/peer/VariableEditorPopoutHandler.html";
            openvarURL = sprintf('%s?channel=%s&docId=%s&summaryBarVisible=on&notifyOnCellFocus=on',ve_webview_baseurl,urlencode(this.Manager.Channel),urlencode(doc.DocID));
            msgData = struct;
            msgData.variableName = varName;
            msgData.webURL = openvarURL;
            msgData.type = this.OpenvarResponseMessage;
            msgData.requestID = requestID;
            this.publishMessage(msgData);
        end

        function handleUserDataInteraction(this, varName, ed)
            msgData = struct;
            msgData.variableName = varName;
            msgData.type = this.DataActionMessage;
            msgData.codeToBeExecuted = ed.Code;
            this.publishMessage(msgData);
        end

        function handleDataEdit(this, varName, ed)
            msgData = struct;
            msgData.variableName = varName;
            msgData.type = this.DataEditInteractionMessage;
            msgData.codeToBeExecuted = ed.Code;
            this.publishMessage(msgData);
        end


        function closeVar(this, varName, requestID)
            arguments
                this
                varName
                requestID (1,1) string = ""
            end
            this.Manager.closevar(varName);
            this.deleteListenerHandle('DataInteractionListenerList', varName);
            this.deleteListenerHandle('DataEditListenerList', varName);

            % Send CloseVariable Success Message
            msgData = struct;
            msgData.variableName = varName;
            msgData.type = this.ClosevarResponseMessage;
            msgData.status = this.SuccessMessage;
            msgData.requestID = requestID;
            this.publishMessage(msgData);
        end

        function closeAllVariables(this, requestID)
            arguments
                this
                requestID (1,1) string = ""
            end
            if ~isempty(this.Manager) && isvalid(this.Manager)
                this.Manager.closeAllVariables();
            end
            varNames = keys(this.DataInteractionListenerList);
            for i=1:length(varNames)
                varName = varNames(i);
                this.deleteListenerHandle('DataInteractionListenerList', varName);
                this.deleteListenerHandle('DataEditListenerList', varName);
            end
            % Send CloseAllVariables Success Message
            msgData = struct;
            msgData.variableName = varNames;
            msgData.type = this.CloseAllVarsResponseMessage;
            msgData.status = this.SuccessMessage;
            msgData.requestID = requestID;
            this.publishMessage(msgData);
        end

        function deleteListenerHandle(this, listenerListName, keyName)
             if isKey(this.(listenerListName), keyName)
                lh = this.(listenerListName)(keyName);
                delete(lh);
                this.(listenerListName)(keyName) = [];
             end
        end

        function delete(this)
            % Destructor
            if ~isempty(this.ClientRequestListener)
                message.unsubscribe(this.ClientChannel, @(e) this.handleClientRequest(e));
                this.ClientRequestListener = [];
            end
            if ~isempty(this.ViewInteractionListener)
                message.unsubscribe(this.ViewInteractionNotifyChannel, @(e) this.handleViewInteraction(e));
                this.ViewInteractionListener = [];
            end
            this.closeAllVariables();
        end
    end

    methods(Access=public, Static)
        function ve = getInstance()
            % Fetches the static instance of the MobileWorkspaceBrowser

            mlock;
            persistent veInstance;

            % Should be allowed to recreate MobileVariableEditor if it did
            % not previously exist or was previously deleted
            if isempty(veInstance) || ~isvalid(veInstance)
                veInstance = internal.matlab.desktop_variableeditor.MobileVariableEditor;
            end
            ve = veInstance;
        end

        function startup()
            % Starts up the MobileVariableEditor Instance if not already started
            veInstance = internal.matlab.desktop_variableeditor.MobileVariableEditor.getInstance;

            % Send VariableEditorStarted message whenever getInstance is called.
            msgData = struct;
            msgData.type = veInstance.VariableEditorStartedMessage;
            veInstance.publishMessage(msgData);
        end
    end
end
