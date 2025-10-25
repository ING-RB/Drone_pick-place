classdef HwmgrWindow < matlabshared.mediator.internal.Publisher &...
        matlabshared.mediator.internal.Subscriber & ...
        matlab.hwmgr.internal.MessageLogger
    % HWMGRWINDOW - This class wraps matlab.ui.container.internal.AppContainer
    % for use by Hardware Manager as the application window interface. All
    % appcontainer related operations are done through this HwmgrWindow class.

    % Copyright 2016-2024 The MathWorks, Inc.

    properties(Constant)
        %WINDOWTITLE - Name used to identify the application. Localized
        %since this is user visible.
        WindowTitle

        %MAX_NUM_GALLERY_ITEMS - Number of non enumerable device gallery
        %items shown un-popped
        MAX_NUM_GALLERY_ITEMS = 3;

        %DEFAULTDEVLISTWIDTH - Default width of the device list on window launch
        DefaultDevListWidth = 245;
    end

    properties(Access='public')
        %APPCONTAINER - Handle to the AppContainer object that serves as
        %the main application container for the Hardware Manager app
        AppContainer

        % STATUSBAR - Handle to the AppContainer Status Bar
        StatusBar

        %TABGROUP - Hardware Manager TabGroup
        TabGroup

        %FRAMEWORKHANDLE - Handle to the Hardware Manager framework
        FrameworkHandle

        Context

        % IDs to be passed to Device List Panel module for
        % communication channel
        RunningAppClientId
        StartPageClientId
    end

    properties (SetObservable)
        % Run the following command to see listeners for these properties:
        % matlab.hwmgr.internal.util.displayPropListeners('matlab.hwmgr.internal.HwmgrWindow');
        CanCloseHwmgrWindowRequest
        CanCloseAppletDocRequest
        CanRefreshRequest
        UserClosingHwmgr
        UserClosingAppletDoc
        UserRefreshingHwmgr
        DeviceForDocRequest
        DocumentSelected
        NewFigDocReady
        AddDeviceHelpDocumentReady
        AddDeviceFigDocReady
        AddNoDevicesMsgToDoc
        MainTsTabResponse
        AddDeviceListPanelReady
        WindowInitialized
        WebAppDocReady
        DialogParentResponse
        RequestRunningAppClientId
        RequestStartPageClientId
    end

    properties (Access = public)
        CanCloseResponse = true;
        DeviceForSelectedDocument
        SuspendClose = false;
    end

    properties(Access={?matlab.hwmgr.internal.HwmgrWindow})
        ProtocolGalleryButton
        CurrentTitle
        RefreshButtonCallbackFcn
        Listeners
        SelectedViewCallback
        AppletCloseCallback
        CloseRecievedWhileBusy = false;
        WindowClosing = false;
        Tag
        WebAppDocumentUihtml
    end

    methods (Static)
        function out = getPropsAndCallbacks()
            out = ...
                ... % Property to listen to         % Callback function
                ["CanCloseResponse"                 "handleCanCloseResponse"; ...
                "AddDeviceButtonEnabled"            "handleAddDeviceButtonEnabled"; ...
                "RemoveDocument"                    "removeDocument"; ...
                "DeviceForDocResponse"              "handleDeviceForDocResponse"; ...
                "CreateClientAppDoc"                "createClientAppDoc"; ...
                "CreateDocForDevConfigHelpPage"     "createDocForDevConfigHelpPage"; ...
                "SetDocumentTitle"                  "setDocumentTitle"; ...
                "SetWindowTitle"                    "setHwmgrTitle"; ...
                "SetFigureVisible"                  "setFigureVisible"; ...
                "BringDocumentToFocus"              "bringDocumentToFront"; ...
                "ShowNoDevicesMsgByTag"             "showNoDevicesMsgByTag";...
                "SetCollapseToolstrip"              "collapseToolstrip"; ...
                "RunningAppClientId"                "setRunningAppClientId"; ...
                "StartPageClientId"                 "setStartPageClientId"; ...
                ];
        end

        function out = getPropsAndCallbacksNoArgs()
            out = ...
                ... % Property to listen to         % Callback function
                ["RemoveAllDocuments"               "removeAllDocuments"; ...
                "CreateDocForDevConfigStandardMsg"  "createDocForDevConfigStandardMsg"; ...
                "CloseDisplay"                      "closeDisplay";...
                "MakeWindowBusy"                    "makeWindowBusy"; ...
                "RemoveWindowBusy"                  "removeWindowBusy"; ...
                "MainTsTabRequest"                  "handleMainTsTabRequest";...
                "ShowSingleDocumentLayout"          "handleShowSingleDocumentLayout"; ...
                "RemoveAllPanels"                   "handleRemoveAllPanels"; ...
                "DialogParentRequest"               "handleDialogParentRequest";
                ];
        end

        function setDocumentTitle(args)
            args.Document.Title= args.Title;

            drawnow;
        end

        function flag = isDebugWebApp()
            % Check for flags associated with Client App Startpage and
            % Device List, both of which are rendered within the
            % AppContainer in this class
            flag =  strcmp(getenv('HWMGR_CLIENTAPP_STARTPAGE_DEBUG'), 'true') || ...
                    strcmp(getenv('HWMGR_DEVLIST_DEBUG'), 'true');
        end

    end

    methods

        function obj = HwmgrWindow(mediator, context)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);

            obj.Context = context;
            obj.initializeWindow();
        end

        function createAppContainer(obj)
            obj.Tag = "hwm_app" + matlab.lang.internal.uuid;

            appOptions.Tag = obj.Tag;

            appOptions.EnableTheming = true;

            appOptions.Title = "";

            % Disable document tiling by users
            appOptions.UserDocumentTilingEnabled = false;

            % Disallow showing a single document tab, as it would only be
            % closable programmatically
            appOptions.ShowSingleDocumentTab = false;

            appOptions.DocumentPlaceHolderText = "";

            if ~obj.isDebugWebApp()
                obj.AppContainer = matlab.ui.container.internal.AppContainer(appOptions);
            else
                % Add dynamically-loaded module info for debug mode
                extInfo = matlab.ui.container.internal.appcontainer.ExtensionInfo;
                extInfo.Modules = matlab.hwmgr.internal.DeviceListModuleInfo;
                appOptions.Extension = extInfo;

                % Use AppContainer_Debug to enable debug mode in window
                obj.AppContainer = matlab.ui.container.internal.AppContainer_Debug(appOptions);
            end

            % Add status bar
            app = feval(obj.Context.AppletClass);

            obj.addStatusBar(app);

            obj.addContextDefinitions(app);

            obj.CurrentTitle = obj.WindowTitle;

            % Set the ClientAction event listener for intercepting document
            % space user interaction
            propChangedListener = event.listener(obj.AppContainer, 'PropertyChanged', ...
                @(src,evt)obj.propertyChangedCallback(src, evt));

            % Set the framework cleanup listener
            stateChangedListener = event.listener(obj.AppContainer, 'StateChanged', ...
                @(src, evt)obj.destroyFramework(src, evt));

            obj.AppContainer.CanCloseFcn = @obj.windowCanCloseFcn;

            obj.Listeners = [propChangedListener; stateChangedListener];
        end

        function addStatusBar(obj, app)
            if app.StatusBarEnabled
                obj.StatusBar = matlab.ui.internal.statusbar.StatusBar();
                obj.AppContainer.add(obj.StatusBar);

                components = app.createStatusComponents();
                for i=1:numel(components)
                    obj.AppContainer.add(components(i));
                end
            end
        end

        function addContextDefinitions(obj, app)
            % Get the context definitions and add them

            contextDefs = app.createContextDefinitions();

            % Check if any of the context definitions have the toolstrip
            % tabgroup tags or panel tags set.

            for i = 1:numel(contextDefs)
                if ~isempty(contextDefs{i}.ToolstripTabGroupTags) || ~isempty(contextDefs{i}.PanelTags)
                    error(message('hwmanagerapp:framework:UnsupportedContextComponentTags'));
                end
            end

            if ~isempty(contextDefs)
                obj.AppContainer.Contexts = contextDefs;
            end

        end

        function initializeWindow(obj)
            obj.createAppContainer();

            % Create the tab group
            obj.createTabGroup();

            % Add the tabGroup to the toolgroup - this renders the main tab
            obj.AppContainer.add(obj.TabGroup);

            % Set window position and size
            obj.setInitialWindowPositionAndSize();

        end


        function subscribeToMediatorProperties(obj, ~ ,~)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);

            eventsAndCallbacksNoArgs = obj.getPropsAndCallbacksNoArgs();
            obj.subscribeWithGatewaysNoArgs(eventsAndCallbacksNoArgs, @obj.subscribe);
        end

        % ----------UI Callbacks----------------------%

        function okayToClose = windowCanCloseFcn(obj, ~)
            % Function that is called by the APPCONTAINER when a user
            % attempts to close Hardware Manager by clicking on the "X"
            % button in the main window. This is the AppContainer's
            % CanCloseFcn.

            if obj.SuspendClose
                okayToClose = false;
                return;
            end

            closeReason = matlab.hwmgr.internal.AppletClosingReason.AppClosing;

            % Don't do anything if the suspend flag is set
            if obj.AppContainer.Busy
                okayToClose = false;
                % Cache current close request
                obj.CloseRecievedWhileBusy = true;
                return;
            end

            obj.CloseRecievedWhileBusy = false;

            % Ask if the applets can close
            obj.logAndSet("CanCloseHwmgrWindowRequest", closeReason);

            if obj.CanCloseResponse
                obj.WindowClosing = true;
                % Close all applets
                obj.logAndSet("UserClosingHwmgr", true);
            end
            okayToClose = obj.CanCloseResponse;
        end

        function canClose = canCloseAppletDoc(obj, appletDoc)
            % Callback method invoked when the user clicks the "X" button for a
            % document that is hosting an applet or when programmatically remove a
            % document from appcontainer

            % If the window is closing, applets were already closed by the
            % UI closing callback. AppContainer just happens to call the
            % document's canCloseFcn independent of the UI canCloseFcn
            % results so return early here if that's the case.
            if obj.WindowClosing
                canClose = true;
                return;
            end

            % Ask applet runner whether the running applets can close
            obj.logAndSet("CanCloseAppletDocRequest", appletDoc);

            if obj.CanCloseResponse
                % Send a request to the Main Controller to initiate applet
                % close actions
                obj.logAndSet("UserClosingAppletDoc", appletDoc);
            end
            canClose = obj.CanCloseResponse;
        end

        %-----------BEGIN Mediator Callbacks ---------%

        function handleShowSingleDocumentLayout(obj)
            %  Remove the device list panel and any documents
            obj.removeAllDocuments();

            obj.removeAllPanels();

            obj.collapseToolstrip(true);
        end

        function handleRemoveAllPanels(obj)
            %  Remove the device list panel
            obj.removeAllPanels();

            obj.collapseToolstrip(true);
        end

        function handleMainTsTabRequest(obj)
            tabGroup = obj.AppContainer.getTabGroup('hwmgr_tabgroup');
            msgData = struct('MainTabGroup', tabGroup);
            obj.logAndSet("MainTsTabResponse", msgData);
        end

        function handleCanCloseResponse(obj, response)
            obj.CanCloseResponse = response;
        end

        function showNoDevicesMsgByTag(obj, msgTag)

            figDocOptions = struct('GroupTag', "NoDevicesTxt", ...
                'Closable', false, ...
                'CanCloseFcn', function_handle.empty, ...
                'Title', " ");

            document = obj.createAndAddFigureDocument(figDocOptions);

            msgData = struct('Document', document, ...
                'MsgTag', msgTag);
            obj.logAndSet("AddNoDevicesMsgToDoc",msgData);
        end

        function setRunningAppClientId(obj, clientId)
            obj.RunningAppClientId = clientId;
        end

        function setStartPageClientId(obj, clientId)
            obj.StartPageClientId = clientId;
        end

        function removeAllDocuments(obj)
            % This method will loop through all the views in the view
            % struct array and ask the display manager to clean them up.
            % The view struct array will be empty at the end of this
            % method and all views will be removed from the document area
            % in Hardware Manager.
            allDocuments = obj.AppContainer.getDocuments();
            for i = 1:numel(allDocuments)
                % Clear the canCloseFcn for each document before removal
                % since close is confirmed before removal
                allDocuments{i}.CanCloseFcn = function_handle.empty;
                obj.AppContainer.closeDocument(allDocuments{i}.DocumentGroupTag, allDocuments{i}.Tag);
            end
        end

        function removeAllPanels(obj)
            % Remove all panels
            allPanels = obj.AppContainer.getPanels();
            for i = 1:numel(allPanels)
                obj.AppContainer.removePanel(allPanels{i}.Tag);
            end
        end

        function makeWindowBusy(obj)
            obj.setWindowBusy(true);
        end

        function removeWindowBusy(obj)
            obj.setWindowBusy(false);
        end

        function handleDeviceForDocResponse(obj, device)
            obj.logAndSet("DeviceForSelectedDocument", device);
        end

        function handleDialogParentRequest(obj)
            obj.logAndSet("DialogParentResponse", obj.AppContainer);
        end

        %-----------END Mediator Callbacks -----------%

        function collapseToolstrip(obj, flag)
            obj.AppContainer.ToolstripCollapsed = flag;
        end

        function createDocForDevConfigHelpPage(obj, descriptor)

            document = obj.createHelpPanelDocument();
            obj.addDocumentToAppContainer(document);

            msgData = struct('Descriptor', descriptor, ...
                'Document', document);
            obj.logAndSet("AddDeviceHelpDocumentReady", msgData);
        end

        function documentChangedCallback(obj, src, evt)
            % Callback method that is invoked when the user selects the
            % view's document tab. This method is currently only used to
            % change the selected device when an applet is selected in
            % applet mode.

            % Reason why we need to check if busy: ---- AppContainer makes
            % the selected document event fire when a new document is added
            % and this callback is invoked. As such, check if the
            % application was already busy since the use cannot select the
            % document while the application is busy
            if ~obj.AppContainer.Busy
                % The application must be made modal here because we don't
                % want the user to switch tabs again until the first switch
                % is reliably done. Otherwise this leads to timing/state
                % issues.
                obj.makeWindowBusy();
                cleanupObj = onCleanup(@()obj.removeWindowBusy());

                obj.DeviceForSelectedDocument = [];
                obj.logAndSet("DeviceForDocRequest", src);

                if ~isempty(obj.DeviceForSelectedDocument)
                    % Select the device returned
                    obj.logAndSet("DocumentSelected", obj.DeviceForSelectedDocument);
                end
            end
        end

        function createDocForDevConfigStandardMsg(obj)
            helpDocOptions =   struct('GroupTag', "NonEnumDeviceDocGroup", ...
                'Closable', false, ...
                'CanCloseFcn', function_handle.empty, ...
                'Title', " ");
            document = obj.createAndAddFigureDocument(helpDocOptions);
            obj.logAndSet("AddDeviceFigDocReady", document);
        end

        function msg = createWebAppDoc(obj, groupTag)
            % This method creates a figure document with a uihtml widget
            % inside it. This uihtml container will be used to display the
            % web app by passing the uihtml container to the interested
            % module.
            %
            % This method is called whenever the controller would like to
            % show a web module's web app/web page for display.
            %
            % For example, when the controller would like to show the
            % landing page, this method is called to initialize the
            % document and uihtml before giving the landing page module the
            % uicontainer object to show its web app in.

            figDocOptions = struct('GroupTag', groupTag, ...
                'Closable', true, ...
                'Title', " ", ...
                'Maximizable', false);

            doc = obj.createAndAddStartPageDocument(figDocOptions);

            msg = struct("Document", doc);
            obj.WebAppDocumentUihtml = msg;
        end

        function createClientAppDoc(obj, appletStruct)
            % Create a new figure document and relay it to the DocumentPane
            % to add a grid and uipanel inside it before it gets sent to
            % the Applet Runner for use by the next client app that will
            % run. Note that the figure also gets sent to the Applet
            % Runner, addition to the uipanel (rootpane) that will be given
            % to the downstream applets.

            % Although hwmgr controls the group tag for the document
            % currently - in the future, the group tag can be specified by
            % client applets to indicate whether they want to group applet
            % documents together into a single document.

            figDocOptions = struct('GroupTag', appletStruct.GroupTag, ...
                'Closable', true, ...
                'CanCloseFcn', @obj.canCloseAppletDoc, ...
                'Title', " ");

            document = obj.createAndAddFigureDocument(figDocOptions);
            obj.logAndSet("NewFigDocReady", document);
        end

        function constructDeviceListPanel(obj)
            panelOptions.Tag = "deviceListPanel";
            panelOptions.Title = string(message('hwmanagerapp:devicelist:DeviceListTitle').getString());
            panelOptions.Region = "left";
            panelOptions.PreferredWidth = obj.DefaultDevListWidth;
            panelOptions.Maximizable = false;
            panelOptions.PermissibleRegions = "left";

            % Get Client Id for communication channel
            if isempty(obj.RunningAppClientId)
                obj.requestRunningAppClientId();
            end

            clientId = obj.RunningAppClientId;
            panel = matlab.hwmgr.internal.DeviceListPanel(clientId, panelOptions);

            % Add the panel to appcontainer
            % Connector messages are sent after panel is added
            % to the appcontainer, so add to appcontainer after
            % device list has the panel
            obj.AppContainer.add(panel);
            obj.logAndSet("AddDeviceListPanelReady", panel);
        end

        function removeDeviceListPanel(obj)
            obj.AppContainer.removePanel("deviceListPanel");
        end

        function setRefreshButtonCallbackFcn(obj, fcn)
            obj.RefreshButtonCallbackFcn = fcn;
        end

        function show(obj)
            % Make the Hardware Manager application visible
            obj.AppContainer.Visible = true;
            obj.AppContainer.bringToFront;
        end

        function hide(obj)
            obj.AppContainer.Visible = false;
        end

        function bool = isShowing(obj)
            bool = obj.AppContainer.Visible;
        end

        function setHwmgrTitle(obj, newTitle)
            % Method to modify the title of the main
            % hardware manager UI. This is invoked when an app is running
            obj.CurrentTitle = char(newTitle);
            obj.AppContainer.Title = obj.CurrentTitle;
            drawnow;
        end

        function closeApplicationWindow(obj)
            obj.AppContainer.delete()
        end

        function destroyFramework(obj, ~, evt)
            if strcmp(evt.Source.State, 'TERMINATED')
                % Destroy Hardware Manager Framework if the app window is
                % closed

                % First find the framework instance that corresponds to
                % this window

                allInstances = matlab.hwmgr.internal.HardwareManagerFramework.getAllInstances();
                for i = 1:numel(allInstances)
                    if isvalid(allInstances(i)) && allInstances(i).DisplayManager.Window == obj
                        delete(allInstances(i));
                        break;
                    end
                end
            end
        end

        function closeDisplay(obj)
            obj.AppContainer.close();
        end

        function setSelectedViewCallback(obj, fcnHandle)
            obj.SelectedViewCallback = fcnHandle;
        end

        function propertyChangedCallback(obj, appContainer, evt)

            % Check if the event was a window size change event. Set the
            % device list width to a fixed width since the device cards are
            % also of a fixed width. This will allow the app space to get
            % the maximum real estate.
            if strcmp(evt.PropertyName, 'WindowBounds')
                obj.AppContainer.LeftWidth = obj.DefaultDevListWidth;
            end

            if strcmp(evt.PropertyName, 'SelectedChild')
                % Check the SelectedChild property. It is a struct with
                % fields and sometimes the 'tag' field doesn't exist
                % depending on the child that is selected

                % If the device list was clicked, do nothing
                if isfield(appContainer.SelectedChild, 'tag') && (appContainer.SelectedChild.tag == "deviceListPanel")
                    return;
                end

                % It is not always true that the selected child is
                % a document. For example, it is possible that the
                % document area is being collapsed. In that case,
                % there is no documentGroupTag or tag
                if isfield(appContainer.SelectedChild, 'documentGroupTag') && isfield(appContainer.SelectedChild, 'tag')
                    document = appContainer.getDocument(appContainer.SelectedChild.documentGroupTag, appContainer.SelectedChild.tag);
                    obj.documentChangedCallback(document, evt);
                end
            end
        end

        function setViewCloseFcn(obj, document, fcnHandle)
            document.CanCloseFcn = @(doc)fcnHandle(doc, []);
        end

        function setViewDeleteFcn(obj, document, fcnHandle)
            obj.Listeners(end+1) = event.listener(document, 'ObjectBeingDestroyed', @(document, evt)fcnHandle(document, evt));
        end

        function document = createDocument(obj, documentType, docOptions)
            if documentType == "figure"
                document = obj.createFigureDocument(docOptions);
            elseif documentType == "DeviceList"
                document = obj.createDeviceListDocument(docOptions);
            else
                document = obj.createRegularDocument(docOptions);
            end
        end

        function document = createAndAddFigureDocument(obj, docOptions)
            docGroup = obj.AppContainer.getDocumentGroup(docOptions.GroupTag);
            if isempty(docGroup)
                groupCtor = @matlab.ui.internal.FigureDocumentGroup;
                docGroupOptions.Tag = docOptions.GroupTag;
                docGroupOptions.Title = docOptions.Title;
                obj.createAndAddGroup(docGroupOptions, groupCtor);
            end
            document = obj.createDocument('figure', docOptions);
            obj.addDocumentToGroup(document);
        end

        function document = createAndAddStartPageDocument(obj, docOptions)
            docGroup = obj.AppContainer.getDocumentGroup(docOptions.GroupTag);
            if isempty(docGroup)
                groupCtor = @matlab.hwmgr.internal.DeviceListDocumentGroup;
                docGroupOptions.Tag = docOptions.GroupTag;
                docGroupOptions.Title = docOptions.Title;

                obj.createAndAddGroup(docGroupOptions, groupCtor);
            end
            document = obj.createDocument('DeviceList', docOptions);
            obj.addDocumentToGroup(document);
        end

        function doc = createHelpPanelDocument(obj)
            docGroupOptions.Tag = "helpDocumentGroup";
            docGroupOptions.Title = "Help Group";
            docGroup = obj.AppContainer.getDocumentGroup(docGroupOptions.Tag);
            if isempty(docGroup)
                groupCtor = @matlab.ui.internal.FigureDocumentGroup;
                obj.createAndAddGroup(docGroupOptions, groupCtor);
            end

            docOptions.DocumentGroupTag = docGroupOptions.Tag;
            docOptions.Tag = "helpDocument";
            docOptions.Title = "Help Document";
            docOptions.Closable = false;
            docOptions.Selected = true;
            doc = obj.createDocument('figure', docOptions);
        end

        function bringDocumentToFront(obj, document)
            document.Selected = true;
        end

        function setFigureVisible(~, fig)
            fig.Visible = 'on';
        end

        function addDocumentToAppContainer(obj, document)
            obj.addDocumentToGroup(document);
        end

        function removeDocument(obj, document)
            obj.AppContainer.closeDocument(document.DocumentGroupTag, document.Tag);
        end

        function document = createFigureDocument(obj, docOptions)
            if isfield(docOptions, "GroupTag")
                docOptions.DocumentGroupTag = docOptions.GroupTag;
                docOptions = rmfield(docOptions, 'GroupTag');
            end
            document = matlab.ui.internal.FigureDocument(docOptions);

            % This is needed to prevent command window from gaining focus
            % through key press.
            document.Figure.KeyPressFcn = @matlab.hwmgr.internal.FrameworkDisplayManager.noOpFcnForKeyPress;
        end

        function document = createDeviceListDocument(obj, docOptions)
            if isfield(docOptions, "GroupTag")
                docOptions.DocumentGroupTag = docOptions.GroupTag;
                docOptions = rmfield(docOptions, 'GroupTag');
            end

            if isempty(obj.StartPageClientId)
                obj.requestStartPageClientId();
            end
            clientId = obj.StartPageClientId;
            docOptions.Content.clientId = clientId;

            document = matlab.ui.container.internal.appcontainer.Document(docOptions);
        end

        function document = createRegularDocument(obj, docOptions)
            document = matlab.ui.container.internal.appcontainer.Document(docOptions);
        end

        function createAndAddGroup(obj, docGroupOptions, groupCtor)
            docGroup =  groupCtor(docGroupOptions);
            obj.AppContainer.add(docGroup);
        end

        function addDocumentToGroup(obj, document)
            obj.AppContainer.addDocument(document);
        end

        function showDisplay(obj)
            % SHOWDISPLAY = Opens the app window

            obj.show();

            waitfor(obj.AppContainer, 'State', matlab.ui.container.internal.appcontainer.AppState.RUNNING);

            % Set the web window's MATLAB Closing callback so that the
            % client app window doesn't linger for a while after MATLAB
            % window is closed
            webWindow = obj.getWebWindow();
            webWindow.MATLABClosingCallback = @(~,~)obj.handleMATLABClose();

            obj.logAndSet("WindowInitialized", true);
        end

        function handleMATLABClose(obj)
            evt = struct('Source', struct('State', 'TERMINATED'));
            obj.closeDisplay();
            obj.destroyFramework([], evt);
            exit;
        end


        function delete(obj)
            % Don't explicitly delete obj.AppContainer here,
            % because it will cause AppContainer window to be deleted
            % before the close callback's execution completes.

            % We need to delete the protocol gallery explicitly since it
            % contains a timer with a reference to the gallery object
            % itself, which prevents MATLAB from garbage collecting the
            % object and therefore the timer.
            delete(obj.ProtocolGalleryButton);
        end

    end

    methods(Access={?matlab.hwmgr.internal.HwmgrWindow})

        function setWindowBusy(obj, busy)
            obj.AppContainer.Busy = busy;
            if ~busy && obj.CloseRecievedWhileBusy
                obj.closeDisplay();
            end
        end

        function setInitialWindowPositionAndSize(obj)
            % setWindowPositionAndSize the dimensions and positioning
            %of the various elements that are contained within the tool
            %group frame.

            screenSize = getScreenSizeInPixels();
            obj.AppContainer.WindowBounds = [0.125*screenSize(3), 0.125*screenSize(4), .75 * screenSize(3), .75*screenSize(4)];
        end

        function createTabGroup(obj)
            obj.TabGroup = matlab.ui.internal.toolstrip.TabGroup();
            obj.TabGroup.Tag = 'hwmgr_tabgroup';
        end

        function handleRefreshButton(obj, src, evt)
            % Ask if the Applet Runner if applets can close due to refresh
            closeReason = matlab.hwmgr.internal.AppletClosingReason.RefreshHardware;
            obj.logAndSet("CanRefreshRequest", closeReason);

            if obj.CanCloseResponse
                obj.logAndSet("UserRefreshingHwmgr", true);
            end
        end
    end
    methods (Access = private)
        function requestRunningAppClientId(obj)
            obj.RequestRunningAppClientId = true;
        end

        function requestStartPageClientId(obj)
            obj.RequestStartPageClientId = true;
        end
    end

    methods (Hidden)
        function window = getWebWindow(obj)
            window = [];

            wmgr = matlab.internal.webwindowmanager;
            allWindows = wmgr.windowList;
            for i = 1:numel(allWindows)
                if string(allWindows(i).URL).contains(obj.AppContainer.Tag)
                    window = allWindows(i);
                    break;
                end
            end

        end

    end

end

function screenSizePixels = getScreenSizeInPixels()
    % Workaround for g1374535
    % groot Screensize currently does not provide accurate screensize with MO
    import matlab.internal.capability.Capability;
    if ~Capability.isSupported(Capability.LocalClient)
        screenSizePixels = connector.internal.webwindowmanager.instance().defaultPosition;
        return
    end
    originalUnits = get(groot, 'Units');
    restoreUnits = onCleanup(@()set(groot, 'Units', originalUnits));
    set(groot, 'Units', 'pixels');
    screenSizePixels = get(groot, 'ScreenSize');
end
