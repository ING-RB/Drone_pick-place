classdef UIInspector < handle & matlab.ui.componentcontainer.ComponentContainer
    % UIInspector An embeddable inspector for app authors

    % Copyright 2020-2024 The MathWorks, Inc.


    properties(Access = {?UIInspector, ?matlab.unittest.TestCase }, Constant)
        DEFAULT_POSITION    = [20 20 300 400]
        HTMLSource          = 'toolbox/matlab/datatools/inspector/js/peer/index.html';
        DEBUGHTMLSource     = 'toolbox/matlab/datatools/inspector/js/peer/index-debug.html';
        InspectorManagerKey = '/UIInspector';
    end

    properties (Access = {?UIInspector, ?matlab.unittest.TestCase }, Transient, NonCopyable, Hidden)
        GridLayout         matlab.ui.container.GridLayout
        UIHTML             matlab.ui.control.HTML

        InspectorManager   internal.matlab.inspector.peer.PeerInspectorManager
        InspectedObjectsI

        ChannelI

        % Whether the object browser will be shown in the UIInspector or not
        ShowObjectBrowserI logical = false;

        % Whether read-only properties will be shown as labels, or as their
        % default display (typically as disabled text fields)
        UseLabelForReadOnlyI logical = false;

        % Whether to show the class name in the object browser hierarchy or not.
        % When not shown, just the property name is displayed.  Default is true,
        % to show the class name along with the property name.
        ShowClassInHierarchyI logical = true;

        % Whether to use the variable name as the top of the object browser
        % hierarchy or not.  Default is false, so that the top of the hierarchy
        % is the class name.
        UseVarNameAsHierarchyTopI logical = false;

        ErrorFcnI function_handle = function_handle.empty;

        % Whether the inspector will auto-refresh the display or not.  By
        % default the inspector will update when changes are made outside of it.
        AutoRefreshI (1,1) logical = true;

        SupportsPopupWindowEditorI (1,1) logical = true;

        ShowInspectorToolstripI (1,1) logical = true;

        CheckForRecursiveChildrenI (1,1) logical = true;
    end

    properties (Access = protected, Transient, NonCopyable, Hidden)
        DataChangeListener;
        ViewReadyListener;
        FigureThemeListener;
    end

    properties (Dependent = true)
        InspectedObjects
        Channel
        ShowObjectBrowser
        UseLabelForReadOnly
        ShowClassInHierarchy
        UseVarNameAsHierarchyTop
        ErrorFcn
        AutoRefresh
        SupportsPopupWindowEditor
        ShowInspectorToolstrip
        CheckForRecursiveChildren
    end

    properties (Access = public)
        % Callback Functions
        DataChangeFcn;

        ObjectBrowserSelectionChangeFcn;
    end

    properties (Hidden)
        Debug (1,1) logical = false
        EnableTheming (1,1) logical = false

        TopLevelObj = [];

        % Name of the object being inspected.  This is needed to support value
        % objects and structs which may show up in the Object Browser.
        ObjectName char = '';
    end

    methods
        function val = get.InspectedObjects(obj)
            val = obj.InspectedObjectsI;
        end

        function set.InspectedObjects(obj, val)
            obj.InspectedObjectsI = val;
            if ~isempty(obj.InspectorManager)
                if obj.hasNonDefaultSettings()
                    if ~isa(val, "internal.matlab.inspector.InspectorProxyMixin")
                        % Need to create the InspectorProxyMixin for the
                        % object, so its UseLabelForReadOnly can be set.
                        % If the factory doesn't return one, create the
                        % default InspectorProxyMixin
                        [proxyClass, proxyClassName] = internal.matlab.inspector.peer.InspectorFactory.getInspectorView(class(val), 'default', val);
                        if isempty(proxyClassName)
                            val = internal.matlab.inspector.DefaultInspectorProxyMixin(val);
                        else
                            val = proxyClass;
                        end
                    end
                    val.UseLabelForReadOnly = obj.UseLabelForReadOnlyI;
                    val.ShowClassInHierarchy = obj.ShowClassInHierarchyI;
                    val.UseVarNameAsHierarchyTop = obj.UseVarNameAsHierarchyTopI;
                    val.SupportsPopupWindowEditor = obj.SupportsPopupWindowEditorI;
                    val.ShowInspectorToolstrip = obj.ShowInspectorToolstripI;
                    val.CheckForRecursiveChildren = obj.CheckForRecursiveChildrenI;
                end
                % Pass topLevelObj while inspecting to maintain
                % objectHeirarchy.
                obj.InspectorManager.inspect(val, '', '', ...
                    "debug", obj.ObjectName, obj.TopLevelObj);
                if ~obj.AutoRefreshI
                    % Stop the auto-refresh
                    obj.InspectorManager.stopAutoRefresh();
                end

                % Listen to DataChange events on the viewmodel
                obj.updateListenersWhenVMChanges;
            end
        end

        function channel = get.Channel(obj)
            if ~isempty(obj.ChannelI)
                channel = obj.ChannelI;
                return;
            end

            % Generate unique uuid for uiinspector instance
            persistent uuid;
            if isempty(uuid)
                uuid = 0;
            end
            uuid = uuid + 1;

            channel = sprintf('%s%d', obj.InspectorManagerKey, uuid);
            obj.ChannelI = channel;
        end

        function val = get.ShowObjectBrowser(this)
            % Get the ShowObjectBrowser property
            val = this.ShowObjectBrowserI;
        end

        function set.ShowObjectBrowser(this, val)
            % Set the ShowObjectBrowser property
            this.ShowObjectBrowserI = val;
        end

        function val = get.UseLabelForReadOnly(this)
            % Get the UseLabelForReadOnly property
            val = this.UseLabelForReadOnlyI;
        end

        function set.UseLabelForReadOnly(this, val)
            % Set the UseLabelForReadOnly property
            this.UseLabelForReadOnlyI = val;
        end

        function val = get.ShowClassInHierarchy(this)
            val = this.ShowClassInHierarchyI;
        end

        function set.ShowClassInHierarchy(this, val)
            this.ShowClassInHierarchyI = val;
        end

        function val = get.UseVarNameAsHierarchyTop(this)
            val = this.UseVarNameAsHierarchyTopI;
        end

        function set.UseVarNameAsHierarchyTop(this, val)
            this.UseVarNameAsHierarchyTopI = val;
        end

        function val = get.SupportsPopupWindowEditor(this)
            % Get the SupportsPopupWindowEditor property
            val = this.SupportsPopupWindowEditorI;
        end

        function set.SupportsPopupWindowEditor(this, val)
            % set the SupportsPopupWindowEditor property
            this.SupportsPopupWindowEditorI = val;
        end

        function val = get.ShowInspectorToolstrip(this)
            % Get the ShowInspectorToolstrip property
            val = this.ShowInspectorToolstripI;
        end

        function set.ShowInspectorToolstrip(this, val)
            % Set the ShowInspectorToolstrip property
            this.ShowInspectorToolstripI = val;
        end

        function val = get.CheckForRecursiveChildren(this)
            % Get the CheckForRecursiveChildren property
            val = this.CheckForRecursiveChildrenI;
        end

        function set.CheckForRecursiveChildren(this, val)
            % Set the CheckForRecursiveChildren property
            this.CheckForRecursiveChildrenI = val;
        end

        function val = get.ErrorFcn(this)
            val = this.ErrorFcnI;
        end

        function set.ErrorFcn(this, val)
            this.ErrorFcnI = val;
            this.addErrorFcnToViewModel();
        end

        function val = get.AutoRefresh(this)
            % Get the AutoRefresh property
            val = this.AutoRefreshI;
        end

        function set.AutoRefresh(this, val)
            % Set the AutoRefresh property.  This can be used to stop/start the
            % updates when the UIInspector isn't visible, for example, within an
            % App.
            this.AutoRefreshI = val;

            if isempty(this.InspectorManager)
                return;
            end
            if val
                % Start the UIInspector's auto-refresh, so it will automatically
                % pick up any changes made outside of the inspector.
                this.InspectorManager.startAutoRefresh();
            else
                % Stop the UIInspector's auto-refresh, so it will not
                % automatically pick up any changes made outside of the
                % inspector.
                this.InspectorManager.stopAutoRefresh();
            end
        end
    end

    methods
        function obj = UIInspector(NameValueArgs)
            arguments
                NameValueArgs.?matlab.ui.componentcontainer.ComponentContainer

                % UIInspector Appearence
                NameValueArgs.Parent           = uifigure
                NameValueArgs.BackgroundColor  = 'white'

                % InspectedObjects
                NameValueArgs.InspectedObjects = [],

                NameValueArgs.ShowObjectBrowser (1,1) logical = false
                NameValueArgs.UseLabelForReadOnly (1,1) logical = false
                NameValueArgs.ShowClassInHierarchy (1,1) logical = true
                NameValueArgs.UseVarNameAsHierarchyTop (1,1) logical = false
                NameValueArgs.ObjectName char = ''
                NameValueArgs.AutoRefresh (1,1) logical = true
                NameValueArgs.SupportsPopupWindowEditor (1,1) logical = true
                NameValueArgs.ShowInspectorToolstrip (1,1) logical = true
                NameValueArgs.CheckForRecursiveChildren (1,1) logical = true
                NameValueArgs.Debug (1,1) logical = false
            end

            % Initialize the parent class
            obj@matlab.ui.componentcontainer.ComponentContainer(NameValueArgs);
            if ~isa(NameValueArgs.Parent, "matlab.ui.container.GridLayout") && ~isfield(NameValueArgs, "Position")
                obj.Position = matlab.internal.datatools.uicomponents.uiinspector.UIInspector.DEFAULT_POSITION;
            end

            % Initialize the UIInspector
            obj.Debug = NameValueArgs.Debug;
            obj.ObjectName = NameValueArgs.ObjectName;
            obj.setupUIHTML;
        end

        function inspect(obj, val, topLevelObj)
            arguments
                obj
                val
                topLevelObj = [];
            end
            % Takes in an optional TopLevelObject that is set as a prop on
            % inspector. For any inspect/subinspect calls, this TopLevelObj
            % is passed along.
            objectVarName = inputname(2);
            if ~isempty(objectVarName) && isempty(obj.ObjectName)
                obj.ObjectName = objectVarName;
            end
            obj.TopLevelObj = topLevelObj;
            obj.InspectedObjects = val;
        end

        % API To subinspect objects in object browser hierarchy. 
        function subInspect(obj, index)
            metaDataHandler = obj.InspectorManager.Documents.DataModel.MetaDataHandler;
            channel = obj.InspectorManager.Channel;

            try
                internal.matlab.inspector.peer.InspectorObjectActionHelper.selectChild(index, metaDataHandler, channel);
                % Set DataModel's Data to be InspectedObject on sub inspection.
    			inpsectedObj = obj.InspectorManager.Documents.ViewModel.DataModel.getData.OriginalObjects;
                obj.InspectedObjectsI = inpsectedObj;
            catch
                % Ignore errors, this can happen when objects are deleted
            end
        end

        function delete(obj)
            if ~isempty(obj.DataChangeListener)
                delete(obj.DataChangeListener);
                obj.DataChangeListener = [];
            end

            if ~isempty(obj.ViewReadyListener)
                message.unsubscribe(obj.ViewReadyListener);
                obj.ViewReadyListener = [];
            end

            if ~isempty(obj.FigureThemeListener)
                delete(obj.FigureThemeListener);
                obj.FigureThemeListener = [];
            end

            % Delete the manager if all its documents are closed.
            if ~isempty(obj.InspectorManager) && isvalid(obj.InspectorManager)
                obj.InspectorManager.clearObjectAfterClose();
                delete(obj.InspectorManager);
            end
        end

        function refresh(obj)
            % Called to refresh the UIInspector display, to pick up any changes
            % made outside the inspector since it was previously refreshed.
            % This is only needed if auto-refresh was previously set to false.
            obj.InspectorManager.refresh();
        end

        function reinspect(obj)
            % Called to force a re-inspect of the current object.
            % Sometimes clients need a way to force an update of the
            % content being displayed, this provides that functionality.
            obj.InspectorManager.reinspectCurrentObject(true);
        end
    end

    methods (Access = protected)
        function setup(obj)
            % Sets up the UIHTML containing the variable editor widget.
            obj.GridLayout = uigridlayout(obj, [1,1], 'Padding', [0,0,0,0]);
            obj.UIHTML = uihtml(obj.GridLayout);
        end

        function update(~)
        end

        function setupUIHTML(obj)
            % Get channel
            channel = obj.Channel;
            figureParent = ancestor(obj.Parent, 'figure');
            % When the theme property is not set on FigureParent, then
            % listen to ThemeChanged even and enableTheming in PI
            % accordingly
            if isempty(figureParent.Theme)
                obj.FigureThemeListener = addlistener(figureParent, 'ThemeChanged',@(e,d)obj.handleFigureThemeChangedListener(d));
            else
                % Sometimes Theme property gets set on Figure Parent even
                % before PI is initialized, in that case we assume the app
                % is supposed to be themed and enableTheming in PI
                obj.EnableTheming = true;
            end
            enableTheming = string(obj.EnableTheming);
            % Listener to view ready events from the client
            obj.ViewReadyListener = message.subscribe(channel, @(e)obj.handleViewReady(e), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);

            % Create Inspector Manager
            mgr = internal.matlab.inspector.peer.InspectorFactory.createInspector('default', channel);
            mgr.ShowCacheWarning = false;

            if obj.ShowObjectBrowserI
                % Setup the uiinspector to show the breadcrumbs and object browser
                mgr.ShowObjectBrowser = true;
                mgr.registerObjectActionCallback(@(ed, metaDataHandler) obj.objectBrowserEventHandler(ed, metaDataHandler));
            end

            mgr.inspect(obj.InspectedObjectsI);
            obj.InspectorManager = mgr;
            if ~obj.AutoRefreshI
                obj.InspectorManager.stopAutoRefresh();
            end

            % Listen to DataChange events on the viewmodel
            obj.updateListenersWhenVMChanges;

            % Launch the Inspector in UIHTML
            if obj.Debug
                baseUrl = connector.getUrl(obj.DEBUGHTMLSource);
            else
                baseUrl = connector.getUrl(obj.HTMLSource);
            end
            url = sprintf('%s&channel=%s&enableTheming=%s',baseUrl, channel, enableTheming);
            obj.UIHTML.HTMLSource =  url;
        end

        % Callback function that enables theming when figure parent enables
        % theming
        function handleFigureThemeChangedListener (obj, data)
            if ~isempty(data) && isprop(data, 'EventName') && strcmp(data.EventName, 'ThemeChanged')
                if ~obj.EnableTheming
                    obj.EnableTheming = true;
                    enableTheming = string(obj.EnableTheming);
                    channel = obj.Channel;
                    % Launch the Inspector in UIHTML
                     if obj.Debug
                        baseUrl = connector.getUrl(obj.DEBUGHTMLSource);
                    else
                        baseUrl = connector.getUrl(obj.HTMLSource);
                    end
                    url = sprintf('%s&channel=%s&enableTheming=%s',baseUrl, channel, enableTheming);
                    obj.UIHTML.HTMLSource =  url;
                end
            end
            
        end

        % Handle a view ready event from the client to reinspect
        function handleViewReady(obj, eventData)
            if ~isempty(eventData) && isfield(eventData, 'type') && strcmp(eventData.type, 'ViewReady')
                % One shot listener to make sure the ui is ready
                message.unsubscribe(obj.ViewReadyListener);
                obj.ViewReadyListener = [];

                if ~isempty(obj.InspectedObjects) && isvalid(obj.InspectedObjects)
                    % pass TopLevelObj to inspect, else any subinspected
                    % object will be reinspected and ObjectBrowser will be lost.
                    obj.inspect(obj.InspectedObjects, obj.TopLevelObj);

                    obj.updateListenersWhenVMChanges;
                end
            end
        end

        function updateListenersWhenVMChanges(obj)
            % Update listeners and other properties of the ViewModel when it
            % changes.  This needs to be done using dtcallback, because other
            % updates in the inspector use this, and without it, we could be
            % updating the old ViewModel before it is swapped with the new one.

            function localUpdate(obj)
                if isvalid(obj)
                    if ~isempty(obj.DataChangeListener)
                        delete(obj.DataChangeListener)
                    end
                    % Listen to DataChange events on the viewmodel
                    obj.DataChangeListener = addlistener(obj.InspectorManager.Documents.ViewModel, 'DataChange', @(es,ed)obj.handleDataChange(ed));

                    obj.addErrorFcnToViewModel();
                end
            end

            execImmediately = internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle;
            if execImmediately
                localUpdate(obj);
            else
                builtin('_dtcallback', @() localUpdate(obj));
            end
        end

        function addErrorFcnToViewModel(obj)
            if ~isempty(obj.ErrorFcnI) && ~isempty(obj.InspectorManager)
                % ErrorFcn is set.  Wrap it in an anonymous function to add in
                % the UIInspector as the source
                obj.InspectorManager.Documents.ViewModel.ErrorFcn = @(ed) obj.ErrorFcnI(obj, ed);
            end
        end

        % This method is called when the data inspected is changed
        function handleDataChange(obj, eventData)
            if ~isempty(obj.DataChangeFcn)
                try
                    obj.DataChangeFcn(obj, eventData);
                catch e
                    disp(e);
                end
            end
        end

        function b = hasNonDefaultSettings(obj)
            b = obj.UseLabelForReadOnlyI || ...
                ~obj.ShowClassInHierarchyI || ...
                obj.UseVarNameAsHierarchyTopI || ...
                ~obj.SupportsPopupWindowEditorI || ...
                ~obj.ShowInspectorToolstripI || ...
                ~obj.CheckForRecursiveChildren;
        end
    end

    methods(Hidden)
        function objectBrowserEventHandler(obj, ed, metaDataHandler)
            % Callback function for object browser selections and actions. This
            % wraps the helper function that would typically be called by the
            % inspector, so that the uiinspector's DataChangeListener can be
            % updated for the new object being inspected.
            internal.matlab.inspector.peer.InspectorActionHelper.actionEventHandler(ed, metaDataHandler);
            obj.updateListenersWhenVMChanges();
            if strcmp(ed.actionType, 'objectSelectionChanged') && ~isempty(obj.ObjectBrowserSelectionChangeFcn)
                try
                    s = struct('SelectedIndices', ed.affectedNodes);
                    s.SelectedObjects = obj.InspectorManager.Documents.ViewModel.DataModel.getData.OriginalObjects;
                    obj.ObjectBrowserSelectionChangeFcn(obj, s);
                catch
                end
            end
        end
    end
end
