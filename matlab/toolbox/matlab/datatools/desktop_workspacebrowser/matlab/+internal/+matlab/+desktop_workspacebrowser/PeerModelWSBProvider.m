classdef PeerModelWSBProvider < internal.matlab.variableeditor.peer.RemoteProvider
    % PeerModelWSBProvider handles all the peer communication between
    % client and server
    % It has knowledge of the Manager, Document, View structure
    % Communicates the information received from the client to the
    % RemoteManager, RemoteDocument, RemoteView

    % Copyright 2019-2020 The MathWorks, Inc.

    % PeerModelServer
    properties (SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false)
        % PeerModelServer Property
        PeerModelServer;
    end %properties

    methods
        function storedValue = get.PeerModelServer(this)
            storedValue = this.PeerModelServer;
        end

        function set.PeerModelServer(this, newValue)
            reallyDoCopy = ~isequal(this.PeerModelServer, newValue);
            if reallyDoCopy
                this.PeerModelServer = newValue;
            end
        end
    end

    properties
        Channel;
        Root;
        Manager;
    end

    properties(Constant)
      PeerNodeTypeView = '_WorkspaceBrowserViewModel_';
      PeerNodeTypeDocument = '_WorkspaceBrowserDocument_';
      PeerModelChannel = '/WorkspaceBrowserManager';
      RootType = '/WorkspaceBrowser_Root';
    end

    properties
        DocumentMap;
        ViewMap;
    end

    % Peer Listener Properties
    properties (SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false)
        PeerEventListener;
        PropertySetListener;
    end %properties

    methods
        % Constructor
        function this = PeerModelWSBProvider(Channel)
            this.Channel = Channel;
            this.PeerModelServer = peermodel.internal.PeerModelManagers.getServerManager(Channel);
            this.PeerModelServer.SyncEnabled = true;
            this.createRoot(this.RootType);

            % Send event for the manager creation
            if (internal.matlab.variableeditor.peer.PeerUtils.isTestingOn)
              internal.matlab.variableeditor.peer.PeerUtils.sendPeerEvent(this.Root, 'ManagerCreated', 'Channel', Channel);
            end
        end

        % API called by RemoteManager, RemoteDocument and RemoteView set up listeners on their respective peer nodes
        % sourceObj: Can be manager, document or view objects
        function setUpProviderListeners(this, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteManager')
                this.Manager = sourceObj;
                peerNode = this.getRoot;
            else
                % retrieves the peer node associated with the source object (which
                % can be manager, document, view)
                peerNode = this.getPeerNode(sourceObj, id);
            end

            % Use addlistener so that listener is destroyed when the peer
            % node is destroyed
            % Add listener for documents being removed
            addlistener(peerNode, ...
                'PeerEvent',@(src, evt)handleEventFromClient(sourceObj, src, evt));

            % Setup Property Listeners
            addlistener(peerNode, ...
                'PropertySet',@(src, evt)handlePropertySetFromClient(sourceObj, src, evt));
        end

        % Handles peer events received from the client on manager,
        % document, view nodes.
        % src: can be manager, document or view nodes
        % evt: event object
        function handleEventFromClient(~, src, evt)
            if isfield(evt.EventData,'source') && strcmp('server',evt.EventData.source)
                return;
            end

            % Extracts out the information in the event object to MATLAB object
            % (struct) format and sends to the Manager
            % Provider does not care about the internals of the event
            % object
            src.handleEventFromClient(evt);
        end

        % Dispatches event to the client. This is called by the manager,
        % document or view
        % sourceObj: Can be manager, document or view
        % eventObj: event object
        % id: id of the sourceObj
        function dispatchEventToClient(this, sourceObj, eventObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteManager')
                this.dispatchEventOnManager(eventObj);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteDocument')
                this.dispatchEventOnDocument(eventObj, id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                % viewmap stores the key as a combination of 'docid+viewid' inorder to have unique ids
                % TODO: Currently viewID on the view is a counter (Ex: '__1'),
                % if this is changed to be (docId+viewId) live editor prepopulations usecase breaks.
                % Needs to be refactored as follow-up
                viewKey = [sourceObj.parentID '_' id];
                this.dispatchEventOnView(eventObj, viewKey);
            end
        end

        % Provider listens to property set events from the client
        % src: Can be manager, document or view
        % evt: event object
        function status = handlePropertySetFromClient(~, src, evt)
            status = '';
            if ~isa(evt.EventData.newValue, 'java.util.HashMap')
                return;
            end

            if evt.EventData.newValue.containsKey('Source')
                source = evt.EventData.newValue.get('Source');
                if strcmp('server',source)
                    return;
                end
            end

            % Extracts out the information in the event object to MATLAB object
            % (struct) format and sends to the Manager
            % Provider does not care about the internals of the event
            % object
            src.handlePropertySetFromClient(evt);
        end

        % Dispatches an event to set a property value on the client
        % propertyName: property whose value needs to be set
        % propertyValue: new value of the given property
        % sourceObj: object on which this property needs to be set. Can be
        % manager, document or view
        % id: id of the sourceObj
        function setPropertyOnClient(this, propertyName, propertyValue, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteManager')
                this.setManagerProperty(propertyName, propertyValue);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteDocument')
                this.setDocumentProperty(propertyName, propertyValue, id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = [sourceObj.parentID '_' id];
                this.setViewProperty(propertyName, propertyValue, viewKey);
            end
        end

        % Dispatches an event to set a propertiesObj on the client
        % propertiesObj: properties object to be set on the peernde
        % sourceObj: object on which this property needs to be set. Can be
        % manager, document or view
        % id: id of the sourceObj
        function setPropertiesOnClient(this, propertiesObj, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteManager')
                this.setManagerProperties(propertiesObj);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteDocument')
                this.setDocumentProperties(propertiesObj, id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = [sourceObj.parentID '_' id];
                this.setViewProperties(propertiesObj, viewKey);
            end
        end

        % Returns the property value of the property passed in by accessing
        % the corresponding peernode
        % propertyName: name of the property whose value is needed
        % sourceObj: object on which this property exists
        % id: id of the sourceObj
        function propVal = getProperty(this, propertyName, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteManager')
                propVal = this.getManagerProperty(propertyName);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteDocument')
                propVal = this.getDocumentProperty(propertyName, id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = [sourceObj.parentID '_' id];
                propVal = this.getViewProperty(propertyName, viewKey);
            end
        end

        % Returns all the properties by accessing
        % the corresponding peernode
        % sourceObj: object on which this property exists
        % id: id of the sourceObj
        function propVal = getProperties(this, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteManager')
                propVal = this.getManagerProperties();
            elseif isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteDocument')
                propVal = this.getDocumentProperties(id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = [sourceObj.parentID '_' id];
                propVal = this.getViewProperties(viewKey);
            end
        end

        % Called by the RemoteManager to add a document
        % docID: id of the new document
        % documentInfo: the properties that need to be set on the new
        % document's node
        function addDocument(this, docID, documentInfo)
            peerVariableNode = internal.matlab.variableeditor.peer.PeerVariableNode(this.Root,...
                internal.matlab.desktop_workspacebrowser.PeerModelWSBProvider.PeerNodeTypeDocument,...
                documentInfo);
            if isempty(this.DocumentMap)
                this.DocumentMap = containers.Map;
            end
            this.DocumentMap(docID) = peerVariableNode;
        end

        % Called by the RemoteDocument to add a new view
        % parentDocumentID: id of the RemoteDocument
        % viewID: id of the new view
        % viewInfo: the properties that need to be set on the new view node
        function addView(this, parentDocumentID, viewID, viewInfo)
            if isempty(this.DocumentMap)
                return;
            end

            parentDocumentNode = this.DocumentMap(parentDocumentID);
            peerNodeChild = internal.matlab.variableeditor.peer.PeerNodeChild(...
                parentDocumentNode.PeerNode, ...
                internal.matlab.desktop_workspacebrowser.PeerModelWSBProvider.PeerNodeTypeView, ...
                viewInfo);
            if isempty(this.ViewMap)
                this.ViewMap = containers.Map;
            end
            % viewmap stores the key as a combination of 'docid+viewid' inorder to have unique ids
            % TODO: Currently viewID on the view is a counter (Ex: '__1'),
            % if this is changed to be (docId+viewId) live editor prepopulations usecase breaks.
            % Needs to be refactored as follow-up
            viewKey = [parentDocumentID '_' viewID];
            this.ViewMap(viewKey) = peerNodeChild;
        end

        % deletes the PeerModelServer, event and property set listeners,
        % documents, views
        function delete(this)
            if ~isempty(this.PeerModelServer) && isvalid(this.PeerModelServer)
                this.PeerModelServer.delete;
            end
            if ~isempty(this.PeerEventListener)
                delete(this.PeerEventListener);
            end
            if ~isempty(this.PropertySetListener)
                delete(this.PropertySetListener);
            end
            this.deleteDocuments();
        end

        % deletes the cache of document nodes
        function deleteDocuments(this)
            if ~isempty(this.DocumentMap) && isvalid(this.DocumentMap)
                documentKeys = keys(this.DocumentMap);
                for i=1:length(documentKeys)
                    delete(this.DocumentMap(documentKeys{i}));
                end
                this.DocumentMap = containers.Map;
            end
            this.deleteViewMap();
        end

        % deletes the cache of view nodes
        function deleteViewMap(this)
            if ~isempty(this.ViewMap) && isvalid(this.ViewMap)
                viewKeys = keys(this.ViewMap);
                for i=1:length(viewKeys)
                    delete(this.ViewMap(viewKeys{i}));
                end
                this.ViewMap = containers.Map;
            end
        end

        % deletes the document corresponding to the given id
        function deleteDocument(this, docID)
            documentPeerNode = this.DocumentMap(docID);
            delete(documentPeerNode);
        end

        % Gets the root node of the Peer Tree
        % TODO: remove this API once the PeerManagerFactory is deleted
        function root=getRoot(this)
            if isempty(this.Root)
              this.createRoot(this.RootType);
            end

            root = this.Root;
        end

        % Returns a unique id for the given manager, document or view
        % the uniuq id in case of peer provider is the id on the peer node
        function uid = getUID(this, sourceObj, id)
            try
                % returns the id on the root
                if isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteManager')
                    rootNode = this.getRoot();
                    uid = rootNode.Id;
                elseif isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteDocument')
                    % returns the id on the document peer node
                    documentNode = this.getDocumentPeerNode(id);
                    uid = documentNode.Id;
                elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                    % returns the id on the view peer node
                    viewKey = [sourceObj.parentID '_' id];
                    viewNode = this.getViewPeerNode(viewKey);
                    uid = viewNode.Id;
                end
            catch e
                % should never result in an exception in software
                % can only happen in tests when they want to mock uid without
                % peer nodes
                uid = [];
            end
        end
    end

    methods(Access='private')
        % Creates the root of the Peer Tree
        function createRoot(this, RootType)
            if isempty(this.Root)
                if isempty(this.PeerModelServer.getRoot())
                    this.Root = this.PeerModelServer.createRoot(RootType);
                    % Set Channel as a root property on the Manager
                    this.Root.setProperty('Channel', this.Channel);
                else
                    this.Root = this.PeerModelServer.getRoot();
                end
            end
        end

        % returns the peer node associated with the source object
        function node = getPeerNode(this, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteManager')
                node = this.getRoot;
            elseif isa(sourceObj, 'internal.matlab.variableeditor.peer.RemoteDocument')
                node = this.getDocumentPeerNode(id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = [sourceObj.parentID '_' id];
                node = this.getViewPeerNode(viewKey);
            end
        end

        % Accesses the cached (document id -> node map) and returns the peer
        % node corresponding to the given document id
        function documentPeerNode = getDocumentPeerNode(this, docId)
            documentNode = this.DocumentMap(docId);
            documentPeerNode = documentNode.PeerNode;
        end

        % Accesses the cached (view id -> node map) and returns the peer
        % node corresponding to the given view id
        function viewPeerNode = getViewPeerNode(this, viewId)
            viewNode = this.ViewMap(viewId);
            viewPeerNode = viewNode.PeerChildNode;
        end

        % Accesses the manager peer node and returns the value
        % corresponding to the given property name
        function propertyValue = getManagerProperty(this, propertyName)
            propertyValue = this.getRoot.getProperty(propertyName);
        end

        % Accesses the manager peer node and returns all the properties
        % on the peer node
        function managerProps = getManagerProperties(this)
            managerProps = this.getRoot.getProperties;
        end

        % Accesses the document peer node and returns the value
        % corresponding to the given property name
        function propertyValue = getDocumentProperty(this, propertyName, docId)
            documentNode = this.getDocumentPeerNode(docId);
            propertyValue = documentNode.getProperty(propertyName);
        end

        % Accesses the document peer node and returns the value
        % corresponding to the given property name
        function documentProps = getDocumentProperties(this, docId)
            documentNode = this.getDocumentPeerNode(docId);
            documentProps = documentNode.getProperties;
        end

        % Accesses the view peer node and returns the value
        % corresponding to the given property name
        function propertyValue = getViewProperty(this, propertyName, viewId)
            viewNode = this.getViewPeerNode(viewId);
            propertyValue = viewNode.getProperty(propertyName);
        end

        % Accesses the view peer node and returns the value
        % corresponding to the given property name
        function viewProps = getViewProperties(this, viewId)
            viewNode = this.getViewPeerNode(viewId);
            viewProps = viewNode.getProperties;
        end

        % Dispatches an event to the client on the manager's peer node
        function dispatchEventOnManager(this, eventObj)
            this.getRoot.dispatchEvent(eventObj);
        end

        % Dispatches an event to the client on the document's peer node
        function dispatchEventOnDocument(this, eventObj, docId)
            documentNode = this.getViewPeerNode(docId);
            documentNode.dispatchEvent(eventObj);
        end

        % Dispatches an event to the client on the view's peer node
        function dispatchEventOnView(this, eventObj, viewId)
           viewNode = this.getViewPeerNode(viewId);
           viewNode.dispatchEvent(eventObj);
        end

        % Dispatches a property set event to client on the manager's peer node
        function setManagerProperty(this, propertyName, propertyValues)
            map = java.util.HashMap();
            map.put('Source', 'server');
            if ~isstruct(propertyValues)
                map.put(propertyName, propertyValues);
            else
                fields = fieldnames(propertyValues);
                for i=1:length(fields)
                    map.put(fields{i}, propertyValues.(fields{i}));
                end
            end

            this.getRoot.setProperty(propertyName, map);
        end

        % Dispatches a property set event to client on the manager's peer node
        function setManagerProperties(this, propertiesObj)
            this.getRoot.setProperties(propertiesObj);
        end

        % Dispatches a property set event to client on the document's peer node
        function setDocumentProperty(this, propertyName, propertyValues, docId)
            documentPeerNode = this.getDocumentPeerNode(docId);
            documentPeerNode.setProperty(propertyName, propertyValues);
        end

        % Dispatches a property set event to client on the document's peer node
        function setDocumentProperties(this, propertiesObj, docId)
            documentPeerNode = this.getDocumentPeerNode(docId);
            documentPeerNode.setProperties(propertiesObj);
        end

        % Dispatches a property set event to client on the view's peer node
        function setViewProperty(this, propertyName, propertyValues, viewId)
            viewPeerNode = this.getViewPeerNode(viewId);

            if isempty(viewPeerNode)
                return;
            end

            if ~isstruct(propertyValues)
                if isa(propertyValues,'java.util.HashMap') && ~propertyValues.containsKey('source')
                    propertyValues.put('source', 'server');
                end
                viewPeerNode.setProperty(propertyName, propertyValues);
                return;
            end

            map = java.util.HashMap();
            fields = fieldnames(propertyValues);
            for i=1:length(fields)
                map.put(fields{i}, propertyValues.(fields{i}));
            end
            if ~map.containsKey('source')
                map.put('source', 'server');
            end

            viewPeerNode.setProperty(propertyName, map);
        end

        % Dispatches a property set event to client on the view's peer node
        function setViewProperties(this, propertiesObj, viewId)
            viewPeerNode = this.getViewPeerNode(viewId);
            viewPeerNode.setProperties(propertiesObj);
        end
    end
end
