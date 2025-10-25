classdef MF0ViewModelVEProvider < internal.matlab.variableeditor.peer.RemoteProvider

    % MF0ViewModelVEProvider handles all the peer communication between
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
    end

    properties (Transient, WeakHandle)
        Manager internal.matlab.variableeditor.MLManager;
    end

    properties(Transient)
        Root;
    end

    properties(Constant)
      PeerNodeTypeView = '_VariableEditorViewModel_';
      PeerNodeTypeDocument = '_VariableEditorDocument_';
      ViewModelChannel = '/VariableEditorVMManager';
    end

    properties
        DocumentMap;
        ViewMap;
    end

    % Peer Listener Properties
    properties (SetAccess='protected', Transient)
        PeerEventListener;
        peerEventListener;
        PropertySetListener;
    end %properties

    properties (SetAccess='protected')
        Initialized = false;
    end

    methods
        % Constructor
        function this = MF0ViewModelVEProvider(Channel)
            arguments
                Channel char
            end
            % If connector is not turned on, ensureServiceOn. Certain
            % enviornments like deployment may not have this service running.
            if ~connector.isRunning
                connector.ensureServiceOn;
            end
            this.Channel = Channel;
            Root = [Channel '_Root'];
            factory = viewmodel.internal.ViewModelManagerFactory;
            this.ViewModelManager = factory.getViewModelManager(Channel);
            % Set stop at breakpoints behavior
            this.ViewModelManager.setCallbackDebugFlag(~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.createRoot(Root);
            % the import tool still uses this DeleteManager message
            % TODO look into removing the messageservice call
            message.subscribe(this.Channel + "/DeleteManager", @(x) this.deleteManager(), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            
            % Send event for the manager creation
            if (internal.matlab.variableeditor.peer.PeerUtils.isTestingOn)
              data = struct;
              this.Root.dispatchEvent('ManagerCreated', data);
            end
            
            message.subscribe(this.Channel + "/queryInitStatus", ...
                @(x) this.sendInitializedMessage(), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            
            this.Initialized = true;
            this.sendInitializedMessage();
        end
        
        function sendInitializedMessage(this)
            if this.Initialized
                message.publish(this.Channel + "/variableEditorServerInitialized",...
                    struct('initialized', true));
            end
        end
        
        % API called by RemoteManager, RemoteDocument and RemoteView set up listeners on their respective peer nodes
        % sourceObj: Can be manager, document or view objects
        function setUpProviderListeners(this, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.Manager')
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
            % do not save the listener for cleanup later. if we don't save
            % the listener it will be cleaned up with the ViewModel
            % deletion automatically
            peerNode.addEventListener('peerEvent', @(src, evt) handleEventFromClient(this, sourceObj, evt));
            peerNode.addEventListener('propertySet', @(src, evt) handlePropertySetFromClient(this, sourceObj, evt));
        end
        
        function deleteManager(this)
            message.unsubscribe(this.Channel + "/DeleteManager");
                     
            if ~isempty(this.PeerEventListener)
                this.PeerEventListener.delete;
            end
            
            if ~isempty(this.PropertySetListener)
                this.PropertySetListener.delete;
            end
            
            if ~isempty(this.getRoot)
                this.getRoot.delete;
            end
            
            if ~isempty(this.ViewModelManager)
                this.ViewModelManager.delete;
            end
            delete(this.Manager);
            
            internal.matlab.variableeditor.peer.VEFactory.deleteManager(this.Channel, true);
        end
        
        % Handles peer events received from the client on manager,
        % document, view nodes.
        % src: can be manager, document or view nodes
        % evt: event object
        function handleEventFromClient(~, src, evt)
            if isfield(evt,'srcLang') && ~strcmp(evt.srcLang, 'JS')
                return;
            end

            src.handleEventFromClient(src, evt);
        end

        % Dispatches event to the client. This is called by the manager,
        % document or view
        % sourceObj: Can be manager, document or view
        % eventObj: event object
        % id: id of the sourceObj
        function dispatchEventToClient(this, sourceObj, eventObj, id)
            % TODO: check on the performance of 'isa' calls since they are used many times
            if isa(sourceObj, 'internal.matlab.variableeditor.Manager')
                this.dispatchEventOnManager(eventObj);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.Document')
                this.dispatchEventOnDocument(eventObj, id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                % viewmap stores the key as a combination of 'docid+viewid' inorder to have unique ids
                % TODO: Currently viewID on the view is a counter (Ex: '__1'),
                % if this is changed to be (docId+viewId) live editor prepopulations usecase breaks.
                % Needs to be refactored as follow-up
                viewKey = sourceObj.parentID + "_" + id;
                this.dispatchEventOnView(eventObj, viewKey);
            else
                % Fallback to just dispatching the event on the root
                this.dispatchEventOnManager(eventObj);
            end
        end

        % Provider listens to property set events from the client
        % src: Can be manager, document or view
        % evt: event object
        function status = handlePropertySetFromClient(~, src, evt)
            status = '';
            if isfield(evt, 'srcLang') && strcmp(evt.srcLang, 'CPP')
               return;
            end

            % Extracts out the information in the event object to MATLAB object
            % (struct) format and sends to the Manager
            % Provider does not care about the internals of the event
            % object
            if ismethod(src, 'handlePropertySetFromClient')
                src.handlePropertySetFromClient('', evt);
            end
        end

        % Dispatches an event to set a property value on the client
        % propertyName: property whose value needs to be set
        % propertyValue: new value of the given property
        % sourceObj: object on which this property needs to be set. Can be
        % manager, document or view
        % id: id of the sourceObj
        function setPropertyOnClient(this, propertyName, propertyValue, sourceObj, id)
            if isa(sourceObj, 'internal.matlab.variableeditor.Manager')
                this.setManagerProperty(propertyName, propertyValue);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.Document')
                this.setDocumentProperty(propertyName, propertyValue, id);
            elseif isa(sourceObj, 'internal.matlab.variableeditor.ViewModel')
                viewKey = sourceObj.parentID + "_" + id; 
                this.setViewProperty(propertyName, propertyValue, viewKey);
            else
                % Fallback to just setting the property on the root
                this.setManagerProperty(propertyName, propertyValue);
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
                viewKey = sourceObj.parentID + "_" + id;
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
            variableNode = this.Root.addChild(docID, documentInfo);
            
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
            % TODO: temporary since currently document can have just one
            % view. This was needed since were were passing in the manager as the parent to unsupported views
            % in the current code when the view on a document was changed. Change this to have a better design
            % for usecase when the view attached to a document is changed. (Ex: add 'updateView' API and call that)
            children = parentDocumentNode.getChildren;
            if ~isempty(children)
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
            viewKey = parentDocumentID + "_" +  viewID;
            this.ViewMap(viewKey) = childNode;
        end

        % deletes the PeerModelServer, event and property set listeners,
        % documents, views
        function delete(this)
            if ~isempty(this.Root) && isvalid(this.Root)
                this.Root.delete;
            end
            
            if ~isempty(this.ViewModelManager) && isvalid(this.ViewModelManager)
                this.ViewModelManager.delete;
            end
        end

        % deletes the cache of document nodes
        function deleteDocuments(this)
            if ~isempty(this.DocumentMap) && isvalid(this.DocumentMap)
                documentKeys = keys(this.DocumentMap);
                for i=1:length(documentKeys)
                    thisDoc = this.DocumentMap(documentKeys{i});
                    if isvalid(thisDoc)
                        delete(thisDoc);
                    end
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
            if ~isempty(documentPeerNode) && isvalid(documentPeerNode)
                delete(documentPeerNode);
                remove(this.DocumentMap, docID);
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
                    viewKey = sourceObj.parentID + "_" + id;
                    viewNode = this.getViewPeerNode(viewKey);
                    uid = viewNode.Id;
                end
            catch
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
                    this.Root.setProperties(struct('Channel', this.Channel, 'HasFocus', '', 'FocusedDocument', ''));
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
            if ~isvalid(this) || ~isKey(this.ViewMap, viewId) || ~isvalid(this.ViewMap(viewId))
                return;
            end
            
            viewNode = this.ViewMap(viewId);
            viewPeerNode = viewNode;
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
            %obj = struct('eventDataStruct', eventObj);
            root = this.getRoot;
            root.dispatchEvent('peerEvent', eventObj);
        end

        % Dispatches an event to the client on the document's peer node
        function dispatchEventOnDocument(this, eventObj, docId)
            documentNode = this.getViewPeerNode(docId);
            documentNode.dispatchEvent(eventObj);
        end

        % Dispatches an event to the client on the view's peer node
        function dispatchEventOnView(this, eventObj, viewId)
            viewNode = this.getViewPeerNode(viewId);
            viewNode.dispatchEvent('peerEvent', eventObj);
        end

        % Dispatches a property set event to client on the manager's peer node
        function setManagerProperty(this, propertyName, propertyValues)
            % TODO I think this isvalid check is necessary because of the
            % timer for deletion. Double check if we can remove it after
            % C++ VM happens (same with setManagerProperties)
            if isvalid(this.getRoot)
                this.getRoot.setProperty(propertyName, propertyValues);
            end
        end

        % Dispatches a property set event to client on the manager's peer node
        function setManagerProperties(this, propertiesObj)
            % TODO see setManagerProperty TODO
            if isvalid(this.getRoot)
                this.getRoot.setProperties(propertiesObj);
            end
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
                viewPeerNode.setProperty(propertyName, propertyValues);
                return;
            end

            map = struct;
            fields = fieldnames(propertyValues);
            for i=1:length(fields)
                map.(fields{i}) = propertyValues.(fields{i});
            end
            if ~isfield(map, 'source')
                map.('source') = 'server';
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
