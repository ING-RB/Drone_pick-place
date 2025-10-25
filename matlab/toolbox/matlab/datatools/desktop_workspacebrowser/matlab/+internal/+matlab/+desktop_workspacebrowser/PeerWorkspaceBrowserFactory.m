classdef PeerWorkspaceBrowserFactory < handle
    % A class defining MATLAB PeerModel Workspace Browser Factory
    % 

    % Copyright 2013-2014 The MathWorks, Inc.

    % Property Definitions:

    properties (Constant)
        % PeerModelChannel
        PeerModelChannel = '/WorkspaceBrowserManager';

        % Force New Instance
        % Used to force creation of a new instance for testing purposes
        ForceNewInstance = 'force_new_instance';
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
        function this = PeerWorkspaceBrowserFactory()
            provider = internal.matlab.desktop_workspacebrowser.PeerModelWSBProvider(internal.matlab.desktop_workspacebrowser.PeerModelWSBProvider.PeerModelChannel);
            this.PeerManager = internal.matlab.variableeditor.peer.RemoteManager(...
                                            provider, true);
            %Add peer event listener
            this.PeerEventListener = ...
               event.listener(this.PeerManager.Provider.PeerModelServer.getRoot, ...
               'PeerEvent',@this.handlePeerEvent);
            this.PropertySetListener = event.listener(this.PeerManager.Provider.PeerModelServer.getRoot,'PropertySet',@this.handlePropertySet);

            this.PeerManager.setProperty('Initialized', true);

            %Send event for the factory ready
            eventObj = struct('eventType', 'FactoryInitialized');
            internal.matlab.variableeditor.peer.PeerUtils.sendPeerEvent(this.PeerManager.Provider.getRoot(), 'FactoryInitialized');

%             this.PeerManager.dispatchEventToClient(eventObj);
        end
        
    end
    
    % Public methods
    methods
        % Handles all peer events from the client
        function handlePeerEvent(this, ~, ed)
            if isfield(ed.EventData,'source') && strcmp('server',ed.EventData.source)
                return;
            end
            if isfield(ed.EventData,'type')
                try
                    switch ed.EventData.type
                        case 'CreateWorkspaceBrowser' % Fired to start a server peer manager
                            this.logDebug('PeerWorkspaceBrowserFactory','handlePeerEvent','CreateWorkspaceBrowser');
                            this.createWorkspaceBrowser(ed.EventData.workspace, ed.EventData.channel);
                        case 'DeleteWorkspaceBrowser' % Fired to start a server peer manager
                            this.logDebug('PeerWorkspaceBrowserFactory','handlePeerEvent','DeleteWorkspaceBrowser');
                            % Get the manager instance and delete it
                            factoryInstance = internal.matlab.desktop_workspacebrowser.WSBFactory.getInstance();
                            wsbManagerInstances = factoryInstance.getWorkspaceBrowserInstances;
                            if wsbManagerInstances.isKey(ed.EventData.channel)                                
                                manager = this.createWorkspaceBrowser(ed.EventData.workspace, ed.EventData.channel);
                                delete(manager);
                            end
                    end
                catch e
                    this.PeerManager.sendErrorMessage(e.message);
                end
            end
        end
        
        function status = handlePropertySet(~, ~, ed)
            % Handles properties being set.  ed is the Event Data, and it
            % is expected that ed.EventData.key contains the property which
            % is being set.  Returns a status: empty string for success,
            % an error message otherwise.
            status = '';
            
            if ~isa(ed.EventData.newValue, 'java.util.HashMap')
                return;
            end
            
            if ed.EventData.newValue.containsKey('Source') && strcmp('server',ed.EventData.newValue.get('Source'))
                return;
            end

        end
        
        function handlePropertyDeleted(this, ~, ~)
            this.PeerManager.sendErrorMessage(getString(message(...
                'MATLAB:codetools:variableeditor:NoPropertiesShouldBeRemoved')));
        end
        
        function logDebug(this, class, method, message, varargin)
            rootNode = this.PeerManager.getRoot();
            internal.matlab.legacyvariableeditor.peer.PeerUtils.logDebug(rootNode, class, method, message, varargin{:});
        end
    end
    
    % Public Static Methods
    methods(Static, Access='public')
        % getInstance
        function obj = getInstance(varargin)
            obj = internal.matlab.desktop_workspacebrowser.WSBFactory.getInstance();
        end
        
        function obj = createWorkspaceBrowser(Workspace, Channel)
            fac = internal.matlab.desktop_workspacebrowser.WSBFactory.getInstance();
            obj = fac.createWorkspaceBrowser(Workspace, Channel);
        end
        
        % getInstance
        function obj = getPeerInstance(varargin)
            mlock; % Keep persistent variables until MATLAB exits
            persistent managerInstance;
            if isempty(managerInstance) || (nargin>0 && strcmpi(varargin{1},internal.matlab.workspace.peer.PeerManager.ForceNewInstance))
                managerInstance = internal.matlab.desktop_workspacebrowser.PeerWorkspaceBrowserFactory();
            end
            obj = managerInstance;
        end
    end
end


