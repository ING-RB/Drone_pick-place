classdef RemoteManager < internal.matlab.variableeditor.MLManager
    % A class defining MATLAB PeerModel Variable Manager
    %

    % Copyright 2013-2024 The MathWorks, Inc.

    % Property Definitions:

    % Events
    events
       FocusGained;  % Sent when a manager gains focus
       FocusLost;  % Sent when manager loses focus
    end

    properties (Hidden=true)
        Channel;
        ClonedVariableList;
        ActionManagerInfo;
        CodePublishing logical = false
    end

    properties(Transient, WeakHandle)
        Provider internal.matlab.variableeditor.peer.RemoteProvider = internal.matlab.variableeditor.peer.MF0ViewModelVEProvider.empty;
    end

    properties(Transient)
        ActionManager;
        ContextMenuProvider;
    end

    % Peer Listener Properties
    properties (SetAccess='protected', Transient)
        DocFocusedListener;
        DocFocusLostListener;
    end %properties

    properties (Access='protected')
        DelayedDocumentList = [];
    end

    % HasFocus_I
    properties (SetObservable=true, SetAccess='protected', GetAccess='protected', Dependent=false, Hidden=true)
        % HasFocus_I Property
        HasFocus_I = false;
    end %properties
    methods
        function storedValue = get.HasFocus_I(this)
            storedValue = this.HasFocus_I;
        end

        function set.HasFocus_I(this, newValue)
            this.HasFocus_I = newValue;
        end
    end

    % HasFocus
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=true, Hidden=false)
        % HasFocus Property
        HasFocus;
    end %properties

    methods
        function storedValue = get.HasFocus(this)
            storedValue = this.HasFocus_I;
        end

        function set.HasFocus(this, newValue)
            if this.HasFocus_I && ~newValue
                this.HasFocus_I = newValue;

                if ~internal.matlab.variableeditor.peer.VEFactory.inFocusUpdate
                    internal.matlab.variableeditor.peer.VEFactory.setFocusedManager([]);
                end

                % Fire event when manager loses focus
                eventdata = internal.matlab.variableeditor.ManagerEventData;
                eventdata.Manager = this;
                try
                    this.notify('FocusLost',eventdata);
                catch e
                    internal.matlab.datatoolsservices.logDebug("variableeditor::remoteManager::error", e.message);
                end


                % Send an event with the new value
                this.setProperty('HasFocus', newValue);
            elseif newValue
                this.HasFocus_I = newValue;

                if ~internal.matlab.variableeditor.peer.VEFactory.inFocusUpdate
                    internal.matlab.variableeditor.peer.VEFactory.setFocusedManager(this);
                end

                % Fire event when manager gainsfocus
                eventdata = internal.matlab.variableeditor.ManagerEventData;
                eventdata.Manager = this;
                try
                    this.notify('FocusGained',eventdata);
                catch e
                    internal.matlab.datatoolsservices.logDebug("variableeditor::remoteManager::error", e.message);
                end

                % Send an event with the new value
                this.setProperty('HasFocus', newValue);
            end

            this.HasFocus_I = newValue;
        end

        % Initializes Actions on the server of type specified by creating an
        % ActionManager instance. Notifies ClientPeerManager by sending the
        % namespace used to initialize the Actions.
        % actionNamespace : Namespace with which the ActionDataService (MF0
        %                   Provider) is created
        % startPath       : Path to ML actions which is scanned to
        %                   initialize actions and add them to ActionDataService
        % classType       : Class type of Action.(E.g VEAction) If no classType is
        %                   provided, default to default Action.m class.
        % createActionsSynchronously : Logical which creates actions
        %                              synchronously or async when ML is idle (using _dtcallback)
        % actionClasses   : Optional string array specifying specific
        %                   actions to be initialized instead of scanning from startPath.
        function [ActionManager] = initActions(this, actionNamespace, startPath, classType, createActionsSynchronously, actionClasses)
            arguments
                this
                actionNamespace
                startPath char                              = ''
                classType                                   = 'internal.matlab.datatoolsservices.actiondataservice.Action'
                createActionsSynchronously  (1,1) logical   = false
                actionClasses                     string    = []
            end
            if (isempty(this.ActionManager)) || ~isvalid(this.ActionManager)
                peerProvider = internal.matlab.datatoolsservices.actiondataservice.remote.MF0VMActionDataServiceProvider(actionNamespace);
                veADS = internal.matlab.variableeditor.VEActionDataService(peerProvider, this);
                ActionManager = internal.matlab.datatoolsservices.actiondataservice.ActionManager(this, peerProvider, veADS);
                % If startPath exists, scan and initialize actions using the path.
                if ~isempty(startPath)
                    % Defer startup cost by initializing actions when MATLAB
                    % is idle g2427655
                    if createActionsSynchronously
                        this.callInitActionOnIdle(actionNamespace, startPath, classType, ActionManager);
                    else
                        builtin('_dtcallback', @() this.callInitActionOnIdle(actionNamespace, startPath, classType, ActionManager), ...
                            internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle);
                    end
                    % callInitActionsOnIdle also sets ActionsInitialized that syncs up actions on the client.
                elseif ~isempty(actionClasses)
                    % Loads fixed set of actionClasses on to the ActionManager
                    ActionManager.loadActions(actionClasses);
                    this.setProperty('ActionsInitialized', actionNamespace);
                end
                this.ActionManager = ActionManager;
            else
                ActionManager = this.ActionManager;
            end
        end

        % Initializes ContextMenus on the server for each instance of the
        % Manager. 'ContextMenuManager' parses through the xml file and communicates this to the client
        function [provider] = initContextMenu(this, queryString, xmlPath, contextNamespace)
            contextMenuManager = internal.matlab.datatoolsservices.contextmenuservice.ContextMenuManager.getInstance();
            provider = contextMenuManager.createMenuProvider(xmlPath, contextNamespace, struct('channel', contextNamespace, 'queryString', queryString));

            this.setProperty('ContextMenuServiceNameSpace', contextNamespace);

            this.ContextMenuProvider = provider;
        end
    end

    % Constructor and client-server communication APIs
    methods(Access='public')
        function this = RemoteManager(provider, IgnoreUpdates, ActionManagerInfo)
            this@internal.matlab.variableeditor.MLManager(IgnoreUpdates);

			this.ClonedVariableList = containers.Map;
            this.Provider = provider;
            this.Channel = provider.Channel;

            % if the action manager info object has been passed it then set
            % it as a property
            if exist('ActionManagerInfo', 'var') && ~isempty(ActionManagerInfo)
                this.ActionManagerInfo = ActionManagerInfo.initActionManager;
            end

            % Add document focus listeners
            this.DocFocusedListener = event.listener(this,'DocumentFocusGained',@(es, ed) this.handleDocumentFocusEvent(es, ed));
            this.DocFocusLostListener = event.listener(this,'DocumentFocusLost',@(es, ed) this.handleDocumentFocusEvent(es, ed));

            this.Provider.setUpProviderListeners(this, []);
        end

        % Temporary code returns the focus state of manager.
        % This will be refactored to move the HasFocus property to the
        % base Manager class.
        function focused = isFocused(this)
            focused = this.HasFocus;
        end

        % API used by the provider when an event is received from the
        % client
        function handleEventFromClient(this, ~, ed)
            if ~isvalid(this)
                return;
            end
            if isfield(ed.data,'type')
                try
                    switch ed.data.type
                        case 'OpenVariable'
                            if isfield(ed.data,'workspace') && strcmp(ed.data.workspace,'test')
                                this.openvar(ed.data.variable, 'caller', evalin('caller', ed.data.variable));
                            else
                                userContext = '{}';
                                if isfield(ed.data,'userContext')
                                    userContext = ed.data.userContext;
                                end
                                value = internal.matlab.variableeditor.NullValueObject(ed.data.variable);
                                if isfield(ed.data,'value')
                                    value = ed.data.value;
                                end
                                workspace = 'debug';
                                if isfield(ed.data,'workspace')
                                    workspace = ed.data.workspace;
                                end
                                this.delayedOpenVar(ed.data.variable, workspace, userContext, value);
                            end
                        case 'OpenDocument'
                            docCreationArgs = ed.data;
                            this.createSingleDeferredDocument(varName = docCreationArgs.variable, DocID = docCreationArgs.docID, UserContext = docCreationArgs.userContext, ...
                                 Workspace = docCreationArgs.workspace, DisplayFormat = docCreationArgs.displayFormat);
                        case 'RemoveDocument' % Fired when a document is closed on the client
                            workspace = 'debug';
                            if isfield(ed.data,'workspace')
                                workspace = ed.data.workspace;
                            end
                            % If there are any associated variables cloned
                            % from the current document, clean them up.
                            clonedVariables = string(keys(this.ClonedVariableList));
                            popoutID = clonedVariables(endsWith(clonedVariables, ed.data.variable));
                            if ~isempty(popoutID)
                                for i=1:length(popoutID)
                                    this.cleanupClonedVariableList(char(popoutID(i)));
                                end
                            end
                            %% TODO: CONSOLIDATE THE BLOCK BELOW WITH THE CLOSEVAR API IN MLMANAGER
                            if ~isempty(this.Documents)
                                docIndex = find(strcmp({this.Documents.DocID}, ed.data.variable));
                            end

                            if ~isempty(docIndex)
                                doc = this.Documents(docIndex);
                                name = doc.Name;
                                % Call only close only if there is a document to close
                                if this.FocusedDocument == doc
                                    this.FocusedDocument = [];
                                end

                                % Delete the document
                                if isvalid(doc)
                                    delete(doc);
                                end

                                % Remove the element from the Documents list
                                if ~isempty(this.Documents) && ...
                                        docIndex <= length(this.Documents) && ...
                                        isequal(this.Documents(docIndex), doc)
                                    this.Documents = [this.Documents(1:docIndex-1) this.Documents(docIndex+1:end)];
                                    % Decrement the document counter
                                    this.deccrementWorkspaceDocCount(workspace);
                                end

                                % Fire event when document is closed
                                eventdata = internal.matlab.variableeditor.DocumentChangeEventData;
                                eventdata.Name = name;
                                eventdata.Workspace = workspace;
                                eventdata.Document = [];

                                try
                                    this.notify('DocumentClosed',eventdata);
                                catch e
                                    internal.matlab.datatoolsservices.logDebug("variableeditor::remoteManager::error", e.message);
                                end
                             end

                        case 'CloseAll' % This event is fired when the variable editor is closed on the client
                            this.closeAllVariables();
                    end
                catch e
                    this.sendErrorMessage(e.message);
                end
            end
        end

        function [data] = getData(~, eventObj)
            data = eventObj.data;
        end

        function [source] = getSource(~, eventObj)
            source = '';
            if isfield(eventObj, 'data') && isfield(eventObj.data.newValue, 'Source')
                source = eventObj.data.newValue.Source;
            elseif isfield(eventObj, 'originator')
                if strcmp(eventObj.srcLang, 'JS')
                    source = 'Client';
                else
                    source = 'Server';
                end
            end
        end

        % API used by the provider when a property set event is received
        % from the client
        function handlePropertySetFromClient(this, ~, eventObj)

            % some tests use structs instead of objects for eventObj,
            % so I'll check for both here rather than changing all of the
            % tests that do so
            if ~isfield(eventObj, 'data')
               return;
            end

            data = this.getData(eventObj);
            source = this.getSource(eventObj);

            if strcmpi(data.key, 'HasFocus')
                if isstruct(data.newValue)
                    this.setFocus(data.newValue.HasFocus, source);
                else
                    this.setFocus(data.newValue, source);
                end
            elseif strcmpi(data.key, 'FocusedDocument')
                this.setFocusedDocument(eventObj);
            elseif strcmpi(data.key, 'FocusedManager')
                % do nothing
            else
                % do nothing
            end
        end

        % returns the property value of the given property
        function propVal = getProperty(this, propertyName)
            propVal = this.Provider.getProperty(propertyName, this, '');
        end


        % Calls into the provider to send an event to the client
        function dispatchEventToClient(this, eventObj)
            this.Provider.dispatchEventToClient(this, eventObj, '');
        end

        % Calls into the provider to set a property on the client
        function setProperty(this, propertyName, propertyValue)
            this.Provider.setPropertyOnClient(propertyName, propertyValue, this, '');
        end

        % Given a popoutID, looks through the existing list of
        % ClonedVariableList if a corresponding popoutID is present. If Yes, this
        % entry is removed from hashMap.
        function cleanupClonedVariableList(this, popoutID)
            clonedVariables = keys(this.ClonedVariableList);
            for i = 1: length(clonedVariables)
                key = clonedVariables{i};
                if strcmp(key, popoutID)
                    remove(this.ClonedVariableList, key);
                    break;
                end
            end
        end

        % Delete
        function delete(this)
            if ~isempty(this.ActionManager) && isvalid(this.ActionManager)
                this.ActionManager.delete;
            end
            if ~isempty(this.ContextMenuProvider) && isvalid(this.ContextMenuProvider)
                contextMenuManager = internal.matlab.datatoolsservices.contextmenuservice.ContextMenuManager.getInstance();
                contextMenuManager.deleteContextMenuProvider(this.ContextMenuProvider.msgServiceChannel);
            end
            if ~isempty(this.DocFocusedListener)
              delete(this.DocFocusedListener);
            end
            if ~isempty(this.DocFocusLostListener)
              delete(this.DocFocusLostListener);
            end
            if ~isempty(this.Provider) && isvalid(this.Provider)
                delete(this.Provider);
            end
            % If there are outtsanding cloned variables (also instances of
            % RemoteManager), delete them.
            if (this.ClonedVariableList.Count > 0)
                clonedVariables = string(keys(this.ClonedVariableList));
                for i=1:length(clonedVariables)
                    clonedVarID = char(clonedVariables(i));
                    clonedVarMgr = this.ClonedVariableList(clonedVarID);
                    clonedVarMgr.closeAllVariables();
                    delete(clonedVarMgr);
                end
            end
        end
    end

    methods(Access='private')
        function callInitActionOnIdle(this, actionNamespace, startPath, classType, ActionManager)
            if ~isvalid(this)
                % Because this can be called aysnchrounously there is a
                % chance that the this object is no longer valid
                return;
            end
            if isempty(classType)
                classType = 'internal.matlab.datatoolsservices.actiondataservice.Action';
            end

            if ~isempty(ActionManager) && isvalid(ActionManager)
                ActionManager.initActions(startPath, classType);
                this.setProperty('ActionsInitialized', actionNamespace);
            end
        end

        function setFocus(this, hasFocus, source)
            if ~isvalid(this)
                return;
            end
            clientGeneratedEvent = false;
            if strcmpi('server',source)
                return;
            elseif strcmpi('client',source)
                clientGeneratedEvent = true;
            end

            if clientGeneratedEvent
                cachedDocFocusedListenerState = this.DocFocusedListener.Enabled;
                cachedDocFocusLostListenerState = this.DocFocusLostListener.Enabled;
                this.DocFocusedListener.Enabled = false;
                this.DocFocusLostListener.Enabled = false;
            end
            this.HasFocus = hasFocus;
            if clientGeneratedEvent
                this.DocFocusedListener.Enabled = cachedDocFocusedListenerState;
                this.DocFocusLostListener.Enabled = cachedDocFocusLostListenerState;
            end
        end

        function setFocusedDocument(this, eventObject)
            if ~isvalid(this) || ~isfield(eventObject, 'data') || isempty(eventObject.data.newValue)
                return;
            end
            source = this.getSource(eventObject);
            clientGeneratedEvent = false;
            if strcmp('server',source)
                return;
            elseif strcmp('client',source)
                clientGeneratedEvent = true;
            end

            if isfield(eventObject.data.newValue, 'Document')
                docId = eventObject.data.newValue.Document;
                index = this.docIdIndex(docId);
                if ~isempty(index)
                     % If the peer node property set was generated by the
                     % client, do not trigger the DocFocusedListener or DocFocusLostListener
                     % callbacks (by executing the FocusedDocument set function)
                     % which will just re-transport the same peer
                     % node property set back to the client. This should be
                     % avoided as it can cause infinite loops when the time
                     % between property changes is smaller than the transport
                     % time
                     if clientGeneratedEvent
                          cachedDocFocusedListenerState = this.DocFocusedListener.Enabled;
                          cachedDocFocusLostListenerState = this.DocFocusLostListener.Enabled;
                          this.DocFocusedListener.Enabled = false;
                          this.DocFocusLostListener.Enabled = false;
                     end
                     this.FocusedDocument = this.Documents(index);

                     % When the document comes into focus, this also puts the manager into focus
                     this.HasFocus = true;
                     if clientGeneratedEvent
                         this.DocFocusedListener.Enabled = cachedDocFocusedListenerState;
                         this.DocFocusLostListener.Enabled = cachedDocFocusLostListenerState;
                     end
                end
            end
        end

        function status = handleErrorEvent(this, ed)
            this.sendErrorMessage(getString(message(...
                    'MATLAB:codetools:variableeditor:UnsupportedProperty', ...
                    ed.EventData.key)));
                status = 'error';
        end

        function handleDocumentFocusEvent(this, ~, ed)
            % Set the Focused Document
            if ~isempty(this.FocusedDocument) && ...
                    strcmp('DocumentFocusGained', ed.EventName)
                this.setProperty('FocusedDocument', this.FocusedDocument.DocID);
            else
                this.setProperty('FocusedDocument', '');
            end
        end
    end

    methods(Static)
        function docID = getNextDocID(veVar)
            mlock; % Keep persistent variables until MATLAB exits
            persistent docIDCounter;
            if isempty(docIDCounter)
                docIDCounter = 0;
            end
            docIDCounter = docIDCounter+1;

            % g2843418: Ensure that DocID is valid as it is used to create Mf0 channels
            docID = ['_' matlab.lang.makeValidName(veVar.Name) '__' num2str(docIDCounter)];
        end
    end

    % Protected methods
    methods(Access='protected')

        % Overrides the MLManager  method
        function varDocument = addDocument(this, veVar, userContext, displayFormat)
            arguments
                this
                veVar
                userContext char = ''
                displayFormat = ''
            end
            varDocument = [];
            if ~isempty(veVar)
                docID = this.getNextDocID(veVar);
                varDocument = docID;
                this.DelayedDocumentList = [this.DelayedDocumentList struct('docID', docID, 'veVar', veVar, 'userContext', userContext, 'displayFormat', displayFormat)];
            end
        end

        function varDocument = createDocument(this, veVar, docID, documentCreationArgs)
            arguments
                this
                veVar
                docID char
                documentCreationArgs.UserContext char = ''
                documentCreationArgs.DisplayFormat = ''
            end
            args = namedargs2cell(documentCreationArgs);
            varDocument = internal.matlab.variableeditor.peer.RemoteDocument(this.Provider, this, veVar, docID, args{:});
            varDocument.IgnoreUpdates = this.IgnoreUpdates;
            varDocument.DataModel.IgnoreUpdates = this.IgnoreUpdates;
            if isprop (varDocument.DataModel, 'CodePublishing')
                varDocument.DataModel.CodePublishing = this.CodePublishing;
            end

            if this.IgnoreUpdates
                varDocument.Name = docID;
            end

            this.Documents = [this.Documents varDocument];

            % Increment the workspace document counter
            this.incrementWorkspaceDocCount(veVar.DataModel.Workspace);

            % Fire event when document is opened
            eventdata = internal.matlab.variableeditor.DocumentChangeEventData;
            eventdata.Name = varDocument.Name;
            eventdata.Workspace = veVar.DataModel.Workspace;
            eventdata.Document = varDocument;
            try
                this.notify('DocumentOpened',eventdata);
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::remoteManager::error", e.message);
            end
        end

        function delayedOpenVar(this, variable, ws, userContext, value)
            if isempty(ws)
                ws = 'debug';
            end

            if internal.matlab.datatoolsservices.VariableUtils.isCustomCharWorkspace(ws)
                % Try to see if this workspace is something that needs to
                % be evaluated
                try
                    wsKey = ws;
                    ws = eval(ws);
                    % Register workpace with the key user provided.
                    this.registerWorkspace(ws, wsKey);
                catch
                end
            end

            % Get the mapped workspace key
            workspace = this.getWorkspaceKey(ws);

            [~] = this.openvar(variable, workspace, value, UserContext=userContext);
        end

        function sendErrorMessage(this, message)
            this.Provider.dispatchEventToClient(this, struct('type','error','message',message,'source','server'));
        end

    end

    % Public Methods
    methods(Access='public')
        % Refers to the current document Ids
        function index = docIdIndex(this, docID)
            index = [];

            for i=1:length(this.Documents)
                doc = this.Documents(i);
                if strcmp(doc.DocID,docID)
                    index = i;
                    return;
                end
            end
        end

        function classname = getAdapterClassNameForData(this, varClass, varSize, data, userContext)
            arguments
                this
                varClass
                varSize
                data
                userContext char = ''
            end
            classname = this.getAdapterClassNameForData@internal.matlab.variableeditor.MLManager(varClass, varSize, data, userContext);
            classname = strrep(classname, 'internal.matlab.variableeditor.ML', 'internal.matlab.variableeditor.peer.Remote');
        end

        function doc = doDelayedDocumentCreation(this)
            % Do not turn this on in deployment mode as this function is
            % not deployable currently.
            if ~isdeployed
                warningSuppressor = matlab.internal.editor.LastWarningGuard; %#ok<NASGU>
            end
            doc = [];
            while ~isempty(this.DelayedDocumentList)
                try
                    s = this.DelayedDocumentList(1);
                    if ~isa(s.veVar, 'internal.matlab.variableeditor.VariableEditorMixin')
                        veVar = this.getVariableAdapter(s.veVar.Name, s.veVar.Workspace, s.veVar.VarClass, s.veVar.VarSize, s.veVar.Data, s.userContext);
                    else
                        veVar = s.veVar;
                    end
                    displayFormat = '';
                    if isfield(s, 'displayFormat')
                        displayFormat = s.displayFormat;
                    end
                    doc = this.createDocument(veVar, s.docID, UserContext = s.userContext, DisplayFormat = displayFormat);
                    this.DelayedDocumentList(1) = [];

                    % inititalize the actions is action manager does not exist
                    % and on creation the initActionManager object has been set
                    if (isempty(this.ActionManager) && ~isempty(this.ActionManagerInfo))
                        this.initActions([this.Provider.Channel this.ActionManagerInfo.ActionManagerNamespace], this.ActionManagerInfo.startPath);
                    end
                catch e
                    this.DelayedDocumentList(1) = [];
                    rethrow(e)
                end
            end
        end

        function doc = createSingleDeferredDocument(this, docCreationArgs)
            arguments
                this
                docCreationArgs.VarName char = ''
                docCreationArgs.DocID char = ''
                docCreationArgs.UserContext char = ''
                docCreationArgs.Workspace char = 'debug'
                docCreationArgs.DisplayFormat char = 'short'
            end
            variableData = evalin(docCreationArgs.Workspace, docCreationArgs.VarName);
            varClass = class(variableData);
            varSize = internal.matlab.datatoolsservices.FormatDataUtils.getVariableSize(variableData);
            varAdapter = this.getVariableAdapter(docCreationArgs.VarName, docCreationArgs.Workspace, varClass, varSize, variableData, docCreationArgs.UserContext);
            doc = this.createDocument(varAdapter, docCreationArgs.DocID, UserContext = docCreationArgs.UserContext, DisplayFormat = docCreationArgs.DisplayFormat);
        end

        % This will create the ActionManager alone and load with pre-defined actionClasses
        function initializeActionManager(this, actionClasses)
            arguments
                this
                actionClasses string = []
            end
            if (isempty(this.ActionManager) && ~isempty(this.ActionManagerInfo))
                actionNamespace = [this.Provider.Channel this.ActionManagerInfo.ActionManagerNamespace];
                % This will create ActionManager alone and pre-load actionClasses
                this.initActions(actionNamespace, '', 'internal.matlab.datatoolsservices.actiondataservice.Action', false, actionClasses);
            end
        end

        % This function is only for testing purpose
        function SetDelayedDocumentList(this,value)
            this.DelayedDocumentList = value;
        end

        function asyncDoDelayedDocumentCreation(this)
            imv = 'internal.matlab.variableeditor';
            openCmd = sprintf('[~] = %s.peer.VEFactory.getInstance.createManager(''%s'',%s).doDelayedDocumentCreation();', ...
                imv, this.Provider.Channel, mat2str(this.IgnoreUpdates));
            % For asyncDelayedDocCreation, do not execute command
            % synchronoysly, wait for IDLE.
            internal.matlab.datatoolsservices.executeCmd(openCmd, true);
        end

        %   openvar() opens a variable in Variable Editor either
        %                    synchronously by calling addDocument or by deferring it if
        %                    DelayDocCreation is set to true
        %   'name'           name of the workspace variable.
        %   'ws'             workspace in which the variable is present. This
        %                    defaults to 'debug' workspace. ML workspaces can be
        %                    'base'|'caller'|'debug' or a custom workspace obj.
        %   'data'           workspace variable passed in as data, if this is passed
        %                    in, we will not evaluate to populate the data
        %   'UserContext'    Optional Context in which the variable is to be opened. For e.g 'MOTW' | 'liveeditor'
        %   'DelayDocCreation' true|false to indicate whether document
        %                      creation nust be delayed or not.
        %   'DisplayFormat'  Optional DisplayFormat when provided, the
        %                    numberic data in the variable will be displayed with this
        %                    number display format.
        function varDocument = openvar(this, name, ws, data, openvarArgs)
            arguments
                this
                name char
                ws = 'debug'
                data = []
                openvarArgs.UserContext char = ''
                openvarArgs.DelayDocCreation logical = false
                openvarArgs.DisplayFormat = ''
            end
            try
                if (~istall(data) && isempty(data)) || isa(data,'internal.matlab.variableeditor.NullValueObject')
                    % NullValueObject - signals that we have to ask MATLAB for the
                    % data
                    if isempty(data) || isa(data,'internal.matlab.variableeditor.NullValueObject')
                        try
                            % For custom workspaces that are char, fetch the registered
                            % workspace before evalin.
                            if internal.matlab.datatoolsservices.VariableUtils.isCustomCharWorkspace(ws)
                                ws = this.getWorkspace(ws);
                            end
                            data = evalin(ws, name);
                        catch
                            data = internal.matlab.variableeditor.NullValueObject(name);
                        end
                    end
                end
            catch e % Handle to deleted objects might error, they will go through unsupported view.
            end

            if ~openvarArgs.DelayDocCreation
                if ~this.isVariableOpen(name, ws)
                    if useOpenCommand(data)
                        this.closeClientDocument(name);
                        evalin(ws, sprintf("openvar('%s', %s);", name, name));
                        varDocument = [];
                    else
                        varDocument = this.openvar@internal.matlab.variableeditor.MLManager(name, ws, data, UserContext=openvarArgs.UserContext, DisplayFormat=openvarArgs.DisplayFormat); %#ok<NASGU>
                        varDocument = this.doDelayedDocumentCreation();
                    end
                else
                    % If the variable is already opened, update the focused
                    % document.
                    varDocument = this.updateFocusedDocument(name, ws);
                end
            else
                varClass = class(data);
                varSize = internal.matlab.datatoolsservices.FormatDataUtils.getVariableSize(data);
                documentArgs = struct('Name', name, 'Workspace', ws, 'VarClass', varClass, 'VarSize', varSize, 'DisplayFormat', openvarArgs.DisplayFormat);
                documentArgs.Data = data;
                varDocument = this.addDocument(documentArgs, openvarArgs.UserContext, openvarArgs.DisplayFormat);
            end
        end

        function closeAllVariables(this)
            this.closeAllVariables@internal.matlab.variableeditor.MLManager();
            if ~isempty(this.Provider) && isvalid(this.Provider)
                this.Provider.deleteDocuments();
            end
            this.DelayedDocumentList = [];
        end

        function closeClientDocument(this, varName)

        % Set property on manager incase the listeners for
        % handling event from server are not setup yet
        if isempty(this.getProperty('closeClientDocument'))
            ed = struct('varName', varName);
            this.setProperty('closeClientDocument', ed);
        end
            ed = struct('varName', varName, 'type', 'closeClientDocument');
            this.dispatchEventToClient(ed);
        end

        % for testing only
        function useOpen = testUseOpenCommand(~, data)
            useOpen = useOpenCommand(data);
        end
    end
end

% NOTE: Some objects have custom openvar behavior(through dialogs) and must not go through VE Path(g2610710)
% TODO: This logic needs to be removed when we ensure all entry points go through
% the action and not manager.opnvar
function useOpen = useOpenCommand(data)
    useOpen = isa(data, 'coder.Type');
end
