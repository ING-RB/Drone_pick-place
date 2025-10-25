classdef (Abstract) ActionInterface < handle
    % Base class for MCOS toolstrip components.
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    %% -----------  User-invisible properties --------------------
    properties (GetAccess = protected, SetAccess = protected)
        % Peer Node
        Peer = []
        % Source
        PropertySetSource
        % Channel
        ModelChannel = ''
    end

    properties (Abstract, Access = protected)
        % Peer Node
        Type
    end
    
    properties (Access = protected)
        % Listeners for view events
        PeerEventListener
        PropertySetListener
    end
    
    methods (Access = public)
        % Create action peer node and attach it to the action root.
        function createPeer(this, props_struct)
            type = this.Type;
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannelForAS(this.ModelChannel)
                if strcmp(type,'Action')
                    manager = matlab.ui.internal.toolstrip.base.ActionService.get(this.ModelChannel);
                    parent_node = manager.getRoot();
                else
                    error('Non actions should use the Peer Interface');
                end

                this.Peer = parent_node.addChild(type, props_struct);
                this.PropertySetListener = addlistener(this.Peer, 'propertySet', @(event, data) PropertySetCallback(this, event, data));
                this.PeerEventListener = addlistener(this.Peer, 'peerEvent', @(event, data) PeerEventCallback(this, event, data));
            else
                
                if strcmp(type,'Action')
                    manager = com.mathworks.peermodel.PeerModelManagers.getInstance(this.ModelChannel);
                    parent_node = manager.getRoot();
                else
                    manager = com.mathworks.peermodel.PeerModelManagers.getInstance(this.ModelChannel);
                    parent_node = manager.getByType('OrphanRoot').get(0);
                end
                % prepare property value pairs
                props_hash = matlab.ui.internal.toolstrip.base.Utility.convertFromStructureToHashmap(props_struct);
                % create peer node and put it into orphan tree
                this.Peer = parent_node.addChild(type, props_hash);
                % add listeneer to peer node event coming from client node
                this.PropertySetListener = addlistener(this.Peer, 'propertySet', @(event, data) PropertySetCallback(this, event, data));
                this.PeerEventListener = addlistener(this.Peer, 'peerEvent', @(event, data) PeerEventCallback(this, event, data));
                % set source is MCOS
                this.PropertySetSource = java.util.HashMap();
                this.PropertySetSource.put('source','MCOS');
            end
        end
        
        % Destroy peer node and all its children
        function destroyPeer(this)
            if ~isempty(this.Peer)
                if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                    if isvalid(this.Peer)
                        this.Peer.delete();
                    end
                else
                    this.Peer.destroy();
                end
            end
        end
        
        % Move peer node
        function moveToTarget(this,target,varargin)
            if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                manager = matlab.ui.internal.toolstrip.base.ActionService.get(this.ModelChannel);
            else
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(this.ModelChannel);
            end
            
            if ischar(target)
                % no op for Toolstrip target
                switch target
                    case 'PopupList'
                        this.moveTo(manager, this.Peer, 'PopupRoot');
                    case 'GalleryPopup'
                        this.moveTo(manager, this.Peer, 'GalleryPopupRoot');
                    case 'GalleryFavoriteCategory'
                        this.moveTo(manager, this.Peer, 'GalleryPopupRoot');
                    case 'QuickAccessBar'
                        this.moveTo(manager, this.Peer, 'QABRoot');
                    case 'Toolstrip'
                        this.moveTo(manager, this.Peer, 'ToolstripRoot');
                    case 'TabGroup'
                        this.moveTo(manager, this.Peer, 'TabGroupRoot');
                    case 'QuickAccessGroup'
                        this.moveTo(manager, this.Peer, 'QAGroupRoot');
                end
            else
                if nargin == 2
                    current_parent = this.Peer.getParent();
                    if current_parent~=target.Peer
                        % move only when necessary
                        manager.move(this.Peer,target.Peer);
                    end
                else
                    if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                        manager.move(this.Peer,target.Peer,varargin{1});
                    else
                        manager.move(this.Peer,target.Peer,varargin{1}-1);
                    end
                end
            end
        end
        
        % Move peer node
        function moveToOrphanRoot(this)
            if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                manager = matlab.ui.internal.toolstrip.base.ActionService.get(this.ModelChannel);
                manager.move(this.Peer,manager.getByType('OrphanRoot'));
            else
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(this.ModelChannel);
                manager.move(this.Peer,manager.getByType('OrphanRoot').get(0));
            end
            %%
        end
        
        % Get peer node property
        function matlab_value = getPeerProperty(this, property)
            if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                matlab_value = this.Peer.getProperty(property);
            else
                java_value = this.Peer.getProperty(property);
                matlab_value = matlab.ui.internal.toolstrip.base.Utility.convertFromJavaToMatlab(java_value);
            end
        end
        
        % Set peer node property
        function setPeerProperty(this, property, matlab_value)
            % skip when the peer node does not exist
            if ~isempty(this.Peer)
                if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                        % we can do an isvalid() check on ViewModel node, but
                        % not for PeerModel node
                        if isvalid(this.Peer)
                            this.Peer.setProperty(property, matlab_value);
                        end
                else
                        % convert value into java format
                        java_value = matlab.ui.internal.toolstrip.base.Utility.convertFromMatlabToJava(matlab_value);
                        % set peer node property
                        this.Peer.setProperty(property, java_value, this.PropertySetSource);
                end
            end
        end
        
        % Dispatch peer event from server to client
        function dispatchEvent(this, structure)
            if ~isempty(this.Peer)
                if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                        % we can do an isvalid() check on ViewModel node, but
                        % not for PeerModel node
                        if isvalid(this.Peer)
                            this.Peer.dispatchEvent('peerEvent', structure);
                        end
                else
                        hashmap = matlab.ui.internal.toolstrip.base.Utility.convertFromStructureToHashmap(structure);
                        if ~isempty(this.Peer)
                            this.Peer.dispatchEvent('peerEvent',this.Peer,hashmap);
                        end
                end
            end
        end
        
        function PropertySetCallback(this,src,data)
            % no op
        end
        
        function PeerEventCallback(this,src,data)
            % no op
        end
        
        function value = hasPeerNode(this)
            value = ~isempty(this.Peer);
        end
        
        function value = getModelChannel(this)
            value = this.ModelChannel;
        end
        
    end
    methods (Access = private)
        function moveTo(this, manager, peer, target)
            if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(peer)
                manager.move(this.Peer, manager.getByType(target));
            else
                manager.move(this.Peer, manager.getByType(target).get(0));
            end
        end
    end
end

