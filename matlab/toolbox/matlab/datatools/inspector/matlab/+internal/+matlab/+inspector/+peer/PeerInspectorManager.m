classdef PeerInspectorManager < internal.matlab.inspector.Inspector & ...
        internal.matlab.variableeditor.peer.RemoteManager
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Peer Inspector Manager class, extends the Inspector and Peer Manager
    % classes
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    events
        InspectorPropertyAdded
        InspectorPropertyRemoved
        ViewReady
        PropertyEdited
        PropertyChanging
        EditorHoveredOver
    end
    
    properties(Access = private)
        % Unique ID of the object currently being inspected
        objID;
        ObjectActionCallback;
        propertyRemovedListener = [];
        propertyAddedListener = [];
        propertyUpdatedListener = [];
        propertyEditedListener = [];
        viewReady = false;
        viewReadyListeners = event.listener.empty;
        subScriptions = {};
    end

    properties(Hidden)
        % Whether to show the Inspector's cache out of date warning if this is
        % the inspector which was created.  By default this is true, but some
        % App usage may not use the cache content, and so it doesn't make sense
        % to show the warning.  These can set this to false.
        ShowCacheWarning (1,1) logical = true;
    end

    methods
        % Constructor, creates a PeerInspectorManager for the application
        % and channel
        function this = PeerInspectorManager(application, provider)
            this@internal.matlab.variableeditor.peer.RemoteManager(...
                provider, false);
            this@internal.matlab.inspector.Inspector(application, provider.Channel);
            this.subScriptions{end+1} = message.subscribe(provider.Channel, @(evt) this.handleMessage(evt), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.subScriptions{end+1} = message.subscribe(provider.Channel, @(evt) this.handleViewReady(evt), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
        end
        

        function handleViewReady(this, event)
            % ViewReady handler to allow for queuing callbacks that
            % require the ViewReady event to have been fired (such as
            % showObjectBrowser)
            if isfield(event,'type') && event.type == "ViewReady"
                this.viewReady = true;
                notify(this,"ViewReady");
                this.viewReadyListeners = [];
            end
        end

        function handleMessage(this, event)
            if isfield(event, "name")
                switch(event.name)
                    case "setData"
                        this.Documents.ViewModel.clientSetData(event.data);
                    case "actionEvent"
                        this.Documents.ViewModel.handleActionEvent(event.data);
                    case "propertyValueChanging"
                        internal.matlab.datatoolsservices.logDebug("pi", ...
                            "propertyValueChanging, property name: " + event.data.property + ", value: " + event.data.value);
                    case "editorHoveredOver"
                        if event.data.value
                            internal.matlab.datatoolsservices.logDebug("pi", ...
                                "editorHoveredOver start, property name: " + event.data.property + ", value: " + event.data.value);
                        else
                            internal.matlab.datatoolsservices.logDebug("pi", ...
                                "editorHoveredOver end, property name: " + event.data.property + ", value: " + event.data.value);
                        end
                end
            end
        end

        function addViewReadyListener(this, callback)
            % If a ViewReady event has fired, call the callback
            % synchronously
            if this.viewReady
                feval(callback, this, []);
            else
                % Otherwise add the callback as a listener to a "ViewReady"
                % event
                this.viewReadyListeners = [this.viewReadyListeners;
                    event.listener(this,"ViewReady",callback)];
            end
        end

        function showObjectBrowser(this)
            % Show the Object Browser or wait until the first ViewReady and
            % then show it
            this.addViewReadyListener(@(h, ~) h.Documents.ViewModel.showObjectBrowser);
        end
        
        function veVar = getVariableAdapter(this, name, ws, varClass, ...
                varSize, data, ~)
            % Returns a PeerInspectorAdapter class for the object being
            % inspected
            veVar = this.getVariableAdapter@internal.matlab.inspector.Inspector(...
                name, ws, varClass, varSize, data);
            if ~isa(veVar, 'internal.matlab.inspector.peer.PeerInspectorAdapter')
                this.Adapter = internal.matlab.inspector.peer.PeerInspectorAdapter(...
                    veVar.DataModel.Name, veVar.DataModel.Workspace, ...
                    veVar.DataModel, veVar.ViewModel);
                veVar = this.Adapter;
                
                if ~isempty(this.propertyRemovedListener)
                    delete(this.propertyRemovedListener);
                    delete(this.propertyAddedListener);
                    delete(this.propertyUpdatedListener);
                end
                
                this.propertyRemovedListener = event.listener(...
                    veVar.DataModel, 'PropertyRemoved', ...
                    @(es,ed) this.handlePropertyRemoved(es, ed));
                this.propertyAddedListener = event.listener(...
                    veVar.DataModel, 'PropertyAdded', ...
                    @(es,ed) this.handlePropertyAdded(es, ed));
                this.propertyUpdatedListener = event.listener(...
                    veVar.DataModel, 'PropertiesUpdated', ...
                    @(es,ed) this.handlePropertiesUpdated(es, ed));

          
            end
        end
        
        function handleEventFromClient(this, ~, ed)
            % Handles peer events coming from the client
            if isfield(ed.EventData, 'source') && ...
                    strcmp('server', ed.EventData.source)
                % Ignore any events generated by the server
                return;
            end
            if isfield(ed.EventData, 'type')
                % Determine the object name, server eval function,
                % class name and workspaceID, if they are set.
                [objectName, serverEvalFcn, className, workspaceID] = ...
                    this.getDataFromEvent(ed.EventData);

                try
                    switch ed.EventData.type
                        case 'inspect'
                            % Called to inspect an object.  Need to look
                            % through the properties to see how the object
                            % is being specified.
                            if ~isempty(workspaceID)
                                workspace = this.getWorkspace(workspaceID);
                            else
                                workspace = 'debug';
                            end
                            
                            % Set the objID used for the object
                            % currently being inspected
                            this.objID = this.getUniqueID(workspaceID, ...
                                serverEvalFcn);
                            %disp(['Key: ' this.objID])
                            
                            if ~ischar(workspace) || ...
                                    strcmp(workspace, 'base')
                                % Attempt to get a handle
                                obj = [];
                                if ~isempty(objectName)
                                    obj = evalin(workspace, objectName);
                                elseif ~isempty(serverEvalFcn)
                                    obj = evalin(workspace, serverEvalFcn);
                                elseif ~isempty(className)
                                    obj = evalin(workspace, className);
                                end
                                
                                if ~isempty(obj)
                                    this.inspect(obj);
                                end
                            else
                                if isempty(objectName)
                                    if ~isempty(serverEvalFcn)
                                        objectName = serverEvalFcn;
                                    elseif ~isempty(className)
                                        objectName = className;
                                    end
                                end
                                this.showInspector(objectName);
                            end
                            
                        case 'undo'
                            % Get the UndoQueue for this object
                            undoQueue = this.getUndoRedoQueueForObject(...
                                workspaceID, serverEvalFcn);
                            
                            % Perform the Undo
                            undoQueue.undo();

                        case 'redo'
                            % Get the UndoQueue for this object
                            undoQueue = this.getUndoRedoQueueForObject(...
                                workspaceID, serverEvalFcn);
                            
                            
                            % Perform the Redo
                            undoQueue.redo();

                        case 'updateObjectPropertyValue'
                            % Called to update an object's property value.
                            % Expects the object name, property and value
                            % to set.  The value is set asynchronously via
                            % Java.
                            
                            objectName = [];
                            serverEvalFcn = [];
                            className = [];
                            property = '';
                            value = [];

                            if isfield(ed.EventData, 'objectName')
                                % Object name is set
                                objectName = ed.EventData.objectName;
                            end
                            
                            if isfield(ed.EventData, 'property')
                                % Property name is set
                                property = ed.EventData.property;
                            end
                            
                            if isfield(ed.EventData, 'value')
                                % Value is set
                                value = ed.EventData.value;
                            end
                            
                            if isfield(ed.EventData, 'className')
                                % Application class name is specified
                                className = ed.EventData.className;
                            end
                            
                            if ~isempty(workspaceID)
                                workspace = this.getWorkspace(workspaceID);
                            else
                                workspace = 'debug';
                            end
                            
                            if ~ischar(workspace) || ...
                                    strcmp(workspace, 'base')
                                % Attempt to get a handle
                                obj = [];
                                if ~isempty(objectName)
                                    obj = evalin(workspace, objectName);
                                elseif ~isempty(serverEvalFcn)
                                    obj = evalin(workspace, serverEvalFcn);
                                elseif ~isempty(className)
                                    obj = evalin(workspace, className);
                                end
                                
                                if ~isempty(obj)
                                    this.setOfflinePropertyValue(obj, property, value);
                                end
                            else
                                if isempty(objectName)
                                    if ~isempty(serverEvalFcn)
                                        objectName = serverEvalFcn;
                                    elseif ~isempty(className)
                                        objectName = className;
                                    end
                                end
                                
                                % Called to show the Property Inspector for the given object
                                cmd = sprintf(...
                                    'setOfflinePropertyValue(internal.matlab.inspector.peer.InspectorFactory.createInspector(''%s'',''%s''), %s, ''%s'', ''%s'');', ...
                                    this.Application, this.InspectorID, objectName, property, regexprep(value, '['']{1,1}',''''''));
                                this.executeCommand(cmd);
                            end
                        otherwise
                            this.handleEventFromClient@internal.matlab.variableeditor.peer.RemoteManager([], ed);
                    end
                catch e
                    this.sendErrorMessage(e.message);
                end
            end
        end
        
        function registerObjectActionCallback(this, cb)
            % Registers an object selection action function.  The inspector JS
            % client may generate events related to the object selection/deletion -- this
            % allows instances of the inspector to register what to do when
            % those events are fired.
            this.ObjectActionCallback = cb;
        end
        
        function [canCache, cacheID] = canBeCachedInProxyMaps(~, objects)
            % We currently only store graphics objects, because these have a
            % unique key (by calling their double() method.  Also only store
            % scalar objects for now.  Returns logical canCache which is true
            % if the object can be cached, and returns the cacheID to use as well.
            canCache = ~isjava(objects) && isscalar(objects) && all(ishghandle(objects));
            cacheID = [];

            if canCache
                try
                    cacheID = double(objects);
                    if isnan(cacheID) || ~isscalar(cacheID)
                        canCache = false;
                        cacheID = [];
                    end
                catch
                    canCache = false;
                end
            end
        end
        
        % Called to inspect an object or array of objects.  If the
        % workspace is not provided, it defaults to caller.  name is
        % optional, and is required only for non-handle (value) objects.
        % Returns the Document if an output argument is specified.
        function varargout = inspect(this, objects, ...
                multiplePropertyCombinationMode, ...
                multipleValueCombinationMode, ws, name, parentObject, childIndex)
            % Reset the viewReady state when a new object is inspected
            this.viewReady = false;
            if nargin < 2 || isempty(objects)
                objects = internal.matlab.inspector.EmptyObject;
            end
            
            % Setup MultiplePropertyCombinationMode
            if nargin < 3 || isempty(multiplePropertyCombinationMode)
                multiplePropertyCombinationMode = '';
            end
            
            % Setup MultipleValueCombinationMode
            if nargin < 4 || isempty(multipleValueCombinationMode)
                multipleValueCombinationMode = '';
            end
            
            if nargin < 5 || isempty(ws)
                ws = '';
            end
            
            if nargin < 6 || isempty(name)
                name = '';
            else
                le = lasterror;
                try
                    % If we have a name, see if it exists in the base workspace.
                    % If it does, additional editing capabilities will be made
                    % available.
                    evalVar = evalin('base', name);
                    if isequal(evalVar, objects)
                        ws = 'base';
                    end
                catch
                end
                lasterror(le);
            end
            
            if nargin < 7
                parentObject = [];
            end
            if nargin < 8
                childIndex = NaN;
            end
            
            if ~isa(objects, 'internal.matlab.inspector.InspectorProxyMixin')
                [canBeCached, cacheID] = canBeCachedInProxyMaps(this, objects);
                objs = [];
                if canBeCached && isKey(this.ProxyMaps, cacheID)
                    % If this object exists in the ProxyMaps map, then reuse it
                    objs = this.ProxyMaps(cacheID);
                end
                
                if isempty(objs) || ~isvalid(objs) || ~isvalid(objs.OriginalObjects)
                    className = class(objects);
                    [objs, proxyViewClass] = internal.matlab.inspector.peer.InspectorFactory.getInspectorView(...
                        className, this.Application, objects, name);
                    if ~isempty(proxyViewClass)
                        if canBeCached
                            % Store the object in the ProxyMaps map.  
                            this.ProxyMaps(cacheID) = objs;
                        end
                    else
                        objs = objects;
                    end
                end
            else 
                objs = objects;
            end
            
            % Delete the old ProxyMixin object before inspecting a new object if
            % it wasn't previously stored in the ProxyMaps map.
            if ~isempty(this.Documents) && isempty(parentObject)
                dmData = this.Documents.DataModel.getData;
                if ~isempty(dmData) && isa(dmData,  'internal.matlab.inspector.InspectorProxyMixin') && ...
                    isvalid(dmData) && ~canBeCachedInProxyMaps(this, dmData.OriginalObjects) && ...
                    ~isequal(dmData, objects)
                    delete(this.Documents.DataModel.getData);
                end
            end
            peerInspectorDocument = this.inspect@internal.matlab.inspector.Inspector(objs, ...
                multiplePropertyCombinationMode, ...
                multipleValueCombinationMode, ws, name, parentObject, childIndex);
            if isempty(peerInspectorDocument)
                varargout{1} = [];
            else
                % Retrieve the UndoQueue associated with this object, and
                % set it on the ViewModel.  It will be created by the
                % UndoService if it hasn't been created yet.
                if isempty(this.objID) || isequal(this.objID, 'base')
                    this.objID = this.getUniqueID(ws, []);
                end
                uniqueID = this.objID;
                
                try
                    undoService = internal.matlab.inspector.InspectorUndoService.getInstance;
                    undoQueue = undoService.getUndoQueue(uniqueID);
                    peerInspectorDocument.ViewModel.UndoQueue = undoQueue;
                catch
                end
                peerInspectorDocument.ViewModel.ObjectActionCallback = this.ObjectActionCallback;
                varargout{1} = peerInspectorDocument;

                this.propertyEditedListener = event.listener(peerInspectorDocument.ViewModel, 'PropertyEdited', ...
                    @(e,d)this.handlePropertyEdited(e,d));
            end
        end

        function reinspect(this, objects, ...
                multiplePropertyCombinationMode, ...
                multipleValueCombinationMode, ws, name)
            
            % Called to reinspect an object.  This is called for the desktop
            % inspector when it is reopened after it has been closed.  
            arguments
                this
                objects = this.Documents.ViewModel.DataModel.getData
                multiplePropertyCombinationMode = this.MultiplePropertyCombinationMode
                multipleValueCombinationMode = this.MultipleValueCombinationMode
                ws = this.Documents.ViewModel.DataModel.VariableWorkspace
                name = this.Documents.ViewModel.DataModel.VariableName
            end
            
            useTimer = this.useTimerForObjects(objects);
            if useTimer && strcmp(this.Channel, this.DEFAULT_INSPECTOR_ID)
                % For objects which use the timer for checking for updates, just
                % restart the timer (to resolve any differences between when the
                % inspector was closed and reopened).  If not, the object will
                % just be inspected again.  Restarting the timer is quicker than
                % reinspecting (the timer is stopped when the desktop inspector
                % is closed)
                if ~this.Documents.ViewModel.DataModel.isTimerRunning
                    this.Documents.ViewModel.DataModel.restartTimer();
                end
            else
                this.inspect(objects, multiplePropertyCombinationMode, ...
                    multipleValueCombinationMode, ws, name);
            end
        end
        
        function reinspectCurrentObject(this, forceUpdate)

            % Called to reinspect the currently inspected object.  This is
            % called when the inspector HTML is refreshed.

            arguments
                this

                forceUpdate (1,1) logical = false;
            end

            % Get all of the current settings for the inspected object
            vm = this.Documents.ViewModel;
            dm = vm.DataModel;
            objects = dm.getData;
            errorFcn = [];

            function localReinspect(this)
                try
                    % Call inspect again with the same object/settings
                    this.inspect(objects, multiplePropertyCombinationMode, ...
                        multipleValueCombinationMode, ws, name, topLevelObj);
                    if ~isempty(errorFcn)
                        % Reassign the ErrorFcn callback if it was previously set
                        this.Documents.ViewModel.ErrorFcn = errorFcn;
                    end
                catch
                    % Since this is deferred it is possible that the inspector
                    % closes/etc
                end
            end

            if isvalid(objects) && all(isvalid(objects.OriginalObjects))
                multiplePropertyCombinationMode = this.MultiplePropertyCombinationMode;
                multipleValueCombinationMode = this.MultipleValueCombinationMode;
                ws = dm.VariableWorkspace;
                name = dm.VariableName;
                topLevelObj = this.getTopLevelObjFromDM(dm);
                errorFcn = vm.ErrorFcn;

                if (forceUpdate)
                    remove(objects.ObjRenderedData, keys(objects.ObjRenderedData));
                    remove(objects.ObjectViewMap, keys(objects.ObjectViewMap));
                end

                execImmediately = internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle;
                if execImmediately
                    localReinspect(this);
                else
                    builtin('_dtcallback', @() localReinspect(this));
                end
            end
        end
        
        % Called to inspect a sub-object of an object hierarchy.  For example,
        % if you have an object T, with a property Prop1, whose value is an
        % object, and you are inspecting T.Prop1, then argument 'objects' is
        % T.prop1, while parentObject is T.
        %
        % This is useful to maintain the object browser display when the
        % inspector is already open, and the user is selecting objects in the
        % breadcrumbs or object browser tree data.
        function subObjectInspect(this, objects, ...
                multiplePropertyCombinationMode, ...
                multipleValueCombinationMode, ws, name, parentObject, childIndex)

            function subInspect(this)
                try
                    this.inspect(objects, multiplePropertyCombinationMode, ...
                        multipleValueCombinationMode, ws, name, parentObject, childIndex);
                catch
                    % Since this is deferred it is possible that the inspector
                    % closes/etc
                end
            end

            execImmediately = internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle;
            if execImmediately
                subInspect(this);
            else
                builtin('_dtcallback', @() subInspect(this));
            end
        end

        function setOfflinePropertyValue(this, objects, property, value)
            % Called to set the offline property value of an object.
            if nargin < 2 || isempty(objects)
                objects = internal.matlab.inspector.EmptyObject;
            end
            
            try
                className = class(objects);
                [objs, proxyViewClass] = internal.matlab.inspector.peer.InspectorFactory.getInspectorView(className, this.Application, objects);
                oldValue = [];
                hasProxy = false;
                if ~isempty(proxyViewClass)
                    hasProxy = true;
                else
                    objs = objects;
                end
                
                m = metaclass(objs);
                p = m.PropertyList(strcmp(property, {m.PropertyList.Name}));
                dataType = p.Type.Name;
                                
                isEnumeration = false;
                if isobject(objs.(property))
                    [~, values] = enumeration(objs.(property));
                    isEnumeration = ~isempty(values);
                elseif isa(p.Type, 'meta.EnumeratedType')
                    isEnumeration = true;
                end
                
                % Need to get the value from the client-side JSON string
                s = jsondecode(value);
                value = s.value;

                widgetRegistry = internal.matlab.datatoolsservices.WidgetRegistry.getInstance;
                if ~isempty(this.Documents)
                    widgets = widgetRegistry.getWidgets(class(this.Documents.ViewModel), dataType);
                else
                    widgets = widgetRegistry.getWidgets('internal.matlab.inspector.peer.PeerInspectorViewModel', dataType);
                end
                
                if ~isempty(widgets)
                    if (isa(dataType, 'meta.EnumeratedType') || ...
                            iscategorical(objs.(property)) || ...
                            isEnumeration)
                        if ~isempty(this.Documents)
                            widgets = widgetRegistry.getWidgets(class(this.Documents.ViewModel), 'categorical');
                        else
                            widgets = widgetRegistry.getWidgets('internal.matlab.inspector.peer.PeerInspectorViewModel', 'categorical');
                        end
                    end
                end
                
                % The following sections are similar to
                % PeerInspectorViewModel.  This will be refactored to use a
                % common method.
                if ~isempty(widgets) && ~isempty(widgets.EditorConverter)
                    converter = eval(widgets.EditorConverter);
                    converter.setClientValue(value);
                    value = converter.getServerValue();
                    if ~ischar(value)
                        value = mat2str(value);
                    else
                        isCellText = startsWith(value, '{') && endsWith(value, '}');
                        hasSingleQuotes = startsWith(value, '''') && endsWith(value, '''');
                        if ~isCellText && ~hasSingleQuotes
                            value = mat2str(value);
                        end
                    end
                end
                
                if isEnumeration && ischar(value)
                    value = strrep(value, '''', '');
                    L = lasterror; %#ok<*LERR>
                    try
                        % Try to convert to actual enumeration if possible,
                        % but if not, just use the string representation
                        value = eval([dataType '.' value]);
                    catch
                    end
                    lasterror(L);
                end
                
                if hasProxy
                    set(objs, property, value);
                else
                    objs.(property) = value;
                end
                
                this.Provider.dispatchEventToClient(this, struct(...
                    'type', 'dataChangeStatus', ...
                    'source', 'server', ...
                    'property', property, ...
                    'oldValue', oldValue, ...
                    'newValue', value, ...
                    'status', 'success'));
            catch e
                this.Provider.dispatchEventToClient(this, struct(...
                    'type', 'dataChangeStatus', ...
                    'source', 'server', ...
                    'property', property, ...
                    'oldValue', oldValue, ...
                    'newValue', value, ...
                    'status', 'error', ...
                    'message', e.message));
                this.sendErrorMessage(e.message);
            end
        end
        
        function clearObj = clearObjectAfterClose(this)
            % Clears out the object being inspected after the inspector is
            % closed, based on some criteria.  In general, the proxy object
            % created for graphics objects are not deleted, while for
            % non-graphics objects it is.  This prevents the inspector from
            % keeping a reference around to an object (through the proxy object)
            clearObj = false;
            if ~isempty(this.Documents)
                dmData = this.Documents.DataModel.getData;
                if ~isempty(dmData) && isa(dmData,  'internal.matlab.inspector.InspectorProxyMixin') && ...
                    isvalid(dmData) && ~canBeCachedInProxyMaps(this, dmData.OriginalObjects)

                    % Delete just the DataModel's data, which is the proxy
                    % object that the inspector is using to inspect the actual
                    % object.  By deleting the proxy object, we remove the
                    % inspector's reference to the actual object.
                    delete(this.Documents.DataModel.getData);
                    clearObj = true;
                end
            end

            % Check if there are any open Popup Variable Editors -- and if there
            % are, close them.
            f = findobjinternal(0, "Type", "figure", "UserData", this.Channel);
            delete(f);
        end

        function delete(this)
            for k=1:length(this.subScriptions)
                message.unsubscribe(this.subScriptions{k});
            end
        end
    end
    
    methods(Access = protected)
        function showInspector(this, objectName)
            % Called to show the Property Inspector for the given object
            cmd = sprintf(...
                'inspect(internal.matlab.inspector.peer.InspectorFactory.createInspector(''%s'',''%s''), %s);', ...
                this.Application, this.InspectorID, objectName);
            this.executeCommand(cmd);
        end
        
        function executeCommand(~, cmd)
            % Called to asynchronously execute a command in the base
            % workspace, using the Java WebWorker
            internal.matlab.datatoolsservices.executeCmd(cmd, false);
        end
        
        function varDocument = addDocument(this, veVar, userContext, ~)
            % Overrides the MLManager addDocument method in order to
            % create a PeerInspectorDocument
            varDocument = [];
            if ~isempty(veVar)
                docID = this.getNextDocID(veVar);
                varDocument = docID;                
                this.DelayedDocumentList = [this.DelayedDocumentList struct('docID', docID, 'veVar', veVar, 'userContext', userContext)];
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
            varDocument = ...
                internal.matlab.inspector.peer.PeerInspectorDocument(...
                    this.Provider, this, veVar, docID, args{:});
            varDocument.DataModel.IgnoreUpdates = this.IgnoreUpdates;

            if this.IgnoreUpdates
                varDocument.Name = ...
                    varDocument.PeerNode.getProperty('docID');
            end

            this.Documents = [this.Documents varDocument];
        end
        
        % Initialize the object name, server eval function, class name
        % and workspace ID from the information in the eventData.
        % eventData is a struct which may contain fields for the
        % values.
        function [objectName, serverEvalFcn, className, workspaceID] = getDataFromEvent(~, eventData)
            objectName = [];
            serverEvalFcn = [];
            className = [];
            workspaceID = [];

            if isfield(eventData, 'objectName')
                % Object name is set
                objectName = eventData.objectName;
            end
            
            if isfield(eventData, 'workspaceID')
                % Object workspaceID is specified.  This can be a
                % workspace name ('base', for example), or an ID to a
                % MLWorkspace workspace-like object.
                workspaceID = eventData.workspaceID;
            end
            
            if isfield(eventData, 'className')
                % Application class name is specified
                className = eventData.className;
            end
            
            if isfield(eventData, 'serverEvalFcn')
                % Server eval function is specified.  This allows the
                % client to pass a function to evaluate on the server
                % to get the object to inspect
                serverEvalFcn = eventData.serverEvalFcn;
            end
        end

        % Returns a unique ID for an object, based on its workspace
        % ID, server eval function, Application name, and Inspector ID.
        % This ID will be used within the undo/redo service.  The
        % workspaceID and serverEvalFcn will be used, if they are set.
        % Otherwise, the Inspector Application name and ID will be used.
        function id = getUniqueID(this, workspaceID, serverEvalFcn)
            id = "";
            
            % If it is set, use the serverEvalFcn
            if ~isempty(serverEvalFcn)
                id = id + serverEvalFcn;
            end
            
            % If it is set, also use the workspaceID
            if ~isempty(workspaceID)
                id = id + workspaceID;
            end

            % If we have no ID yet, add in the Application and inspector ID
            if strlength(id) == 0
                id = id + this.Application + this.InspectorID;
            end
            
            % Return a char, as the ID is used as a key in a map
            id = char(id);
        end
        
        % Finds the UndoQueue for the given object, using the
        % UndoService
        function undoQueue= getUndoRedoQueueForObject(this, workspaceID, ...
                serverEvalFcn)
            % Determine the unique ID for this object
            uniqueID = this.getUniqueID(workspaceID, serverEvalFcn);
            %disp(['Key: ' uniqueID])

            % Get its UndoQueue from the UndoService
            undoService = internal.matlab.inspector.InspectorUndoService.getInstance;
            undoQueue = undoService.getUndoQueue(uniqueID);
        end
        
        function handlePropertyAdded(this, ~, ed)
            skipUpdate = false;
            try
                obj = ed.Source.getData;
                if isa(obj, "internal.matlab.inspector.ProxyAddPropMixin") && obj.BulkPropertyChange
                    % Skip individual property adds/deletes because a bulk change is taking place
                    skipUpdate = true;
                end
            catch
            end

            if ~skipUpdate
                this.reinspectAndNotify('InspectorPropertyAdded', ed);
            end
        end

        function handlePropertyRemoved(this, ~, ed)
            skipUpdate = false;
            try
                obj = ed.Source.getData;
                if isa(obj, "internal.matlab.inspector.ProxyAddPropMixin") && obj.BulkPropertyChange
                    % Skip individual property adds/deletes because a bulk change is taking place
                    skipUpdate = true;
                end
            catch
            end

            if ~skipUpdate
                this.reinspectAndNotify('InspectorPropertyRemoved', ed);
            end
        end
        
        function handlePropertiesUpdated(this, ~, ~)
            this.reinspectAndNotify([], []);
        end

        function handlePropertyEdited(this,~,ed)
            this.notify('PropertyEdited',ed);
        end

        function reinspectAndNotify(this, evt, ed)
            % Reinspect the object, and send the event for the properties which
            % are added or removed
            dm = this.Adapter.getDataModel;

            % Save the ErrorFcn so it can be reassigned in the new ViewModel
            % which is created
            errFcn = this.Adapter.getViewModel.ErrorFcn;

            data = dm.getData;
            data.recreateUserRichEditorUI();
            
            ws = dm.VariableWorkspace;
            name = dm.Name;
            multiplePropertyCombinationMode = this.MultiplePropertyCombinationMode;
            multipleValueCombinationMode = this.MultipleValueCombinationMode;
            topLevelObj = this.getTopLevelObjFromDM(dm);

            this.Adapter.getViewModel.handleFocusLost();

            function localReinspect(this)
                try
                    this.inspect(data, multiplePropertyCombinationMode, ...
                        multipleValueCombinationMode, ws, name, topLevelObj);

                    if ~isempty(errFcn)
                        % If the ErrorFcn was set previously, need to reassign it
                        vm = this.Adapter.getViewModel;
                        vm.ErrorFcn = errFcn;
                    end

                    if ~isempty(evt)
                        e = internal.matlab.variableeditor.PropertyChangeEventData;

                        % Property name comes from the event source, which is the
                        % metaclass data for the property. Property value can be
                        % retrieved by getting the property from the affected source in
                        % the event data
                        e.Properties = ed.Properties;
                        e.Values = ed.Values;
                        this.notify(evt, e);
                    end
                catch
                    % Since this is deferred it is possible that the inspector
                    % closes/etc
                end
            end

            execImmediately = internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle;
            if execImmediately
                localReinspect(this);
            else
                builtin('_dtcallback', @() localReinspect(this));
            end
        end

        function topLevelObj = getTopLevelObjFromDM(~, dm)
            % On reinspection, if a topLevel obj exists, pass that in
            % as parentObj.
            metaDataHandler = dm.MetaDataHandler;
            topLevelObj = [];
            if isa(metaDataHandler, "internal.matlab.inspector.ObjectHierarchyMetaData")
                topLevelObj = internal.matlab.inspector.peer.InspectorObjectActionHelper.getTopLevelObjFromProxy(metaDataHandler);
            end
        end
    end
end
