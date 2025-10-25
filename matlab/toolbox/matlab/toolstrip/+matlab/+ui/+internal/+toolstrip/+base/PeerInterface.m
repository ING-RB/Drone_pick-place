classdef (Abstract) PeerInterface < handle
    % Base class for MCOS toolstrip components.
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    %% -----------  User-invisible properties --------------------
    properties (GetAccess = protected, SetAccess = protected)
        % Peer Node
        Peer = []
        % Source
        PropertySetSource
        % 
        PeerModelChannel = ''
        Manager
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
    
    methods (Access = protected)
        
        % Create toolstrip peer node and attach it to the orphan root.
        % Create action peer node and attach it to the action root.  We
        % always create a peer node at the orphan root because of Swing
        % support.  otherwise, we have to add "childadded" listener to
        % every node
        function createPeer(this, props_struct)
            type = this.Type;
            if strcmp(type,'Action')
                error('Actions should use the Action Interface');
            else
                if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannel(this.PeerModelChannel)
                    manager = matlab.ui.internal.toolstrip.base.ToolstripService.get(this.PeerModelChannel);
                    parent_node = manager.getByType('OrphanRoot');
                    this.Manager = manager;
                else
                    manager = com.mathworks.peermodel.PeerModelManagers.getInstance(this.PeerModelChannel);
                    parent_node = manager.getByType('OrphanRoot').get(0);
                end
            end
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannel(this.PeerModelChannel)
                % create peer node and put it into orphan tree
                this.Peer = parent_node.addChild(type, props_struct);
                % add listeneer to peer node event coming from client node
                this.Peer.addEventListener('propertySet', @(event, data) PropertySetCallback(this, event, data));
                this.Peer.addEventListener('peerEvent', @(event, data) PeerEventCallback(this, event, data));
            else
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

        function attachToPeer(this, peerId)
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannel(this.PeerModelChannel)
                manager = matlab.ui.internal.toolstrip.base.ToolstripService.get(this.PeerModelChannel);
            else
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(this.PeerModelChannel);
                % set source is MCOS
                this.PropertySetSource = java.util.HashMap();
                this.PropertySetSource.put('source','MCOS');
            end
            % create peer node and put it into orphan tree
            this.Peer = manager.getById(peerId);
            % add listener to peer node event coming from client node
            this.PropertySetListener = addlistener(this.Peer, 'propertySet', @(event, data) PropertySetCallback(this, event, data));
            this.PeerEventListener = addlistener(this.Peer, 'peerEvent', @(event, data) PeerEventCallback(this, event, data));
        end
        
        % Destroy peer node and all its children
        function destroyPeer(this)
            if ~isempty(this.Peer)                
                if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                    % we can do an isvalid() check on ViewModel node, but
                    % not for PeerModel node
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
            %%
            if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                manager = this.Manager;
            else
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(this.PeerModelChannel);
            end
            if ischar(target)
                % no op for Toolstrip target
                if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                    %                     This works because the array only returns one element
                    switch target
                        case 'PopupList'
                            manager.move(this.Peer, manager.getByType('PopupRoot'));
                        case 'GalleryPopup'
                            manager.move(this.Peer, manager.getByType('GalleryPopupRoot'));
                        case 'GalleryFavoriteCategory'
                            manager.move(this.Peer, manager.getByType('GalleryFavoriteCategoryRoot'));
                        case 'QuickAccessBar'
                            manager.move(this.Peer, manager.getByType('QABRoot'));
                        case 'Toolstrip'
                            manager.move(this.Peer, manager.getByType('ToolstripRoot'));
                        case 'TabGroup'
                            manager.move(this.Peer, manager.getByType('TabGroupRoot'));
                        case 'QuickAccessGroup'
                            manager.move(this.Peer, manager.getByType('QAGroupRoot'));
                    end
                else
                    switch target
                        case 'PopupList'
                            manager.move(this.Peer, manager.getByType('PopupRoot').get(0));
                        case 'GalleryPopup'
                            manager.move(this.Peer, manager.getByType('GalleryPopupRoot').get(0));
                        case 'GalleryFavoriteCategory'
                            manager.move(this.Peer, manager.getByType('GalleryFavoriteCategoryRoot').get(0));
                        case 'QuickAccessBar'
                            manager.move(this.Peer, manager.getByType('QABRoot').get(0));
                        case 'Toolstrip'
                            manager.move(this.Peer, manager.getByType('ToolstripRoot').get(0));
                        case 'TabGroup'
                            manager.move(this.Peer, manager.getByType('TabGroupRoot').get(0));
                        case 'QuickAccessGroup'
                            manager.move(this.Peer, manager.getByType('QAGroupRoot').get(0));
                    end
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
                        if varargin{1} <= 0
                            error(message('MATLAB:toolstrip:general:invalidAddIndex'));
                        end
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
                %%
                manager = this.Manager;
                % target is already a peer node
                manager.move(this.Peer,manager.getByType('OrphanRoot'));
                
            else
                %%
                manager = com.mathworks.peermodel.PeerModelManagers.getInstance(this.PeerModelChannel);
                % target is already a peer node
                manager.move(this.Peer,manager.getByType('OrphanRoot').get(0));
            end
        end
        
        % Get peer node property
        function matlab_value = getPeerProperty(this, property)
            java_value = this.Peer.getProperty(property);
            matlab_value = matlab.ui.internal.toolstrip.base.Utility.convertFromJavaToMatlab(java_value);
        end
        
        % Set peer node property
        function setPeerProperty(this, property, matlab_value)            
            % skip when the peer model or view model node does not exist
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
            % skip when the peer model or view model node does not exist
            if ~isempty(this.Peer)
                if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                    % we can do an isvalid() check on ViewModel node, but
                    % not for PeerModel node
                    if isvalid(this.Peer)
                        this.Peer.dispatchEvent('peerEvent', structure);
                    end
                else
                    hashmap = matlab.ui.internal.toolstrip.base.Utility.convertFromStructureToHashmap(structure);
                    this.Peer.dispatchEvent('peerEvent',this.Peer,hashmap);
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
        
        function value = getPeerModelChannel(this)
            value = this.PeerModelChannel;
        end
        
    end
    
end

