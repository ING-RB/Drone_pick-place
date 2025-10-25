classdef RemoteWorkspaceBrowserManager < internal.matlab.desktop_workspacebrowser.MLWorkspaceBrowserManager & internal.matlab.variableeditor.peer.RemoteManager
    % A class defining MATLAB PeerModel Workspace Browser
    %

    % Copyright 2013-2024 The MathWorks, Inc.

    % Constructor
    methods(Access='public')
        function this = RemoteWorkspaceBrowserManager(Workspace, provider, userContext, ignoreUpdates, EnableContainerExpansion)
            arguments
                Workspace;
                provider;
                userContext;
                ignoreUpdates (1,1) logical = false;
                EnableContainerExpansion (1,1) logical = false;
            end
            this@internal.matlab.variableeditor.peer.RemoteManager(provider, ignoreUpdates, []);
            this@internal.matlab.desktop_workspacebrowser.MLWorkspaceBrowserManager(Workspace, userContext, EnableContainerExpansion);
            this.Workspace = Workspace;
            this.Provider = provider;
        end

        function handleEventFromClient(this, ~, eventData)
           if strcmp(eventData.data.type, 'InitActions')
                actionNamespace = [this.Channel 'ActionManager'];
                pathToScan = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.startPath;
                WSBActionManager = this.initActions(actionNamespace, pathToScan);
                WSBActionManager.initActions('internal.matlab.variableeditor.Actions.struct', 'internal.matlab.datatoolsservices.actiondataservice.Action');
            end
        end
    end

    methods(Access='protected')
        function initialize(this, userContext, enableContainerExpansion)
            % The workspace could be a key so fetch the actual workspace
            % object. 
            this.Workspace = this.getWorkspace(this.Workspace);
            % Depending on the enableContainerExpansion flag, create the appropriate
            % DataModel and Adapter
            if enableContainerExpansion
                % If container expansion is enabled, create a Tree DataModel and corresponding Adapter
                DataModel = internal.matlab.desktop_workspacebrowser.MLWorkspaceTreeDataModel(this.Workspace);
                Adapter = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceTreeAdapter( ...
                    DataModel.Name, DataModel.Workspace, DataModel);
            else
                % If container expansion is not enabled, create a regular DataModel and corresponding Adapter
                DataModel = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel(this.Workspace);
                Adapter = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceAdapter( ...
                    DataModel.Name, DataModel.Workspace, DataModel);
            end
            this.Documents = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceDocument( ...
                this.Provider, this, Adapter, enableContainerExpansion, UserContext = userContext);
            % (Do not set FocusedDocument on init, else 'DocumentFocusGained' will not fire on a propertySet from client)
            DataModel.Data = struct();
            
            function updateIfVars(this)
                try
                    variables = evalin(this.Workspace, 'who');
                    if ~isempty(variables)
                        this.Documents.ViewModel.DataModel.workspaceUpdated({}, internal.matlab.datatoolsservices.WorkspaceEventType.WORKSPACE_CHANGED);
                    end
                catch ex
                    internal.matlab.datatoolsservices.logDebug("RemoteWorkspaceBrowserManager", ...
                        "error on initial update: " + ex.message);
                end
            end

            execImmediately = internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle;
            if execImmediately
                updateIfVars(this);
            else
                % Defer first-time udpate of the DataModel until after the
                % WorkspaceBrowserManager is initialized.
                builtin('_dtcallback', @() updateIfVars(this));
            end

%             % Do initial population for the workspace
%             % If we don't have a Workspace-Like Object or the base
%             % workspace we need to call an asynchronous update using a
%             % WebWorker. Wait for IDLE to execute this, else
%             % createWorkspaceBrowser will create a new manager again and
%             % will update Infinitely. 
%             % TODO: Investigate to see if DataModel update can be synchronous.
%             if ischar(this.Workspace) && isequal(this.Workspace, 'base')
%                 openCmd = ['internal.matlab.desktop_workspacebrowser.WSBFactory.createWorkspaceBrowser(''' ...
%                     workspaceKey ''',''' this.Channel ''').Documents.DataModel.workspaceUpdated;'];
%                 internal.matlab.datatoolsservices.executeCmd(openCmd, true);
%             else
%             end
        end
    end

    % Public Methods
    methods(Access='public')
        function reinitialize(this, userContext, enableContainerExpansion)
            if nargin < 2
                userContext = '';
            end
            % Deletes the current Workspace Document in order to force a
            % refresh of the Workspace Peer Stack
            delete(this.Documents);
            this.initialize(userContext, enableContainerExpansion);
        end
    end
end
