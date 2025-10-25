classdef ClientAppController < matlabshared.mediator.internal.Publisher &...
        matlabshared.mediator.internal.Subscriber &...
        matlab.hwmgr.internal.MessageLogger
    % The client app controller class. This class mediates/coordinates
    % communication between the different Hardware Manager modules and
    % ClientAppWindow. This is done by receiving high level command messages
    % that are converted to a series of specific action messages sent out
    % to different modules and the ClientAppWindow.

    % Copyright 2018-2024 The MathWorks, Inc.

    properties
        % USAGELOGGER - Handle to the Hardware Manager Usage Logger class
        % that wraps DDUX functionality. The usage logger is instantiated
        % in this class and then passed around to modules. This is because
        % the usage logger instance has the dynamically changing usage data
        % and is not a singleton (i.e. modules cannot add to the data
        % if they each create an instance of the logger).
        UsageLogger

        % MODALREQUESTID - ID to synchronize/pair ansynchronous
        % requests to make and remove modality (i.e. calls to
        % makeHwmgrBusy and removeHwmgrBusy).
        ModalRequestID

        % CUSTOMUSAGELOGGINGFCN - a function handle that can be used to
        % inspect the usage logging data that is flushed to the DDUX
        % service. This function is called right before the DDUX data is
        % logged. The function takes a single input argument - the
        % structure containing the data that is instrumented.
        CustomUsageLoggingFcn

        % CLOSECACHED - flag indicating that a programmatic application
        % close should be initiated to honor a cached user initiated close
        % via the UI
        CloseCached

        % CURRENTPAGE - String that indicates which page the user is
        % currently on. This is intended to be used by the Hardware Manager
        % Framework class to inform clients. The possible values are
        % "StartPage", "RunningAppPage"
        CurrentPage
    end

    properties (SetObservable)
        % Run the following command to see listeners for these properties:
        % matlab.hwmgr.internal.util.displayPropListeners('matlab.hwmgr.internal.MainController');
        CloseAllApplets
        CloseAppletForDoc
        CloseAppletForDevice

        RefreshNonEnumDeviceGallery
        RefreshDeviceList

        RemoveAllDocuments
        RemoveDocument

        ShowAppletForSelectedDevice

        RemoveDeviceTsTab
        CreateAppletTsTab
        ReplaceAppletTsTab

        SelectDeviceByIndex
        SelectDeviceByObject
        DeselectDevice
        
        CreateClientAppDoc
        ConstructAndLaunchNewApplet

        ShowAppFailedMsg
        SetDocumentTitle
        SetWindowTitle

        SetFigureVisible
        BringDocumentToFocus

        CloseDisplay

        CreateDocForDevConfigHelpPage
        CreateDocForDevConfigStandardMsg

        ShowDevicesInDevList

        ShowNoDevicesMsgInDoc

        RemoveWindowBusy
        MakeWindowBusy

        DisableDeviceList
        EnableDeviceList

        ShowSingleDocumentLayout

        SetCollapseToolstrip
        
        RefreshPlugins

        DeviceSelectedOnStartPage
        
        DeviceRemovedOnStartPage
        
        ShowStartPage
        ShowDeviceListToolstripLayout
        
        DisableClientToolstripArea

        ShowAppletAfterConfiguring

        ShowLoadingInDevList

        UserConfigureDeviceStartPage
        % Callers can use this API property to select a device in priority
        % order. 
        % Possible values:
        % [-1] - Attempt to select the previously selected device if
        % possible
        % [1] Select the first device 
        % [-1 1] Select the last used device and if not possible select the
        % first device
        SelectDeviceByPriority
    end

    methods (Static)
        function out = getPropsAndCallbacks()
            out =  ... % Property to listen to         % Callback function
                [
                "UserClosingAppletDoc"              "handleUserClosingAppletDoc"; ...
                "UserRemovingDevice"                "handleUserRemovingDevice"; ...
                "ShowScreenForSelectedDevice"       "handleDeviceSelectionChanged"; ...
                "LaunchAppletRequest"               "handleLaunchAppletRequest"; ...
                "AppletFocusRequest"                "handleAppletFocusRequest";...
                "DeviceSelectionChanged"            "handleDeviceSelectionChanged"; ...
                "DocumentSelected"                  "handleDocumentSelected"; ...
                "AppClosedDueToError"               "handleAppClosedDueToError";...
                "LaunchedAppDocTitleReady"          "handleLaunchedAppDocTitleReady"; ...
                "LaunchedAppNameReady"              "handleLaunchedAppNameReady"; ...
                "LaunchedAppFigureReady"            "handleLaunchedAppFigureReady"; ...
                "LaunchedAppTsTabReady"             "handleLaunchedAppTsTabReady"; ...
                "AppletClosedForDocument"           "handleAppletClosedForDocument"; ...
                "UserAddingDevice"                  "handleUserAddingDevice"; ...
                "UserDoneAddingDevice"              "handleUserDoneAddingDevice";...
                "UserDoneConfiguringDevice"         "handleUserDoneConfiguringDevice";...
                "DeviceListForDdux"                 "handleDeviceListForDdux"; ...
                "AppDduxDataForDevice"              "setAppDduxDataForDevice"; ...
                "UserSelectDeviceOnStartPage"       "handleSelectDeviceOnStartPage"; ...
                "UserRemoveDeviceOnStartPage"       "handleRemoveDeviceOnStartPage"; ...
                "EmptyDeviceList"                   "handleEmptyDeviceList"; ...
                ];
        end

        function out = getPropsAndCallbacksNoArgs()
            out =  ... % Property to listen to         % Callback function
                ["UserClosingHwmgr"                 "handleUserClosingHwmgr"; ...
                "UserRefreshingHwmgrStartPage"      "handleUserRefreshingStartPage"; ...
                "WindowInitialized"                 "handleWindowInitialized"; ...
                "UserRefreshingHwmgrDeviceList"     "refreshHwmgrClientAppView"; ...
                "UserClosingSession"                "handleUserClosingSession"; ...
                "RegistrationFrameworkRefresh"      "handleRegistrationFrameworkRefresh"; ...
                "SetToolstripForAppError"           "handleSetToolstripForAppError"; ...
                "ShowDevicesLoadingView"            "handleShowDevicesLoadingView"; ...
                "SelectDeviceAfterRefresh"          "handleSelectDeviceAfterRefresh"; ...
                ];
        end
    end

    methods

        function obj = ClientAppController(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);

            obj.UsageLogger = matlab.hwmgr.internal.UsageLogger();
            obj.CurrentPage = "StartPage";
        end

        function subscribeToMediatorProperties(obj, ~, ~)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);

            eventsAndCallbacksNoArgs = obj.getPropsAndCallbacksNoArgs();
            obj.subscribeWithGatewaysNoArgs(eventsAndCallbacksNoArgs, @obj.subscribe);
        end

        %-----------BEGIN Mediator Callbacks ---------%

        function handleWindowInitialized(obj)
            % Prepare the document for showing the landing page
            obj.logAndSet("ShowSingleDocumentLayout", true);

            % AppContainer window is ready, load landing page
            obj.logAndSet("ShowStartPage", true);
            obj.CurrentPage = "StartPage";
        end

        function setAppDduxDataForDevice(obj, appletUsageData)
            obj.UsageLogger.addAppletDataToDevice(appletUsageData);
        end

        function handleDeviceListForDdux(obj,devices)
            obj.UsageLogger.instrumentDeviceList(devices);
        end

        function handleAppletClosedForDocument(obj, doc)
            % This method will remove a single view
            obj.logAndSet("RemoveDocument", doc);

            % Signal the Toolstrip module to remove the applet toolstrip
            % tab
            msgData = struct('IsUsingAppletTsTab', false, ...
                'AppletTsTab', []);
            obj.logAndSet("ReplaceAppletTsTab", msgData);
        end

        function handleUserRemovingDevice(obj, device)

            % Close any apps for the device
            obj.logAndSet("CloseAppletForDevice", device);
        end

        function handleUserClosingHwmgr(obj)
            % Close any running applets before the UI is closed
            obj.logAndSet("CloseAllApplets", true);
        end

        function handleUserClosingAppletDoc(obj, appletDoc)
            obj.logAndSet("CloseAppletForDoc", appletDoc);
        end

        function handleShowDevicesLoadingView(obj)
            % Send a message to the running app page to show loading view
            % in device list
            if obj.CurrentPage == "RunningAppPage"
                obj.logAndSet("ShowLoadingInDevList", "true");
            end
        end

        function refreshHwmgr(obj, doSoftLoad, refreshPlugins)
            % This method is called whenever the hardware manager is
            % refreshed. It will
            % 1. Initialize the device selection callback for the device
            % list web app
            % 2. Load all non enumerable device descriptors from the
            % plugins and put them in the gallery
            % 3. Load enumerable devices from the plugins
            %
            % The doSoftLoad flag indicates whether the refresh should be
            % done as a soft refresh or a hard refresh. A soft refresh will
            % re-use plugins, providers and devices already available in
            % the shared plugin store. A hard refresh will re-create the
            % plugin, providers and re-enumerate devices/reload non enum
            % devices from the user's cache.
            %
            % The refreshPlugins flag indicates whether the plugins
            % should be refreshed. This is set to false when launching the
            % app which already loads the plugin

            
            arguments
               obj
               doSoftLoad (1,1) logical = false;
               refreshPlugins (1,1) logical = true;
            end
            
            id = obj.makeHwmgrBusy();
            oc = onCleanup(@()obj.removeHwmgrBusy(id));

            % Refresh plugins if refreshPlugins is set to true (default).
            % This will cause descriptors to be reloaded
            % in the client app start page if the page is visible
            if refreshPlugins
                obj.logAndSet("RefreshPlugins", doSoftLoad);
            end

            % Refresh the devices list in the device list module
            obj.logAndSet("RefreshDeviceList", doSoftLoad);

        end
        
        function handleDocumentSelected(obj, deviceForDocument)
            obj.logAndSet("SelectDeviceByObject", deviceForDocument);
        end

        function handleLaunchedAppTsTabReady(obj, tsTabInfo)

            obj.logAndSet("ReplaceAppletTsTab", tsTabInfo);

        end

        function handleLaunchAppletRequest(obj, appletStruct)
            obj.logAndSet("CloseAllApplets", true);

            obj.logAndSet("RemoveAllDocuments", true);

            obj.launchApplet(appletStruct);
        end

        function launchApplet(obj, appletStruct)

            % This will prompt the Toolstrip module to create a new
            % toolstrip tab and send it to the applet runner as the next
            % applet tab
            obj.logAndSet("CreateAppletTsTab", appletStruct);

            % This will create a fig doc and uipanel inside it, send it to
            % the applet runner as the next applet document
            obj.logAndSet("CreateClientAppDoc", appletStruct);


            % Make HW MGR window modal until the applet is running
            requestID = obj.makeHwmgrBusy();
            oc = onCleanup(@()obj.removeHwmgrBusy(requestID));

            % This will cause the applet runner to instantiate and launch
            % the requested applet
            obj.logAndSet("ConstructAndLaunchNewApplet", appletStruct);
        end

        function handleAppletFocusRequest(obj, args)
            % Ask the window to the bring the provided document to focus
            obj.logAndSet("BringDocumentToFocus", args.Document);

            % Ask the Toolstrip module to show the provided applet tab and
            % remove any existing applet tabs

            msgData = struct('IsUsingAppletTsTab', true, ...
                'AppletTsTab', args.AppletTsTab);
            obj.logAndSet("ReplaceAppletTsTab", msgData);
        end

        function busyID = makeHwmgrBusy(obj)
            busyID = matlab.hwmgr.internal.UsageLogger().generateDeviceListUUID();
            if isempty(obj.ModalRequestID)
                obj.ModalRequestID = busyID;
            end
            obj.logAndSet("MakeWindowBusy", true);


            obj.logAndSet("DisableDeviceList", true);
        end

        function removeHwmgrBusy(obj, modalRequestor)
            if isequal(obj.ModalRequestID, modalRequestor)
                obj.logAndSet("RemoveWindowBusy", false);
                % Once the busy mode is disabled, the appcontainer window
                % will process any close requests and close the window if
                % approved. For that reason, we need to check for validity
                % of the object here and return if the window and framework
                % were already cleaned up.
                if ~isvalid(obj)
                    return;
                end
                obj.logAndSet("EnableDeviceList", true);

                obj.ModalRequestID = [];
            end
        end

        function handleAppClosedDueToError(obj, appRelatedHandles)
            % This method will display an app failure message in the
            % document provided in the appRelatedHandles struct.

            obj.logAndSet("ShowAppFailedMsg", appRelatedHandles);
        end

        function handleLaunchedAppDocTitleReady(obj, documentAndTitle)
            obj.logAndSet("SetDocumentTitle", documentAndTitle);
        end

        function handleLaunchedAppNameReady(obj, title)
            % Set the hardware manager window title to the applet name
            obj.setApplicationWindowTitle(title);
        end

        function setApplicationWindowTitle(obj, title)
            obj.logAndSet("SetWindowTitle", title);
        end

        function handleLaunchedAppFigureReady(obj, fig)
            obj.logAndSet("SetFigureVisible", fig);
        end

        function closeWindow(obj)
            obj.logAndSet("CloseDisplay", true);
        end

        function handleUserAddingDevice(obj, args)
            % Close any applets
            obj.logAndSet("CloseAllApplets", true);

            % Remove all documents
            obj.logAndSet("RemoveAllDocuments", true);

            % Remove any applet tabs
            msgData = struct('IsUsingAppletTsTab', false,...
                'AppletTsTab', []);
            obj.logAndSet("ReplaceAppletTsTab", msgData);

            if args.HasHelpPage
                % Send the HwmgrWindow a message to create a document and
                % relay it to the HelpPanel module. The HelpPanel module
                % will then load the Help Page in the panel.
                obj.logAndSet("CreateDocForDevConfigHelpPage", args.Descriptor);
            else
                % Send a message to the DocumentPane to load a standard
                % device configuration message in a figure document
                obj.logAndSet("CreateDocForDevConfigStandardMsg", true);
            end

        end

        function handleUserDoneAddingDevice(obj, deviceToSelectIdxOrDest)
            % Remove the modal pane from the device list and start showing
            % devices again. Don't refresh devices just show the same
            % devices that were shown before entering the configuration
            % mode. Also, removes any documents showing help for the non
            % enum device being configured
            %
            % deviceToSelectIdxOrDest can be one of two things - a numeric
            % device index of the filtered device list array, or a
            % destination string. The the destination string essentially
            % encodes which page the controller should go to from the modal
            % device configuration page. This can vary depending on where
            % the user had entered the workflow from, and whether the user
            % cancelled or confirmed the device.

            % Remove any documents being shown
            obj.logAndSet("RemoveAllDocuments", true);

            if isnumeric(deviceToSelectIdxOrDest)
               % If the deviceToSelectIdxOrDest is numeric, this means the
               % user either confirmed a device and needs to be taken back
               % to the device list (where they started from). We need to
               % show the running app view again
               obj.logAndSet("ShowDeviceListToolstripLayout", true);
               obj.CurrentPage = "RunningAppPage";

                % Refresh the device list front end
                obj.logAndSet("ShowDevicesInDevList",true);

                % Select the device by index (the first device or the
                % previously selected device depending on whether the user
                % cancelled or confirmed)
                obj.logAndSet("SelectDeviceByIndex", deviceToSelectIdxOrDest);
            else
                % If the deviceToSelectIdxOrDest is not numeric, that means
                % the user has cancelled and needs to go back to a specific
                % page where they started the add non enum device config
                % from
                switch(deviceToSelectIdxOrDest)
                    case "StartPage"
                        % Cleanup and create the the document with the
                        % uihtml for showing the landing page since the
                        % document was removed when we entered the add non
                        % enum device state
                        obj.logAndSet("ShowSingleDocumentLayout", true);

                        obj.logAndSet("ShowStartPage", true);
                        obj.CurrentPage = "StartPage";
                end
                obj.logAndSet("SetCollapseToolstrip", true);
            end

        end

        function handleUserDoneConfiguringDevice(obj, deviceToSelectObjOrSource)
            % Remove the modal pane from the device list and start showing
            % devices again. Removes any documents showing help for the non
            % enum device being configured

            % Remove any documents being shown
            obj.logAndSet("RemoveAllDocuments", true);

            % if device argument is an object, then the config was confirmed
            if ~isstring(deviceToSelectObjOrSource)
                % Show device list and main app
                obj.logAndSet("ShowDeviceListToolstripLayout", true);
                obj.CurrentPage = "RunningAppPage";
                
                % Refresh the device list front end
                obj.logAndSet("ShowDevicesInDevList",true);

                % Select the device and show applet
                obj.logAndSet("ShowAppletAfterConfiguring", deviceToSelectObjOrSource);
                return;
            end
            % if config is cancelled, device is a string representing where the
            % config event started
            switch(deviceToSelectObjOrSource)
                case "StartPage"
                    % Cleanup and create the the document with the
                    % uihtml for showing the landing page since the
                    % document was removed when we entered the configuration device state
                    obj.logAndSet("ShowSingleDocumentLayout", true);
                    obj.logAndSet("ShowStartPage", true);
                    obj.CurrentPage = "StartPage";
                    obj.logAndSet("SetCollapseToolstrip", true);
                case "RunningApp"
                    % If Config started from the running app device
                    % list, when cancelled, it will open the last
                    % selected device
                    obj.logAndSet("ShowDeviceListToolstripLayout", true);
                    obj.logAndSet("SelectDeviceByIndex", 0);
                    obj.CurrentPage = "RunningAppPage";
            end
        end

        function refreshHwmgrClientAppView(obj)
            % This method is invoked when the user clicks the refresh
            % button from the device list in the Client App View - which is
            % the view when the client app is running with the device list
            % panel on the side.
            id = obj.makeHwmgrBusy();
            oc = onCleanup(@()obj.removeHwmgrBusy(id));

            obj.logAndSet("CloseAllApplets", true);
            obj.logAndSet("RemoveAllDocuments", true);

            % Also remove any applet toolstrip tabs
            msgData = struct('IsUsingAppletTsTab', false, ...
                'AppletTsTab', []);
            obj.logAndSet("ReplaceAppletTsTab", msgData);

            % Give the usage logger instance to instrument the list of
            % devices
            doSoftLoad = false;
            obj.refreshHwmgr(doSoftLoad);
        end
        
        function addOnInstalledActions(obj)
            % This is the method that is invoked when an addon is installed
            % and hardware manager is notified by the installer (SSI or
            % product installer). Each controller specialization should
            % take context specific actions

            doSoftLoad = true;
            obj.refreshHwmgr(doSoftLoad);
        end

        function handleUserClosingSession(obj)
            % Close running applet
            obj.logAndSet("CloseAllApplets", true);

            % Remove the document
            obj.logAndSet("RemoveAllDocuments", true);

            % Deselect the device
            obj.logAndSet("DeselectDevice", true);

            % Remove the applet toolstrip tab
            msgData = struct('IsUsingAppletTsTab', false, ...
                'AppletTsTab', []);
            obj.logAndSet("ReplaceAppletTsTab", msgData);

            % Go back to the start page and update the current page
            obj.logAndSet("ShowSingleDocumentLayout", true);

            obj.logAndSet("ShowStartPage", true);
            obj.CurrentPage = "StartPage";
        end

        function handleDeviceSelectionChanged(obj, appletToLaunchOnDevChange)

            id = obj.makeHwmgrBusy();
            cleanup = onCleanup(@()obj.removeHwmgrBusy(id));

            obj.logAndSet("CloseAllApplets", true);

            obj.logAndSet("RemoveAllDocuments", true);

            % Launch the applet
            obj.logAndSet("ShowAppletForSelectedDevice", appletToLaunchOnDevChange);

        end

        function handleSelectDeviceOnStartPage(obj, deviceIndex)
            id = obj.makeHwmgrBusy();
            cleanup = onCleanup(@()obj.removeHwmgrBusy(id));
            % Change the layout of the window to show the device list
            obj.logAndSet("ShowDeviceListToolstripLayout", true);
            obj.CurrentPage = "RunningAppPage";

            obj.logAndSet("SetCollapseToolstrip", false);


            % Select the device and launch the app
            obj.logAndSet("DeviceSelectedOnStartPage", deviceIndex);
        end

        function handleRemoveDeviceOnStartPage(obj, msg)
            obj.logAndSet("DeviceRemovedOnStartPage", msg);
        end

        function handleUserRefreshingStartPage(obj)
            % Hard load plugins
            doSoftLoad = false;

            % Refresh HWMGR is actually just refreshing the device list
            % with enum and non enum devices (calls getDevices for enum
            % devices, and reload non enum devices from the users device
            % cache).
            obj.refreshHwmgr(doSoftLoad);
        end

        function handleEmptyDeviceList(obj, ~)
            % If the device list is empty, and the user was on the client
            % app running page/view, take the user back to the Landing
            % Page so they can start again.

            if obj.CurrentPage ~= "StartPage"
                % Show the single document layout for the landing page
                obj.logAndSet("ShowSingleDocumentLayout", true);
                % Load the landing page
                obj.logAndSet("ShowStartPage", true);
                obj.CurrentPage = "StartPage";
            end

        end

        function handleRegistrationFrameworkRefresh(obj)
            % Hard load plugins
            doSoftLoad = false;

            % Refresh the device list 
            obj.refreshHwmgr(doSoftLoad);
        end

        function handleSetToolstripForAppError(obj)
            obj.logAndSet("DisableClientToolstripArea", true);
        end

        function handleSelectDeviceAfterRefresh(obj)
            % Set the device selection priority to [-1 1] which means that
            % try to select the last used device if possible, and if not
            % possible select the first device in the list if the device
            % list is not empty
            obj.logAndSet("SelectDeviceByPriority", [-1 1]);
        end

        %-----------END Mediator Callbacks -----------%

        function delete(obj)
            % This will flush the DDUX data instrumented so far
            obj.logUsage();
        end
    end


    methods (Access = {?matlab.hwmgr.internal.MainController})

        function logUsage(obj)
            % Flush instrumented data to DDUX. This doesn't actually send
            % the data over to the server - DDUX sends the data on
            % ML shutdown
            try
                for i = 1:numel(obj.UsageLogger.DeviceData)
                    currDeviceData = obj.UsageLogger.DeviceData(i);
                    if ~isempty(obj.CustomUsageLoggingFcn)
                        obj.CustomUsageLoggingFcn(currDeviceData);
                    end
                    obj.UsageLogger.logDeviceListed(currDeviceData);
                end
            catch
                % Do nothing if flushing failed
            end
        end

    end

end
