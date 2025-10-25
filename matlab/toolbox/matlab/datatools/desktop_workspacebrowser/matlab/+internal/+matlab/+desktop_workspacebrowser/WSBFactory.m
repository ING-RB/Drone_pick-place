classdef WSBFactory < handle
    %  WSBFactory
    %  Factory responsible for keeping track of the existing Managers.
    %  Creates the managers and the appropriate providers to allow
    %  communication with the client

    % Copyright 2019-2023 The MathWorks, Inc.

    properties (Access='private')
        CustomWorkspaceMap
    end

    methods(Access='protected')
        function this = WSBFactory()
        end
    end

    methods(Static, Access='public')
        function obj = getInstance(varargin)
            mlock; % Keep persistent variables until MATLAB exits
            persistent factoryInstance;
            if isempty(factoryInstance)
                % startup the Communication mechanism (in the current case PeerManagerFactory)
                % which can listen for create and delete Manager events from the client. Always use getPeerInstance to get an
                % instance of the wsbfactory to avoid multiple instantiations.
                internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory.getPeerInstance();
                factoryInstance = internal.matlab.desktop_workspacebrowser.WSBFactory();
                factoryInstance.CustomWorkspaceMap = dictionary;
            end
            obj = factoryInstance;
        end

        function obj = createWorkspaceBrowser(Workspace, Channel, userContext, ignoreUpdates, enableContainerExpansion)
            arguments
                Workspace;
                Channel char;
                userContext char = '';
                ignoreUpdates (1,1) logical = false;
                enableContainerExpansion (1,1) logical = false;
            end
            mlock; % Keep persistent variables until MATLAB exits
            persistent wsbCounter;
            persistent deleteListeners;
          
            if isempty(wsbCounter)
                wsbCounter = 0;
            end
            
            origWorkspaceEmpty = false;
            if nargin<1 || isempty(Workspace)
                origWorkspaceEmpty = true;
                Workspace = 'debug';
            end            

            if nargin<2 || isempty(Channel)
                wsbCounter = wsbCounter + 1;
                Channel = ['/WSB_' num2str(wsbCounter)];
            end
            
            if nargin <3 || isempty(userContext)
                userContext = 'MOTW_Workspace';
            end

            if nargin <4 || isempty(ignoreUpdates)
                ignoreUpdates = false;
            end

%             factoryInstance = internal.matlab.desktop_workspacebrowser.WSBFactory.getInstance();
%             if ischar(Workspace)
%                 factoryInstance.logDebug('WSBFactory','createManager','','workspace',Workspace,'channel',Channel);
%             else
%                 factoryInstance.logDebug('WSBFactory','createManager','','workspace','private','channel',Channel);
%             end

            WSBInstances = internal.matlab.desktop_workspacebrowser.WSBFactory.getWorkspaceBrowserInstances();
            if isempty(deleteListeners)
                deleteListeners = containers.Map();
            end

            if ~isKey(WSBInstances, Channel)
                % Check to see if the workspace is a standard workspace or we
                % need to attempt to evaluate that workspace
                if internal.matlab.datatoolsservices.VariableUtils.isCustomCharWorkspace(Workspace)
                    factoryInstance = internal.matlab.desktop_workspacebrowser.WSBFactory.getInstance();
                    % Add this workspace key to CustomWorkspaceMap so we
                    % can delete it upon Manager deletion
                    factoryInstance.CustomWorkspaceMap(Channel) = Workspace;
                    Workspace = eval(Workspace);
                end
                provider = internal.matlab.desktop_workspacebrowser.MF0ViewModelWSBProvider(Channel);
                managerInstance = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowserManager(Workspace, provider, ...
                    userContext, ignoreUpdates, enableContainerExpansion);
                WSBInstances(Channel) = managerInstance;
                 deleteListeners(Channel) = event.listener(managerInstance,...
                     'ObjectBeingDestroyed',localCreateObjectDestroyedCallbackWSB(Channel,WSBInstances));
                
                internal.matlab.desktop_workspacebrowser.WSBFactory.getWorkspaceBrowserInstances(WSBInstances);
                
            elseif ~origWorkspaceEmpty && ~isequal(WSBInstances(Channel).Workspace, Workspace) % Check to see if the user passed a new workspace
                % Check to see if the workspace is a standard workspace or we
                % need to attempt to evaluate that workspace
                evaluatedWorkspace = false;
                if internal.matlab.datatoolsservices.VariableUtils.isCustomCharWorkspace(Workspace)
                    evaluatedWorkspace = true;
                end
                
                if ~evaluatedWorkspace || (evaluatedWorkspace && ~strcmp(class(WSBInstances(Channel).Workspace), Workspace))
                   warning(message('MATLAB:workspace:PassedInWorkspaceDoesNotMatchExistingWorkspace'));
                end
            end
            
            % Return the new manager instances
            obj = WSBInstances(Channel);

            % Send event for the manager creation
            peerFactoryInstance = internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory.getPeerInstance();
            if ~isempty(peerFactoryInstance.PeerManager)
                root = peerFactoryInstance.PeerManager.Provider.getRoot;
                data = struct('Workspace', obj.WorkspaceKey, 'Channel', Channel);
                root.dispatchEvent('WorkspaceBrowserCreated', data);
            end
        end

        function removeWorkspaceBrowser(Channel)
            wsbInstances = internal.matlab.desktop_workspacebrowser.WSBFactory.getWorkspaceBrowserInstances();
            if isKey(wsbInstances, Channel)
                wsbMgr = wsbInstances(Channel);          
                factoryInstance = internal.matlab.desktop_workspacebrowser.WSBFactory.getInstance();
                if isConfigured(factoryInstance.CustomWorkspaceMap) && isKey(factoryInstance.CustomWorkspaceMap, Channel)
                    delete(wsbMgr.Workspace); % This is a custom workspace that was created upon Manager creation, delete workpsace when Manager is deleted
                    factoryInstance.CustomWorkspaceMap = factoryInstance.CustomWorkspaceMap.remove(Channel);
                end
                wsbInstances.remove(Channel);
            end
        end

        % deletes the manager with the given channel
        % Channel: channel of the manager to be deleted
        % serverOriginated: true if the delete is initiated on the server
        function deleteManager(Channel, serverOriginated)
            wsbInstances = internal.matlab.desktop_workspacebrowser.WSBFactory.getWorkspaceBrowserInstances();
            if isKey(wsbInstances, Channel)
                wsbMgr = wsbInstances(Channel);
                internal.matlab.desktop_workspacebrowser.WSBFactory.removeWorkspaceBrowser(Channel);
                delete(wsbMgr);
            end
            if serverOriginated
                clientServerCommunicationHandler = internal.matlab.variableeditor.peer.VEFactory.getClientServerCommunicationHandler();
                eventObj = struct();
                eventObj.('type') = 'DeleteWSBManager';
                eventObj.('channel') = Channel;
                clientServerCommunicationHandler.dispatchEventToClient(eventObj);
            end
        end

        function obj = getWorkspaceBrowserInstances(newWSBInstances)
            mlock; % Keep persistent variables until MATLAB exits
            persistent WSBInstances;
            
            % Factory Instance
            factoryInstance = internal.matlab.desktop_workspacebrowser.WSBFactory.getInstance();

            if nargin > 0
                WSBInstances = newWSBInstances;
%                 factoryInstance.logDebug('WSBFactory','getWorkspaceBrowserInstances','set');
                keys = WSBInstances.keys();
                managerJSON = ['[' sprintf('"%s",',keys{:})];
                managerJSON(end) = ']';
                
                peerFactoryInstance = internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory.getPeerInstance();
                if ~isempty(peerFactoryInstance.PeerManager)
                    peerFactoryInstance.PeerManager.setProperty('Managers', managerJSON);
                end
            elseif isempty(WSBInstances)
%                 factoryInstance.logDebug('WSBFactory','getWorkspaceBrowserInstances','initial creation');
                WSBInstances = containers.Map();
            else
%                 factoryInstance.logDebug('WSBFactory','getWorkspaceBrowserInstances','get');
            end
            
            obj = WSBInstances;
        end
        
        % This method returns a Workspace Manager given a workspaceKey
        % corresponding to the Manager;
        function ws = getManagerByWorkspace(workspaceKey)
            arguments
                workspaceKey = "";
            end
            ws = [];
            if isempty(workspaceKey)
                return;
            end
            wsbs = internal.matlab.desktop_workspacebrowser.WSBFactory.getWorkspaceBrowserInstances;
            for channel = keys(wsbs)
                mgr = wsbs(channel{1});
                if strcmp(mgr.WorkspaceKey, workspaceKey)
                    ws = mgr;
                    return;
                end
            end
        end

        function startup()
            % Makes sure the peer manager for the variable editor exists
            [~]=internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory.getInstance();
        end

        function logDebug(this, class, method, message, varargin)
        end
    end
end

function clb = localCreateObjectDestroyedCallbackWSB(Channel,~)
clb =  @(~,~) (internal.matlab.desktop_workspacebrowser.WSBFactory.removeWorkspaceBrowser(Channel));
end
