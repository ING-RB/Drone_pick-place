classdef MF0ViewModelWSBProvider < internal.matlab.variableeditor.peer.RemoteProvider
    % PeerModelWSBProvider handles all the peer communication between
    % client and server
    % It has knowledge of the Manager, Document, View structure
    % Communicates the information received from the client to the
    % RemoteManager, RemoteDocument, RemoteView

    % Copyright 2019-2024 The MathWorks, Inc.

    properties (SetAccess='protected', GetAccess='public', Dependent=false, Hidden=false, Transient)
        ViewModelManager;
    end %properties
    
    properties
        Channel;
        SourceMap;
    end

    properties (Transient, WeakHandle)
        Manager internal.matlab.variableeditor.MLManager;
    end

    properties (Transient)
        Root;
        DocumentMap;
        ViewMap;
    end

    properties(Constant)
      PeerNodeTypeView = '_WorkspaceBrowserViewModel_';
      PeerNodeTypeDocument = '_WorkspaceBrowserDocument_';
      PeerModelChannel = '/WorkspaceBrowserManager';
      RootType = '/WorkspaceBrowser_Root';
    end

    methods
        % Constructor
        function this = MF0ViewModelWSBProvider(Channel)
            this.SourceMap = containers.Map;
            this.Channel = Channel;
            Root = [Channel '_Root'];
            factory = viewmodel.internal.ViewModelManagerFactory;
            this.ViewModelManager = factory.getViewModelManager(Channel);

            if ismethod(this.ViewModelManager, "setCallbackDebugFlag")
                % Set stop at breakpoints behavior
                this.ViewModelManager.setCallbackDebugFlag(~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            end

            this.createRoot(Root);

            % Send event for the manager creation
%             if (internal.matlab.variableeditor.peer.PeerUtils.isTestingOn)
%               internal.matlab.variableeditor.peer.PeerUtils.sendPeerEvent(this.Root, 'ManagerCreated', 'Channel', Channel);
%             end
            
            message.publish(this.Channel + "/workspaceBrowserServerInitialized",...
            struct('initialized', true));
            message.subscribe(this.Channel + "/DeleteWSBManager", @(x) this.deleteManager(), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
        end

        % API gets called when WSB is destroyed from client side
        % Clean Up of ViewModel, Manager, root and instance from WSBFactory
        % for this.Channel
        function deleteManager(this)
            message.unsubscribe(this.Channel + "/DeleteWSBManager");
            if ~isempty(this.ViewModelManager)
                this.ViewModelManager.delete;
            end
            delete(this.Manager);
            internal.matlab.desktop_workspacebrowser.WSBFactory.deleteManager(this.Channel, false);
            if ~isempty(this.getRoot)
                this.getRoot.delete;
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
            
            if ~isKey(this.SourceMap, peerNode.Id)
                this.SourceMap(peerNode.Id) = sourceObj;
            end

            peerNode.addEventListener('peerEvent', @(src, evt) handleEventFromClient(this, src, evt));
            peerNode.addEventListener('propertySet', @(src, evt) handlePropertySetFromClient(this, src, evt));
        end

        % Handles peer events received from the client on manager,
        % document, view nodes.
        % src: can be manager, document or view nodes
        % evt: event object
        function handleEventFromClient(this, src, evt)
            if isfield(evt,'Originator') && evt.Originator.isClient
                return;
            end

            % This was checking for src.Id in the sourcemap before doing
            % this and then falling back to this.Manager.handle... if it
            % wasn't there. Not sure why it was doing that. It doesn't
            % appear to actually be hitting the fallback ever. Lopping
            % out the condition
            sourceObj = this.SourceMap(src.Id);
            sourceObj.handleEventFromClient(src, evt);
        end

        % Dispatches event to the client. This is called by the manager,
        % document or view
        % sourceObj: Can be manager, document or view
        % eventObj: event object
        % id: id of the sourceObj
        function dispatchEventToClient(this, sourceObj, eventObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.Manager')
                this.dispatchEventOnManager(eventObj);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.Document')
                this.dispatchEventOnDocument(eventObj, id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                % viewm ap stores the key as a combination of 'docid+viewid' inorder to have unique ids
                % TODO: Currently viewID on the view is a counter (Ex: '__1'),
                % if this is changed to be (docId+viewId) live editor prepopulations usecase breaks.
                % Needs to be refactored as follow-up
                viewKey = sourceObj.parentID + "_" + id;
                this.dispatchEventOnView(eventObj, viewKey);
            end
        end

        % Provider listens to property set events from the client
        % src: Can be manager, document or view
        % evt: event object
        function status = handlePropertySetFromClient(this, src, evt)
            status = '';
            if isfield(evt.data.newValue, 'Source')
                source = evt.data.newValue.Source;
                if strcmp('server',source)
                    return;
                end
            end

            % Extracts out the information in the event object to MATLAB object
            % (struct) format and sends to the Manager
            % Provider does not care about the internals of the event
            % object
            if isKey(this.SourceMap, src.Id)
                sourceObj = this.SourceMap(src.Id);
                sourceObj.handlePropertySetFromClient(src, evt);
            else
                this.Manager.handlePropertySetFromClient(src, evt);
            end
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
            elseif isa(sourceObj, 'internal.matlab.desktop_workspacebrowser.RemoteWorkspaceDocument')
                this.setDocumentProperty(propertyName, propertyValue, id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = sourceObj.parentID + "_" + id;
                this.setViewProperty(propertyName, propertyValue, viewKey);
            end
        end

        % Dispatches an event to set a propertiesObj on the client
        % propertiesObj: properties object to be set on the peernde
        % sourceObj: object on which this property needs to be set. Can be
        % manager, document or view
        % id: id of the sourceObj
        function setPropertiesOnClient(this, propertiesObj, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.Manager')
                this.setManagerProperties(propertiesObj);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.Document')
                this.setDocumentProperties(propertiesObj, id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = sourceObj.parentID + "_" + id;
                this.setViewProperties(propertiesObj, viewKey);
            end
        end

        % Returns the property value of the property passed in by accessing
        % the corresponding peernode
        % propertyName: name of the property whose value is needed
        % sourceObj: object on which this property exists
        % id: id of the sourceObj
        function propVal = getProperty(this, propertyName, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.Manager')
                propVal = this.getManagerProperty(propertyName);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.Document')
                propVal = this.getDocumentProperty(propertyName, id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = sourceObj.parentID +  "_" + id;
                propVal = this.getViewProperty(propertyName, viewKey);
            end
        end

        % Returns all the properties by accessing
        % the corresponding peernode
        % sourceObj: object on which this property exists
        % id: id of the sourceObj
        function propVal = getProperties(this, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.Manager')
                propVal = this.getManagerProperties();
            elseif isa(sourceObj, 'internal.matlab.variableeditor.Document')
                propVal = this.getDocumentProperties(id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = sourceObj.parentID + "_" + id;
                propVal = this.getViewProperties(viewKey);
            end
        end

        % Called by the RemoteManager to add a document
        % docID: id of the new document
        % documentInfo: the properties that need to be set on the new
        % document's node
        function addDocument(this, docID, documentInfo)
            variableNode = this.getRoot.addChild(docID, documentInfo);
            
            if isempty(this.DocumentMap)
                this.DocumentMap = containers.Map;
            end
            this.DocumentMap(docID) = variableNode;
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
            children = parentDocumentNode.getChildren;
            if length(children) > 0
                delete(children(1));
            end
            
            childNode = parentDocumentNode.addChild(parentDocumentID, viewInfo);
            
            if isempty(this.ViewMap)
                this.ViewMap = containers.Map;
            end
            % viewmap stores the key as a combination of 'docid+viewid' inorder to have unique ids
            % TODO: Currently viewID on the view is a counter (Ex: '__1'),
            % if this is changed to be (docId+viewId) live editor prepopulations usecase breaks.
            % Needs to be refactored as follow-up
            viewKey = parentDocumentID + "_" + viewID;
            this.ViewMap(viewKey) = childNode;
        end

        % deletes the PeerModelServer, event and property set listeners,
        % documents, views
        function delete(this)
            if ~isempty(this.ViewModelManager) && isvalid(this.ViewModelManager)
                this.ViewModelManager.delete;
            end
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
                    this.deleteView(viewKeys{i});
                end
                this.ViewMap = containers.Map;
            end
        end
        
        % delete ViewPeerNode for a given ViewMapID
        function deleteView(this, viewID)
            if this.ViewMap.isKey(viewID)
                thisMap = this.ViewMap(viewID);
                if isvalid(thisMap)
                    delete(thisMap);
                end
                remove(this.ViewMap, viewID);
            end
        end

        % deletes the document corresponding to the given id
        function deleteDocument(this, docID)
            documentPeerNode = this.DocumentMap(docID);
            if isvalid(documentPeerNode)
                delete(documentPeerNode);
            end
        end

        % Gets the root node of the Peer Tree
        % TODO: remove this API once the PeerManagerFactory is deleted
        function root=getRoot(this)
            if isempty(this.Root)
              this.createRoot([this.Channel '_Root']);
            end

            root = this.Root;
        end

        % Returns a unique id for the given manager, document or view
        % the uniuq id in case of peer provider is the id on the peer node
        function uid = getUID(this, sourceObj, id)
            try
                % returns the id on the root
                if isa(sourceObj, 'internal.matlab.variableeditor.Manager')
                    rootNode = this.getRoot();
                    uid = rootNode.Id;
                elseif isa(sourceObj, 'internal.matlab.variableeditor.Document')
                    % returns the id on the document peer node
                    documentNode = this.getDocumentPeerNode(id);
                    uid = documentNode.Id;
                elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                    % returns the id on the view peer node
                    viewKey = sourceObj.parentID  + "_"  + id;
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
                if ~this.ViewModelManager.hasRoot()
                    this.Root = this.ViewModelManager.setRoot(RootType);
                    % Set Channel as a root property on the Manager
                    this.Root.setProperty('Channel', this.Channel);
                else
                    this.Root = this.ViewModelManager.Root;
                end
            end
        end

        % returns the peer node associated with the source object
        function node = getPeerNode(this, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.Manager')
                node = this.getRoot;
            elseif isa(sourceObj, 'internal.matlab.variableeditor.Document')
                node = this.getDocumentPeerNode(id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = sourceObj.parentID + "_" + id;
                node = this.getViewPeerNode(viewKey);
            end
        end

        % Accesses the cached (document id -> node map) and returns the peer
        % node corresponding to the given document id
        function documentPeerNode = getDocumentPeerNode(this, docId)
            documentNode = this.DocumentMap(docId);
            documentPeerNode = documentNode;
        end

        % Accesses the cached (view id -> node map) and returns the peer
        % node corresponding to the given view id
        function viewPeerNode = getViewPeerNode(this, viewId)
            viewPeerNode = [];
            try
                viewNode = this.ViewMap(viewId);
                viewPeerNode = viewNode;
            catch
            end
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
            obj = struct('eventDataStruct', eventObj);
            this.getRoot.dispatchEvent(eventObj.eventType, obj);
        end

        % Dispatches an event to the client on the document's peer node
        function dispatchEventOnDocument(this, eventObj, docId)
            documentNode = this.getViewPeerNode(docId);
            documentNode.dispatchEvent(eventObj);
        end

        % Dispatches an event to the client on the view's peer node
        function dispatchEventOnView(this, eventObj, viewId)
           viewNode = this.getViewPeerNode(viewId);
           % Dispatch event with eventType and payload
           viewNode.dispatchEvent('peerEvent', eventObj);
        end

        % Dispatches a property set event to client on the manager's peer node
        function setManagerProperty(this, propertyName, propertyValues)
            map = struct;
            map.Source = 'server';
            map.(propertyName) = propertyValues;
            this.getRoot.setProperty(propertyName, propertyValues);
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
           
            viewPeerNode.setProperty(propertyName, propertyValues);
        end

        % Dispatches a property set event to client on the view's peer node
        function setViewProperties(this, propertiesObj, viewId)
            viewPeerNode = this.getViewPeerNode(viewId);
            viewPeerNode.setProperties(propertiesObj);
        end
    end
end
