
classdef MF0ViewModelWorkspaceBrowserFactory < handle
    % A class defining MATLAB PeerModel Workspace Browser Factory
    % 

    % Copyright 2020-2023 The MathWorks, Inc.

    % Property Definitions:

    properties (Constant)
        % PeerModelChannel
        PeerModelChannel = '/WorkspaceBrowserManager';
    end

    properties (SetObservable=false, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false)
        PeerManager;
        Channel; 
    end
    
    % Peer Listener Properties
    properties (SetObservable=false, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false)
        PeerEventListener;
        PropertySetListener;
    end %properties
    
    % Constructor
    methods(Access='public')
        function initRemoteFactory(this)
            provider = internal.matlab.desktop_workspacebrowser.MF0ViewModelWSBProvider(internal.matlab.desktop_workspacebrowser.MF0ViewModelWSBProvider.PeerModelChannel);
            this.PeerManager = internal.matlab.variableeditor.peer.RemoteManager(...
                                            provider, true);
                                    
            % TODO move this to the provider
            root = this.PeerManager.Provider.Root;
            this.PeerEventListener = root.addEventListener('peerEvent', @(src, evt) this.handlePeerEvent(src, evt));
            this.PropertySetListener = root.addEventListener('propertySet', @(src, evt) this.handlePropertySet(src, evt));
            
            this.PeerManager.setProperty('Initialized', true);

            %Send event for the factory ready
            eventObj = struct('eventType', 'FactoryInitialized');
            %internal.matlab.variableeditor.peer.PeerUtils.sendPeerEvent(this.PeerManager.Provider.getRoot(), 'FactoryInitialized');
            this.PeerManager.dispatchEventToClient(eventObj);
        end
    
        % Handles all peer events from the client
        function handlePeerEvent(this, src, ed)
            if ~isfield(ed, 'data')
                return;
            end
            
            if isfield(ed,'originator') && strcmp('server',ed.originator)
                return;
            end
            
            if isfield(ed.data,'type')
                try
                    switch ed.data.type
                        case 'CreateWorkspaceBrowser' % Fired to start a server peer manager
                            this.logDebug('WorkspaceBrowserFactory','handlePeerEvent','CreateWorkspaceBrowser');
                            userContext = "";
                            if isfield(ed.data, 'userContext')
                                userContext = ed.data.userContext;
                            end
                            this.createWorkspaceBrowser(ed.data.workspace, ed.data.channel, userContext);
                        case 'DeleteWorkspaceBrowser' % Fired to start a server peer manager
                            this.logDebug('WorkspaceBrowserFactory','handlePeerEvent','DeleteWorkspaceBrowser');
                            % Get the manager instance and delete it
                            factoryInstance = internal.matlab.desktop_workspacebrowser.WSBFactory.getInstance();
                            wsbManagerInstances = factoryInstance.getWorkspaceBrowserInstances;
                            if wsbManagerInstances.isKey(ed.data.channel)
                                userContext = '';
                                if isfield(ed.data, 'userContext')
                                    userContext = ed.data.userContext;
                                end
                                manager = this.createWorkspaceBrowser(ed.data.workspace, ed.data.channel, userContext);
                                delete(manager);
                            end
                    end
                catch e
                    this.sendErrorMessage(e.message);
                end
            end
        end
        
        function status = handlePropertySet(~, ~, ed)
            % Handles properties being set. Currently no properties being
            % set by the Factory
        end
        
        function handlePropertyDeleted(this, ~, ~)
            this.sendErrorMessage(getString(message(...
                'MATLAB:codetools:variableeditor:NoPropertiesShouldBeRemoved')));
        end
        
        function logDebug(this, class, method, message, varargin)
            rootNode = this.PeerManager.Provider.getRoot;
            internal.matlab.variableeditor.peer.PeerUtils.logDebug(rootNode, class, method, message, varargin{:});
        end
        
        function sendErrorMessage(this, message)
            this.PeerManager.Provider.dispatchEventToClient(this, struct('type','error','message', message,'source','server'));
        end
    end
    
    % Public Static Methods
    methods(Static, Access='public')
        % getInstance
        function obj = getInstance(varargin)
            obj = internal.matlab.desktop_workspacebrowser.WSBFactory.getInstance();
        end
        
        function obj = createWorkspaceBrowser(workspace, channel, userContext, ignoreUpdates, enableContainerExpansion)
            arguments
                workspace;
                channel char; % ViewModel does not allow strings as roottype
                userContext char = '';
                ignoreUpdates (1,1) logical = false;
                enableContainerExpansion (1,1) logical = false;
            end
            fac = internal.matlab.desktop_workspacebrowser.WSBFactory.getInstance();
            obj = fac.createWorkspaceBrowser(workspace, channel, userContext, ignoreUpdates, enableContainerExpansion);
        end
        
        % getInstance
        function obj = getPeerInstance(forceNewInstance, createRemoteFactory)
            arguments
                forceNewInstance (1,1) logical = false;
                createRemoteFactory = false;
            end
            mlock; % Keep persistent variables until MATLAB exits
            persistent managerInstance;
            if isempty(managerInstance) || forceNewInstance
                managerInstance = internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory();
                if createRemoteFactory
                    this.initRemoteFactory();   
                end
            end
            obj = managerInstance;
        end
    end
end