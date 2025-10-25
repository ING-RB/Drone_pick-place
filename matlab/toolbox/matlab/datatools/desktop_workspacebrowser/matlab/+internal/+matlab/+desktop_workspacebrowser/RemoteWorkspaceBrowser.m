classdef RemoteWorkspaceBrowser < handle
    % A class defining Server side implementation for RemoteWorkspaceBrowser
    % Integration.

    % Copyright 2013-2025 The MathWorks, Inc.

    % Property Definitions:

    properties (Constant, Hidden)
        % PeerModelChannel
        PeerModelChannel = '/WorkspaceBrowser';
        ActionManagerNamespace = '/WSBActionManager';
        startPath = 'internal.matlab.workspace.actions';
        ContextMenuManagerNamespace = '/WSBContextMenuManager';
        queryString = '.DesktopWorkspaceBrowser';
        UserContext = 'MOTW_Workspace';

        % WSB Pub/Sub Events
        PUBSUB_EVENT_CHANNEL = '/DesktopWSB';
        SHOW_WORKSPACE_EVENT = 'ShowWorkspaceBrowser';
        HIDE_WORKSPACE_EVENT = 'HideWorkspaceBrowser';
        ENABLE_WORKSPACE_LISTENERS = 'EnableWorkspaceListeners';
        PAUSE_WORKSPACE_LISTENERS = 'PauseWorkspaceListeners';
        STARTUP_SERVICES = 'StartupServices';
        MSG_WSB_STARTUP = 'WSBStartup';
    end

    properties (SetAccess = 'protected')
        WSBActionManager;
        ContextMenuProvider;
        Manager;
    end

    % WorkspaceDocument
    properties (SetAccess='private', Dependent=true)
        WorkspaceDocument;
    end
    methods
        function storedValue = get.WorkspaceDocument(this)
            storedValue = this.Manager.Documents(1);
        end
    end

    properties (SetAccess = 'public')
        EnableContainerExpansion;
    end

    properties (Access=private)
        PropertyChangedListener = [];
        PubSubListener;
        DropListener;
    end

    properties
        UseMLWSBModel (1,1) logical = false;
    end

    properties(Dependent = true)
        WorkspaceListenerEnabled;
    end
    methods
        function val = get.WorkspaceListenerEnabled(this)
            val = ~this.Manager.Documents.IgnoreUpdates;
        end

        function set.WorkspaceListenerEnabled(this, val)
            this.Manager.Documents.IgnoreUpdates = ~val;
            this.Manager.Documents.DataModel.IgnoreUpdates = ~val;
            % If workspace is being shown, update the datamodel to refresh the view.
            if (val)
                this.Manager.Documents.DataModel.workspaceUpdated();
            end
        end
    end

    % Constructor
    methods(Access='protected')
        function this = RemoteWorkspaceBrowser(useMLWSBModel)
            arguments
                useMLWSBModel (1,1) logical = false;
            end
            % MLWorkspaceBrowser also calls initialize on WSB
            this.PubSubListener = message.subscribe(internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.PUBSUB_EVENT_CHANNEL, @(ed)this.handlePublishFromClient(ed, useMLWSBModel), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);

            this.UseMLWSBModel = useMLWSBModel;
            this.initialize();
        end

        % Listen to any PropertyChanged events from the WorkspaceView
        function initListeners (this)
            workspaceDoc = this.Manager.Documents(1);
            workspaceView = workspaceDoc.ViewModel;
            this.PropertyChangedListener = event.listener(workspaceView,'PropertyChange',@(es,ed) this.handleViewPropertyChange(es,ed));

            % Add Drop listener
            this.DropListener = addlistener(workspaceDoc, 'DropEvent', @(es,ed) this.handleDrop(ed));
        end

        function initServices(this)
            this.initListeners();
            try
                if isempty(this.WSBActionManager)
                    this.initWSBActions();
                end
                if isempty(this.ContextMenuProvider)
                    this.initWSBContextMenu();
                end
            catch
                internal.matlab.datatoolsservices.logDebug("RemoteWorkspaceBrowser","Error during initServices");
            end
            % Set FocusedDocument once Workspacebrowser is initialized
            % This is needed by actions to update state, set once
            % action data service is initialized
            this.Manager.FocusedDocument = this.Manager.Documents(1);
        end

        % Starts up the Workspacebrowser's ActionDataService using
        % ActionManager that instantiates all the Actions. Every
        % workspacebrowser Action inherits from the 'VEAction' class.
        function initWSBActions(this)
            actionNamespace = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.ActionManagerNamespace;
            pathToScan = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.startPath;
            this.WSBActionManager = this.Manager.initActions(actionNamespace, pathToScan);
            % TODO: have a base location for actions which are common
            % between WSB and variableeditor
            this.WSBActionManager.initActions('internal.matlab.variableeditor.Actions.struct', 'internal.matlab.datatoolsservices.actiondataservice.Action');
        end

        % Starts up the Workspacebrowser's ContextMenuManager Service by passing in
        % Workspacebrowser's ContextNamespace, ActionNamespace, queryString
        % used as a selector on client side and path of the XML file containing the Contextmenu options.
        function initWSBContextMenu(this)
            contextNamespace = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.ContextMenuManagerNamespace;
            % For now, the contextmenus are only for the dataScrollerNode
            % and not for the entire PeerDocument.
            pathToXMLFile = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getContextMenuActionsFile();
            this.ContextMenuProvider = this.Manager.initContextMenu(this.queryString, pathToXMLFile, contextNamespace);
        end

        % On Variable Rename on the workspaceBrowser View in MATLAB, check
        % for any open variables in the Variable Editor and if they exist,
        % update the document name.
        function handleViewPropertyChange(~, ~, ed)
            % Check if variable is opened in desktop_ve and update the
            % document
            if strcmp(ed.Properties, 'VariableRenamed')
                desktop_ve = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance;
                desktop_ve.renamevar(ed.Values.OldValue, ed.Values.NewValue)
            end
        end

        function handleDrop(this, eventData)
            % Property callback to get notified on drop of a
            % variable

            % Fetch the right incoming workspace to return as a
            % part of the eventData;
            factory = internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory.getInstance();
            mgr = factory.getManagerByWorkspace(eventData.Workspace);

            if ~isempty(mgr) && isvalid(mgr) && isvalid(mgr.Workspace)
                % Found Workspace
                variables = strsplit(string(eventData.DropData),",");
                fromWorkspace = mgr.Workspace;
                toWorkspace = this.WorkspaceDocument.Workspace;
                for i=1:length(variables)
                    varName = variables(i);
                    internal.matlab.datatoolsservices.logDebug("workspacebrowser::dropEvent", "Copying " + varName);
                    try
                        varValue = evalin(fromWorkspace, varName);
                        if isa(fromWorkspace, 'matlab.internal.datatools.matlabintegration.cfb.MATFileWorkspace')
                            currToVars = evalin(toWorkspace, 'who');
                            tempStructName = genvarname('tmp', currToVars);
                            % To be consistent with double-click or load
                            % behavior we will overwrite the variable in
                            % the workspace, but it might be a nice
                            % enhancement to prompt the user in the future
                            newVarName = varName;
                            loadCmd = sprintf("%s = load('%s', '%s'); %s = %s.%s; clear %s;", tempStructName, fromWorkspace.MatFileName, varName, newVarName, tempStructName, varName, tempStructName);
                            evalin(toWorkspace, loadCmd);
                        else
                            assignin(toWorkspace, varName, varValue);
                        end
                        internal.matlab.datatoolsservices.logDebug("workspacebrowser::dropEvent", "     copy complete");
                    catch e
                        internal.matlab.datatoolsservices.logDebug("workspacebrowser::dropEvent", "     copy failed");
                        internal.matlab.datatoolsservices.logDebug("workspacebrowser::dropEvent", e.message);
                    end
                end
            else
                % Workspace not found
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::dropEvent", "Workspace " + eventData.Workspace + " not found");
            end
        end
    end

    methods(Access='protected')
        function initialize(this)
            namespace = this.PeerModelChannel;
            context = this.UserContext;
            % Init MOTWWorkspace context to restore settings in view
            internal.matlab.variableeditor.ArrayViewModel.useSettingForContext(context, true)
            s = settings;
            this.EnableContainerExpansion = s.matlab.desktop.workspace.EnableContainerExpansion.ActiveValue;

            if this.UseMLWSBModel
                this.Manager = internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory.createWorkspaceBrowser('debug', namespace, context, false, this.EnableContainerExpansion);
            else
                this.Manager = internal.matlab.desktop_workspacebrowser.DesktopWSBManager;
            end

            % Force an initial update from the base workspace g1044049
%             this.Manager.Documents(1).DataModel.Workspace = 'base';
%             this.Manager.Documents(1).DataModel.workspaceUpdated();
%             this.Manager.Documents(1).DataModel.Workspace = 'debug';
        end
    end

    % Public Static Methods
    methods(Static, Access='public')
        function initComplete = initIfVariables()
            % Startup the Workspace Browser backend if there are variables in the workspace
            w = evalin("debug", "who");
            initComplete = false;

            if ~isempty(w)
                internal.matlab.datatoolsservices.logDebug("RemoteWorkspaceBrowser", "initIfVariables, variables found")
                internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance();
                initComplete = true;
            else
                internal.matlab.datatoolsservices.logDebug("RemoteWorkspaceBrowser", "initIfVariables, variables not found")
            end
        end

        % getInstance
        function obj = getInstance(resetSelection, useMLWSBModel)
            arguments
                % When true, resets the selection in the WSB.  Does not create an instance
                % if one is not already created.
                resetSelection (1,1) logical = false;

                useMLWSBModel (1,1) logical = false;
            end

            internal.matlab.datatoolsservices.logDebug("RemoteWorkspaceBrowser", "getInstance, useMLWSBModel = " + useMLWSBModel);
            mlock; % Keep persistent variables until MATLAB exits

            % Gets the persistent instance of the workspace browser
            persistent managerInstance;
            persistent mLWSBManagerInstance;

            if isempty(managerInstance) && ~useMLWSBModel
                % create new manager instance backed by the CPP WSB Model
                managerInstance = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser(useMLWSBModel);
            elseif isempty(mLWSBManagerInstance) && useMLWSBModel
                % create legacy manager instance backed by the MATLAB WSB Model
                mLWSBManagerInstance = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser(useMLWSBModel);
            end

            if useMLWSBModel
                obj = mLWSBManagerInstance;
            else
                obj = managerInstance;
            end

            if resetSelection
                wbManager = obj.Manager;
                sel = wbManager.Documents.ViewModel.getSelection();

                if ~isempty(sel) && ~isempty(sel{1}) && ~isempty(sel{2})
                    internal.matlab.datatoolsservices.logDebug("workspacebrowser::getInstance", "resetting selection to empty");

                    % Clear out the server-side selection, to start fresh after browser refresh
                    wbManager.Documents.ViewModel.setSelection([0,-1], [0,1], 'server');
                end
            end
        end

        % Function to create the RemoteWorkspaceBrowser instance for the Plots Tab if a Selection has already been made in the WSB
        function obj = getInstanceWithSelection(selection, rows)
            arguments
                selection string
                rows string = strings(0);
            end
            
            internal.matlab.datatoolsservices.logDebug("RemoteWorkspaceBrowser", "getInstanceWithSelection, size = " + length(selection));
            obj = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance();
            if ~isempty(selection) && strlength(selection(1)) > 0
                wbManager = obj.Manager;
                vm = wbManager.Documents.ViewModel;

                if isempty(vm.SelectedFields)
                    % Update the SelectedFields and SelectedRowIntervals.  
                    indices = rmmissing(double(split(rows, ",")));
                    vm.SelectedRowIntervals = (indices + 1);
                    vm.SelectedFields = selection;
                end
            end
        end

        function startup(useMLWSBModel)
            arguments
                useMLWSBModel (1,1) logical = false;
            end

            % Makes sure the peer manager for the workspace browser exists
            [~]=internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance(false, useMLWSBModel);
        end

        % Handles message service events sent from the client-side
        function handlePublishFromClient(event, useMLWSBModel)
            arguments
                event

                useMLWSBModel (1,1) logical = false;
            end
            import internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser;
            if ~isempty(event) && isfield(event, 'type')
                if strcmp(event.type, RemoteWorkspaceBrowser.ENABLE_WORKSPACE_LISTENERS)
                    this = RemoteWorkspaceBrowser.getInstance(false, useMLWSBModel);
                    this.WorkspaceListenerEnabled = true;
                elseif strcmp(event.type, RemoteWorkspaceBrowser.PAUSE_WORKSPACE_LISTENERS)
                    this = RemoteWorkspaceBrowser.getInstance(false, useMLWSBModel);
                    this.WorkspaceListenerEnabled = false;
                elseif strcmp(event.type, RemoteWorkspaceBrowser.STARTUP_SERVICES)
                    this = RemoteWorkspaceBrowser.getInstance(false, useMLWSBModel);
                    this.initServices();
                elseif strcmp(event.type, RemoteWorkspaceBrowser.MSG_WSB_STARTUP)
                    % When MSG_WSB_STARTUP is received, call RemoteWorkspaceBrowser.getInstance
                    % and PlotsTabListeners.getInstance passing in true to reset the selection.
                    % This way, they both start with no WSB selection, which is what is shown
                    % in the WSB UI.
                    RemoteWorkspaceBrowser.getInstance(true, useMLWSBModel);
                    internal.matlab.plotstab.PlotsTabListeners.getInstance(false, true);
                end
            end
        end

        function refresh()
            % Legacy for current JSD WSB
            internal.matlab.datatoolsservices.WorkspaceListener.dispatchWSEventNoVarNames(internal.matlab.datatoolsservices.WorkspaceEventType.WORKSPACE_CHANGED);

            % New JSD WSB Path
            internal.matlab.desktop_workspacebrowser.DesktopWSBManager.refresh();
        end

        function WSBContextMenuActionsFile = getContextMenuActionsFile()
            import matlab.internal.capability.Capability;
            usingMATLABOnline = ~Capability.isSupported(Capability.LocalClient);

            % This file contains the WorkspaceBrowser actions. If it doesn't exist, this condition is handled and no actions are created
            if usingMATLABOnline
                % MOL has fewer shortcut keys, because some of them map to browser shortcuts
                WSBContextMenuActionsFile = fullfile(matlabroot,'toolbox','matlab','datatools','workspacebrowser','matlab','resources','WSBActionGroupingsMOL.xml');
            else
                WSBContextMenuActionsFile = fullfile(matlabroot,'toolbox','matlab','datatools','workspacebrowser','matlab','resources','WSBActionGroupings.xml');
            end
        end
    end

    % Public Methods
    methods(Access='public')
        function reinitialize(this)
            % Deletes the current Workspace Document in order to force a
            % refresh of the Workspace Peer Stack
            context = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.UserContext;
            this.Manager.reinitialize(context, this.EnableContainerExpansion);
            this.initialize();
            % On re-initialize, clear existing listener and add new
            % listener on view.
            if ~isempty(this.PubSubListener)
                message.unsubscribe(this.PubSubListener);
            end
            if ~isempty(this.PropertyChangedListener)
                delete(this.PropertyChangedListener);
                this.initListeners();
            end
        end

        function showWorkspaceBrowser(this, enableListeners)
            arguments
                this
                enableListeners (1,1) logical = true
            end

            import internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser;
            message.publish(RemoteWorkspaceBrowser.PUBSUB_EVENT_CHANNEL,...
                struct('type', RemoteWorkspaceBrowser.SHOW_WORKSPACE_EVENT));
            this.WorkspaceListenerEnabled = enableListeners;
        end

        function hideWorkspaceBrowser(this, stopListeners)
            arguments
                this
                stopListeners (1,1) logical = true
            end
            import internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser;
            message.publish(RemoteWorkspaceBrowser.PUBSUB_EVENT_CHANNEL,...
                struct('type', RemoteWorkspaceBrowser.HIDE_WORKSPACE_EVENT));
            this.WorkspaceListenerEnabled = ~stopListeners;
        end
    end
end
