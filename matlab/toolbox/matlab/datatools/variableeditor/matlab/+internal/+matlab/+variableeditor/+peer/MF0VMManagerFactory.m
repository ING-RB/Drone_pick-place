classdef MF0VMManagerFactory < handle
    % A class defining MATLAB MF0ViewModel Variable Manager
    % 

    % Copyright 2020-2021 The MathWorks, Inc.

    % Property Definitions:
    
    properties (Constant)
        % PeerModelChannel
        PeerModelChannel = '/VariableEditorManager';
    end

    properties (SetObservable=false, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false)
        PeerManager;
        Channel = internal.matlab.variableeditor.peer.MF0VMManagerFactory.PeerModelChannel;
    end
    
    % Peer Listener Properties
    properties (SetAccess='protected', Transient)
        PeerEventListener;
        PropertySetListener;
    end %properties
    
    % Constructor
    methods(Access='public')
        function this = MF0VMManagerFactory()
            provider = internal.matlab.variableeditor.peer.MF0ViewModelVEProvider(internal.matlab.variableeditor.peer.MF0VMManagerFactory.PeerModelChannel);
            this.PeerManager = internal.matlab.variableeditor.peer.RemoteManager(...
                                            provider, true);
            %Add peer event listener
            root = this.PeerManager.Provider.Root;
            this.PeerEventListener = ...
               root.addEventListener('PeerEvent', @this.handlePeerEvent);
            this.PropertySetListener = root.addEventListener('PropertySet',@this.handlePropertySet);

            this.PeerManager.setProperty('Initialized', true);

            %Send event for the factory ready
%             eventObj = struct('eventType', 'FactoryInitialized');
            %provider.dispatchEventToClient(this.PeerManager, eventObj, 'hello');
            %internal.matlab.variableeditor.peer.PeerUtils.sendPeerEvent(this.PeerManager.Provider.Root, 'FactoryInitialized');

%             this.PeerManager.dispatchEventToClient(eventObj);
        end
        
        function delete(this)
            delete(this.PeerManager);
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
                        case 'CreateManager' % Fired to start a server peer manager
                            this.logDebug('MF0VMManagerFactory','handlePeerEvent','CreateManager');
                            this.createInstance(ed.EventData.channel,ed.EventData.ignoreUpdates);
                        case 'DeleteManager' % Fired to remove a server peer manager
                            this.logDebug('MF0VMManagerFactory','handlePeerEvent','DeleteManager');
                            if this.getManagerInstances.isKey(ed.EventData.channel)
                                manager = this.createInstance(ed.EventData.channel,false);
                                delete(manager);
                            end
                    end
                catch e
                    this.PeerManager.sendErrorMessage(e.message);
                end
            end
        end
        
        function status = handlePropertySet(this, ~, ed)
            % Handles properties being set. No properties expected in Factory. 
            % Returns a status: empty string for success, an error message otherwise.
            status = '';
        end
        
        function handlePropertyDeleted(this, ~, ~)
            this.PeerManager.sendErrorMessage(getString(message(...
                'MATLAB:codetools:variableeditor:NoPropertiesShouldBeRemoved')));
        end
        
        function setProperty(this, propertyName, propertyValue)
            this.PeerManager.setProperty(propertyName, propertyValue);
        end
        
        function logDebug(this, class, method, message, varargin)
            rootNode = this.PeerManager.Provider.getRoot();
            internal.matlab.variableeditor.peer.PeerUtils.logDebug(rootNode, class, method, message, varargin{:});
        end
    end
    
    
    % Public Static Methods
    methods(Static, Access='public')
        % getInstance
        function obj = getInstance(varargin)
            obj = internal.matlab.variableeditor.peer.VEFactory.getInstance();
        end

        function obj = getRemoteInstance(forceNewInstance)
            arguments
                forceNewInstance (1,1) logical = false;
            end
            mlock; % Keep persistent variables until MATLAB exits
            persistent managerInstance;
            if isempty(managerInstance) || forceNewInstance
                managerInstance = internal.matlab.variableeditor.peer.MF0VMManagerFactory();
            end
            obj = managerInstance;
        end
        
        function obj = createManager(Channel, IgnoreUpdates, ActionManagerInfo)
            factoryInstance = internal.matlab.variableeditor.peer.MF0VMManagerFactory.getInstance();
            factoryInstance.logDebug('MF0VMManagerFactory','createManager','','channel',Channel,'IgnoreUpdate',IgnoreUpdates);
            
            if ~exist('ActionManagerInfo', 'var')
                ActionManagerInfo = [];
            end
            
            obj = internal.matlab.variableeditor.peer.MF0VMManagerFactory.createInstance(Channel, IgnoreUpdates, ActionManagerInfo);
        end

        function obj = getManagerInstances(newManagerInstances)
            mlock; % Keep persistent variables until MATLAB exits
            
            % Factory Instance
            factoryInstance = internal.matlab.variableeditor.peer.MF0VMManagerFactory.getInstance();
            
            % update the managers list on the client 
            if nargin > 0
                obj = internal.matlab.variableeditor.peer.VEFactory.getManagerInstances(newManagerInstances);
                factoryInstance.logDebug('MF0VMManagerFactory','getManagerInstances','set');
                keys = newManagerInstances.keys();
                managerJSON = ['[' sprintf('"%s",',keys{:})];
                managerJSON(end) = ']';

                factoryInstance.PeerManager.setPropertyOnClient('Managers', managerJSON);
            end
            obj = internal.matlab.variableeditor.peer.VEFactory.getManagerInstances();
        end
        
        function managerInstance = createInstance(Channel, IgnoreUpdates, ActionManagerInfo)
            if ~exist('ActionManagerInfo', 'var')
                ActionManagerInfo = [];
            end
            managerInstance = internal.matlab.variableeditor.peer.VEFactory.createManager(Channel, IgnoreUpdates, ActionManagerInfo);
        end
        
        function startup()
            % Makes sure the peer manager for the variable editor exists
            % [~]=internal.matlab.variableeditor.peer.MF0VMManagerFactory.getInstance();
            internal.matlab.variableeditor.peer.VEFactory.startup();
        end

        function obj = getFocusedManager()
            % Get the currently focused manager
            obj = internal.matlab.variableeditor.peer.MF0VMManagerFactory.getSetFocusedManager();
        end
    end
end
