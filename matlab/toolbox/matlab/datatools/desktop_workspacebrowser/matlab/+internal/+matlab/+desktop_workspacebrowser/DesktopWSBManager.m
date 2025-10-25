classdef DesktopWSBManager < internal.matlab.variableeditor.MLManager

    % Manager class for the Desktop Workspace Browser

    % Copyright 2024-2025 The MathWorks, Inc.

    properties(Constant)
        DesktopWSBMessageServiceChannel (1,1) string = "/WorkspaceBrowser";
        DesktopWSBMessageServiceInstanceName (1,1) string = "WorkspaceBrowser";

        DesktopWSBDataStoreMessageServiceChannel (1,1) string = "/DesktopWSB";

        MessageServiceInstance = message.internal.MessageService(internal.matlab.desktop_workspacebrowser.DesktopWSBManager.DesktopWSBMessageServiceInstanceName);
    end

    properties(Access={?matlab.unittest.TestCase, ?internal.matlab.desktop_workspacebrowser.DesktopWSBManager})
        ClientMessageListener;
        DSClientMessageListener;
        SelectionChangeListener;
        ActionsInitialized (1,1) logical = false;

        PreviousSelectedRows = [];
        PreviousSelectedColumns = [];

        PreviousGridSize = [];

        % These are used when dropping variables from the MAT file preview into the WSB
        VarsToLoad string = string.empty;
        FileToLoadFrom string = string.empty;
    end

    properties
        ActionManager
        ContextMenuProvider
        Channel = internal.matlab.desktop_workspacebrowser.DesktopWSBManager.DesktopWSBMessageServiceChannel;
    end

    methods
        function this = DesktopWSBManager(setupServices)
            arguments
                setupServices (1,1) logical = true;
            end

            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager", "Constructor");
            this.Documents = internal.matlab.desktop_workspacebrowser.DesktopWSBDocument(this);
            this.FocusedDocument = this.Documents(1);
            this.FocusedDocument.ViewModel.dispatchEventToClient = @this.viewDispatchToClient;

            if setupServices
                this.setupListeners();
                this.startServices();
            end
        end

        function varargout = openvar(this, varargin)
            varargout{1} = this.Documents(1);
        end

        % closevar
        function varargout = closevar(~,~)
            varargout = {};
        end

        % getVariableAdapter arguments are: this, name, workspace, varClass, varSize, data
        % But are all unused for the Desktop WSB.
        function veVar = getVariableAdapter(~, ~, ~, ~, ~, ~)
            veVar = {};
        end

        function destroy(this)
            if ~isempty(this.ClientMessageListener)
                internal.matlab.desktop_workspacebrowser.DesktopWSBManager.MessageServiceInstance.unsubscribe(this.ClientMessageListener);
                this.ClientMessageListener = [];
            end
            if ~isempty(this.DSClientMessageListener)
                internal.matlab.desktop_workspacebrowser.DesktopWSBManager.MessageServiceInstance.unsubscribe(this.DSClientMessageListener);
                this.DSClientMessageListener = [];
            end
        end

        % getProperty arguments are: this, prop
        % But both are all unused for the Desktop WSB.
        function val = getProperty(~, ~)
            val = [];
        end

        function reinitialize(this, varargin)
            this.startServices();
        end
    end

    methods (Access={?matlab.unittest.TestCase, ?internal.matlab.desktop_workspacebrowser.DesktopWSBManager})
        function initActions(this)
            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::initActions", "");
            if ~this.ActionsInitialized
                actionNameSpace = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.ActionManagerNamespace;
                peerProvider = internal.matlab.datatoolsservices.actiondataservice.remote.MF0VMActionDataServiceProvider(actionNameSpace);
                veADS = internal.matlab.variableeditor.VEActionDataService(peerProvider, this);
                actionMgr = internal.matlab.datatoolsservices.actiondataservice.ActionManager(this, peerProvider, veADS);

                % builtin('_dtcallback', @() this.callInitActionOnIdle(actionNamespace, startPath, classType, actionMgr), ...
                %     internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle);

                this.ActionManager = actionMgr;

                classType = 'internal.matlab.datatoolsservices.actiondataservice.Action';
                if ~isempty(this.ActionManager) && isvalid(this.ActionManager)
                    startPath = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.startPath;
                    this.ActionManager.initActions(startPath, classType);
                    % TODO: have a base location for actions which are common
                    % between WSB and variableeditor
                    this.ActionManager.initActions('internal.matlab.variableeditor.Actions.struct', 'internal.matlab.datatoolsservices.actiondataservice.Action');
                    % this.setProperty('ActionsInitialized', actionNameSpace);
                end

                % Make sure headers state update
                 headerAction = actionMgr.ActionDataService.getAction('HeaderAction');
                 headerAction.Action.UpdateActionState();
            end

            this.ActionsInitialized = true;
        end

        function initMenu(this)
            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::initMenu", "");
            contextNamespace = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.ContextMenuManagerNamespace;
            xmlPath = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getContextMenuActionsFile();

            contextMenuManager = internal.matlab.datatoolsservices.contextmenuservice.ContextMenuManager.getInstance();
            this.ContextMenuProvider = contextMenuManager.createMenuProvider(xmlPath, contextNamespace, ...
                struct('channel', contextNamespace, ...
                'queryString', internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.queryString));

            % this.setProperty('ContextMenuServiceNameSpace', contextNamespace);
        end

        function setupListeners(this)
            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::setupListeners", "");
            this.ClientMessageListener = internal.matlab.desktop_workspacebrowser.DesktopWSBManager.MessageServiceInstance.subscribe( ...
                internal.matlab.desktop_workspacebrowser.DesktopWSBManager.DesktopWSBMessageServiceChannel, ...
                @this.handleEventFromClient, ...
                'enableDebugger', ...
                ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.DSClientMessageListener = internal.matlab.desktop_workspacebrowser.DesktopWSBManager.MessageServiceInstance.subscribe( ...
                internal.matlab.desktop_workspacebrowser.DesktopWSBManager.DesktopWSBDataStoreMessageServiceChannel, ...
                @this.handleDSEvent, ...
                'enableDebugger', ...
                ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);

            this.SelectionChangeListener = addlistener(this.Documents(1).ViewModel, 'SelectionChanged', @this.handleServerSelectionChanged);
        end

        function startServices(this)
            this.initActions;
            this.initMenu;
            this.sendClientMessage("servicesStarted");
        end

        function handleDSEvent(this, eventData)
            if ~isempty(eventData)
                if isfield(eventData, "type")
                    if strcmp(eventData.type, "StartupServices")
                        % This should only happen on a refresh scenario
                        internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleDSEvent", "StartupServices");
                        if ~this.ActionsInitialized
                            this.startServices();
                        else
                            this.sendClientMessage("servicesStarted");
                        end
                    elseif strcmp(eventData.type, "PauseWorkspaceListeners")
                        this.handlePauseWorkspaceListeners();
                    elseif strcmp(eventData.type,"EnableWorkspaceListeners")
                        this.handleEnableWorkspaceListeners();
                    else
                        internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleDSEvent", "Unhandled event: " + eventData.type);
                    end
                else
                    internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleDSEvent", "Error: No type field!");
                end
            else
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleDSEvent", "Error: No event data!");
            end
        end

        function handlePauseWorkspaceListeners(this)
            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handlePauseWorkspaceListeners", "");
            this.PreviousSelectedRows = this.Documents(1).ViewModel.SelectedRowIntervals;
            this.PreviousSelectedColumns = this.Documents(1).ViewModel.SelectedColumnIntervals;
            this.clearSelection();
        end

        function handleEnableWorkspaceListeners(this)
            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleEnableWorkspaceListeners", "");
            if isscalar(this.PreviousSelectedRows)
                % PreviousSelectedRows is expected to be a start/end pair,
                % adjust it if needed
                this.PreviousSelectedRows = [this.PreviousSelectedRows, this.PreviousSelectedRows];
            end
            this.Documents(1).ViewModel.setSelection(this.PreviousSelectedRows, this.PreviousSelectedColumns);
            this.PreviousSelectedRows = [];
            this.PreviousSelectedColumns = [];
        end

        function handleEventFromClient(this, eventData)
            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleEventFromClient", "");
            if strcmp(eventData.type, "SelectedVariablesChanged")
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleEventFromClient", "SelectedVariablesChanged");
                selectedVars = eventData.Variables;
                this.Documents(1).ViewModel.SelectedFields = selectedVars;
                if isempty(selectedVars)
                    sel = this.Documents(1).ViewModel.getSelection();
                    if ~isempty(sel{1})
                        % If the row selection was already empty, then there's nothing to do.
                        % Otherwise set the selection with an endRow of 0.
                        this.clearSelection();
                    end
                end
            elseif strcmp(eventData.type, "SelectedRowsChanged")
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleEventFromClient", "SelectedRowsChanged");
                rowRanges = eventData.selectedRows;
                if isempty(rowRanges)
                    sel = this.Documents(1).ViewModel.getSelection();
                    if ~isempty(sel{1})
                        % If the row selection was already empty, then there's nothing to do.
                        % Otherwise set the selection with an endRow of 0.
                        this.clearSelection();
                    end
                else
                    rows = [];
                    for i=1:length(rowRanges)
                        range = rowRanges(i);
                        if range.start ~= -1 && range.end ~= -1
                            rows = [rows; [range.start+1, range.end+1]]; %#ok<*AGROW>
                            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleEventFromClient", "SelectedRowsChanged rows: [" + (range.start+1) + ", " + (range.end+1) + "]");
                        else
                            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleEventFromClient", "SelectedRowsChanged empty range rows: [" + (range.start+1) + ", " + (range.end+1) + "]");
                        end
                    end
                    if ~isempty(rows)
                        this.Documents(1).ViewModel.setSelection(rows, [1,1]);
                        this.scrollViewOnClient(rowRanges(1).start, 0); % Zero-based
                    end
                end
            elseif strcmp(eventData.type, "VariableRenamed")
                oldName = eventData.oldName;
                newName = eventData.newName;
                this.clearSelection();
                this.Documents(1).ViewModel.SelectedFields = {newName};

                internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleEventFromClient", "VariableRenamed From: " + oldName + " to: " + newName);
            elseif strcmp(eventData.type, "propertySet")
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleEventFromClient", "propertySet property: " + eventData.propertyName);
                switch (eventData.propertyName)
                    case "Selection"
                        try
                            selection = eventData.propertyValue;
                            selectedRows = jsondecode(selection.selectedRows);
                            sr = [];
                            for i=1:length(selectedRows)
                                sr = [sr;[selectedRows(i).start + 1, selectedRows(i).end + 1]];
                            end
                            selectedColumns = jsondecode(selection.selectedColumns);
                            sc = [0 0];
                            if ~isempty(selectedColumns)
                                sc = [selectedColumns(1).start + 1, selectedColumns(1).end + 1];
                            end
                            if ~isempty(this.SelectionChangeListener)
                                % Don't fire back client-side events
                                this.SelectionChangeListener.Enabled = false;
                            end
                            this.Documents(1).ViewModel.setSelection(sr, sc);
                            if ~isempty(this.SelectionChangeListener)
                                this.SelectionChangeListener.Enabled = true;
                            end
                        catch ME
                            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleEventFromClient", "Errors setting selection: " + ME.message);
                        end
                    case "GridSize"
                        % Actions only update when a selection change
                        % happens, if the WSB was empty then data appears
                        % no selection is made so actions need to be
                        % updated here for this one use case
                        newGridSize = eventData.propertyValue;
                        wasEmptyWSB = isempty(this.Documents(1).ViewModel.SelectedRowIntervals) && ...
                                (isempty(this.PreviousGridSize) || (this.PreviousGridSize(1) == -1) || (newGridSize(1) == -1));
                        if wasEmptyWSB
                            this.updateActionStates();
                        end
                        this.PreviousGridSize = newGridSize;
                end
            elseif strcmp(eventData.type, "ColumnReordered")
                origIndex = eventData.sourceIndex;
                targetIndex = eventData.targetIndex;

                internal.matlab.desktop_workspacebrowser.DesktopWSBManager.moveColumn(origIndex, targetIndex);
            elseif strcmp(eventData.type, "drop")
                % Called when a variable is dragged from the WSB preview in the current folder
                % browser, and dropped in the desktop WSB.  The event data is:
                %     data: "x"
            	%     type: "drop"
            	%     workspace: "workspace_2"

                this.VarsToLoad = string.empty;
                this.FileToLoadFrom = string.empty;
                if isfield(eventData, "filename") && ~isempty(eventData.filename)
					% If the event contains the filename, just load from it directly
                    this.loadVarsFromFile(eventData);
                else
                    % Otherwise, fetch the right incoming workspace and load from it
                    factory = internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory.getInstance();
                    mgr = factory.getManagerByWorkspace(eventData.workspace);

                    if ~isempty(mgr) && isvalid(mgr)
                        internal.matlab.desktop_workspacebrowser.DesktopWSBManager.handleDrop(eventData, mgr);
                    else
                        internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::dropEvent", "Workspace manager " + eventData.workspace + " not found");
                    end
                end
            elseif strcmp(eventData.type, "refresh") || strcmp(eventData.type, "editCell")
                % no-op, this is a MATLAB based action so there's nothing
                % to do from the client
            else
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleEventFromClient", "Unhandled Message: " + eventData.type);
            end
        end

        function updateActionStates(this)
            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::updateActionStates", "");
            if (this.ActionsInitialized)
                actions = this.ActionManager.ActionDataService.getAllActions();
                for i=1:length(actions)
                    actions(i).UpdateActionState();
                end
            end
        end

        function messageData = handleServerSelectionChanged(this, ~, eventData)
            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::handleServerSelectionChanged", "");

            messageData = struct("selectionSource", "server");
            messageData.sourceNode = "view";
            if ~isempty(eventData.Selection)
                rows = eventData.Selection{1};
                cols = eventData.Selection{2};
                if ~isempty(rows)
                    sr = rows(1,:);
                    if isscalar(sr)
                        % this is just a single row, use it for start and
                        % end, and disregard any others in the selection
                        messageData.selectedRows = struct("start", sr-1, "end", sr-1);
                    else
                        messageData.selectedRows = struct("start", sr(1)-1, "end", sr(2)-1);
                        for i=2:height(rows)
                            sr = rows(i,:);
                            messageData.selectedRows(end+1) = struct("start", sr(1)-1, "end", sr(2)-1);
                        end
                    end
                else
                    messageData.selectedRows = struct("start", -1, "end", -1);
                end
                if ~isempty(cols)
                    messageData.selectedColumns = struct("start", cols(1)-1, "end", cols(2)-1);
                else
                    messageData.selectedColumns = struct("start", -1, "end", -1);
                end
            end
            this.sendClientMessage("Selection", messageData);
        end

        function sendClientMessage(this, type, msgData)
            arguments
                this %#ok<INUSA>
                type (1,1) string
                msgData (1,1) struct = struct
            end

            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::sendClientMessage", "type: " + type);

            msgData.type = type;
            msgData.source = "server";
            msgData.sourceType = "mcode";
            %internal.matlab.desktop_workspacebrowser.DesktopWSBManager.MessageServiceInstance.publish(internal.matlab.desktop_workspacebrowser.DesktopWSBManager.DesktopWSBMessageServiceChannel, msgData);
            message.publish(internal.matlab.desktop_workspacebrowser.DesktopWSBManager.DesktopWSBMessageServiceChannel, msgData);
        end

        function viewDispatchToClient(this, msgData)
            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::viewDispatchToClient", "");
            msgData.sourceNode = "view";
            this.sendClientMessage(msgData.type, msgData);
        end

        function scrollViewOnClient(this, row, column)
            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::scrollViewOnClient", "row: " + row + "  column: " + column);
            eventData = struct('row', row+1, 'column', column+1, "type", "scrollClient");
            this.viewDispatchToClient(eventData);
        end

        function clearSelection(this)
            this.Documents(1).ViewModel.setSelection([1,0], [1,1]);
        end

        function loadVarsFromFile(this, eventData)
            this.FileToLoadFrom = eventData.filename;

            % eventData.data is a comma separated list of variables
            this.VarsToLoad = strsplit(string(eventData.data),",");
            this.loadVariables();
        end

        function loadVariables(this)
            currVars = evalin("debug", "who");
            tempStructName = genvarname('tmp', [currVars' cellstr(this.VarsToLoad)]);

            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::dropEvent", "Loading " + strjoin(this.VarsToLoad, ","));
            try
                evalin("debug", internal.matlab.desktop_workspacebrowser.DesktopWSBManager.getLoadCmd( ...
                    tempStructName, this.FileToLoadFrom, this.VarsToLoad));
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::dropEvent", "load complete");
            catch e
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::dropEvent", "load failed");
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::dropEvent", e.message);
            end
        end

        function handleDialogResponse(this, dlgResponse)
            if strcmp(dlgResponse.src, this.DesktopWSBDataStoreMessageServiceChannel)
                if (dlgResponse.response == 1)
                    this.loadVariables();
                elseif (dlgResponse.response == 2)
                    return;
                end
            end
        end

    end

    methods (Static)
        function eventData = refresh(supressImmediateUpdate)
            arguments
                supressImmediateUpdate (1,1) logical = false;
            end

            variables = evalin("debug", "string(who)");

            internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::refresh", "JSD");
            eventData = struct("type", "refresh", ...
                "variables", variables, ...
                "count", length(variables), ...
                "immediateUpdate", ~supressImmediateUpdate);
            message.publish(internal.matlab.desktop_workspacebrowser.DesktopWSBManager.DesktopWSBMessageServiceChannel, eventData);
        end

        function moveColumn(origIndex, targetIndex)
                s = settings;
                columnsShown = s.matlab.desktop.workspace.columns.ColumnsShown.ActiveValue;
                columnOrder = s.matlab.desktop.workspace.columns.ColumnOrder.ActiveValue;

                % Need to sort the visible columns by the current column
                % order to get the correct string values
                [~,ind] = ismember(columnOrder, columnsShown);
                columnsShown = columnOrder(ind~=0);

                % Offset the indices to the columnOrder values
                origIndex = find(strcmp(columnsShown(origIndex), columnOrder));
                targetIndex = find(strcmp(columnsShown(targetIndex), columnOrder));


                % Move the columns
                v = columnOrder(origIndex);
                columnOrder(origIndex) = [];
                columnOrder = [columnOrder(1:targetIndex-1) v columnOrder(targetIndex:end)];


                % Assign it back to settings
                s.matlab.desktop.workspace.columns.ColumnOrder.PersonalValue = columnOrder;
        end

        function handleDrop(eventData, mgr)
            % Called when a variable is dropped from the MAT file preview
            % window into the Workspace Browser.  The eventData is expected to be a struct like:
            %     data: "x,y"
            %     type: "drop"
            %     workspace: "workspace_2"

            if ~isempty(mgr.Workspace) && isvalid(mgr.Workspace)
                % Found Workspace
                fromWorkspace = mgr.Workspace;
                toWorkspace = "debug";

                % eventData.data is a comma separated list of variables
                variables = strsplit(string(eventData.data),",");
                currVars = evalin("debug", "who");
                tempStructName = genvarname('tmp', [currVars' cellstr(variables)]);

                for i=1:length(variables)
                    varName = variables(i);
                    internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::dropEvent", "Loading " + varName);
                    try
                        varValue = evalin(fromWorkspace, varName);
                        if isa(fromWorkspace, 'matlab.internal.datatools.matlabintegration.cfb.MATFileWorkspace')
                            evalin(toWorkspace, internal.matlab.desktop_workspacebrowser.DesktopWSBManager.getLoadCmd( ...
                                tempStructName, fromWorkspace.MatFileName, varName));
                        else
                            assignin(toWorkspace, varName, varValue);
                        end
                        internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::dropEvent", "load complete");
                    catch e
                        internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::dropEvent", "load failed");
                        internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::dropEvent", e.message);
                    end
                end
            else
                % Workspace not found
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::DesktopWSBManager::dropEvent", "Workspace " + eventData.workspace + " not found");
            end
        end

    end

    methods(Static, Hidden)
        function loadCmd = getLoadCmd(tempStructName, filename, varNames)
            arguments
                tempStructName string
                filename string
                varNames string
            end

            % To be consistent with double-click or load behavior we will
            % overwrite the variable in the workspace, but it might be a
            % nice enhancement to prompt the user in the future

            if isscalar(varNames)
                loadCmd = sprintf("%s = load(""%s"", ""%s""); %s = %s.%s; clear %s;", ...
                    tempStructName, filename, varNames, varNames, tempStructName, varNames, tempStructName);
            else
                % Call load only once, and assign each of the variables
                % being loaded from the loaded struct
                loadCmd = sprintf("%s = load(""%s"", ""%s""); ", ...
                    tempStructName, filename, strjoin(varNames, ""","""));
                for idx = 1:length(varNames)
                    loadCmd = loadCmd + varNames(idx) + " = " + tempStructName + "." + varNames(idx) + "; ";
                end
                loadCmd = loadCmd + "clear " + tempStructName;
            end
        end
    end
end
