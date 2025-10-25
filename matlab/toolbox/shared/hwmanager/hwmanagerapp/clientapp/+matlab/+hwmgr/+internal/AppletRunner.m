classdef AppletRunner < matlabshared.mediator.internal.Publisher &...
        matlabshared.mediator.internal.Subscriber & ...
        matlab.hwmgr.internal.MessageLogger
    %APPLETRUNNER This class manages the lifecycle of the currently running
    %application.

    %   Copyright 2017-2023 The MathWorks, Inc.

    properties
        %CURRENTDEVICE - Device currently selected
        CurrentDevice
        %RUNNINGAPPLET - Applet that is currently executing
        RunningApplet
        %RUNNINGAPPLETSTRUCT - The AppletStruct of the currently running
        % applet
        RunningAppletStruct
        %APPLETLIFECYCLEPROCESSING - Flag to applet life cycle processing
        %is currently in progress
        AppletLifecycleProcessing = false;
        % AppletCloseHook - function handle to function invoked by client
        % teams to request closing an applet
        AppletCloseHook
        % AppletConstructHook - Function to be called when the applet is
        % constructed and the applet tab is populated by the applet
        AppletConstructHook
        % AppletUsageData - the DDUX data to be sent back on the running
        % applet and the device
        AppletUsageData
        % AppletRelations - a struct of related handles:
        % Device, Applet, Document, Toolstrip Tab
        AppletRelations
        % AppletProviders - an array of
        % matlab.hwmgr.internal.AppletProviderBase objects received from
        % the plugin module
        AppletProviders
        % NewAppletTsTab - A blank toolstrip tab received from the
        % Toolstrip module. This toolstrip tab is given to the next client
        % app that will be run
        NewAppletTsTab
        % NewFigDoc - A blank figure document with a grid and a panel
        % inside it received from the HwmgrWindow. This is the document
        % that will be used by the next client app that will be run
        NewFigDoc
        % NewClientPanel - A blank panel received from the HwmgrWindow that
        % will be given to the next client app for placing app widgets
        % inside it
        NewClientPanel
        % The handle to the dialog parent receieved from the window module
        DialogParentResponse
        % Property for storing the return value of contextual toolstrip
        % invoker methods.
        ContextTabControlReturnVal
    end

    properties (SetObservable)
        % Run the following command to see listeners for these properties:
        % matlab.hwmgr.internal.util.displayPropListeners('matlab.hwmgr.internal.AppletRunner');
        CanCloseResponse
        LaunchAppletRequest
        DeviceForDocResponse
        AppletFocusRequest
        AppClosedDueToError
        LaunchedAppDocTitleReady
        LaunchedAppNameReady
        LaunchedAppFigureReady
        LaunchedAppTsTabReady
        AppletClosedForDocument
        AppDduxDataForDevice
        AppletAllowMultipleInstances
        SetToolstripForAppError
        DialogParentRequest
        RemoveClientSidePanels
        AddContextTab
        ShowContextTab
        RemoveContextTab
        RemoveAllContextTabs
    end

    methods (Static)
        function out = getPropsAndCallbacks()
            out = ... % Property to listen to         % Callback function
                [
                "CanRemoveDeviceRequest"        "handleCanRemoveDeviceRequest";...
                "CanCloseAppletDocRequest"      "handleCanCloseAppletDocRequest"; ...
                "CloseAppletForDoc"             "closeAppletForDoc"; ...
                "CloseAppletForDevice"          "closeAppletForDevice"; ...
                "SelectedDeviceUpdate"          "setSelectedDevice"; ...
                "ShowAppletForSelectedDevice"   "showAppletForSelectedDevice"; ...
                "DeviceForDocRequest"           "handleDeviceForDocRequest"; ...
                "NewAppletTsTab"                "setNewAppletTsTab"; ...
                "NewFigDocReady"                "handleNewFigDocReady"; ...
                "NewClientPanelReady"           "handleNewClientPanelReady"; ...
                "ConstructAndLaunchNewApplet"   "constructAndLaunchNewApplet"; ...
                "DialogParentResponse"          "handleDialogParentResponse"; ...
                "ContextTabControlReturnVal"    "setContextTabControlReturnValue";...
                ];

        end

        function out = getPropsAndCallbacksNoArgs()
            out = ... % Property to listen to         % Callback function
                ["CanCloseHwmgrWindowRequest"   "handleCanCloseHwmgrWindowRequest"; ...
                "CloseAllApplets"               "closeAllApplets"; ...
                "CanRefreshRequest"             "handleCanRefreshRequest"; ...
                "CanConfigDeviceRequest"        "handleCanConfigDeviceRequest"; ...
                "CanChangeDeviceRequest"        "handleCanChangeDeviceRequest"; ...
                "CanCloseSessionRequest"        "handleCanCloseSessionRequest";...
                ];
        end
    end

    methods (Access = public)

        function obj = AppletRunner(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
        end

        function subscribeToMediatorProperties(obj, ~, ~)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);

            eventsAndCallbacksNoArgs = obj.getPropsAndCallbacksNoArgs();
            obj.subscribeWithGatewaysNoArgs(eventsAndCallbacksNoArgs, @obj.subscribe);
        end

        % %%%%%%%%% CALLBACKS %%%%%%%%%% %
        function closeAllApplets(obj)
            appletsToClose = obj.RunningApplet;
            for i = 1:numel(obj.RunningApplet)
                obj.closeRunningAppletHandler(appletsToClose(i));
            end

            % Even if there are no applets to close, it is possible that
            % there are one or more applet relations (e.g: an app error
            % message containing figure document). As such, clean up the
            % applet relations here
            obj.AppletRelations = [];
        end

        function closeAppletForDoc(obj, appletDoc)
            relatedHandles = obj.getAppletRelationsFor(appletDoc, "Document");
            if ~isempty(relatedHandles)
                obj.closeRunningAppletHandler(relatedHandles.Applet);
            end
        end

        function closeAppletForDevice(obj, device)
            [relatedHandles, relationIndex] = obj.getAppletRelationsFor(device, "DeviceInfo");

            if isempty(relatedHandles)
                % Device has no applet running - nothing to do
                return;
            end

            % Check if the relatedHandles.Applet is empty, which means an
            % applet didn't even get constructed and errored out.
            % Alternatively, check if relatedHandles.Applet is valid since
            % an app initiated close can cause the applet to be destroyed
            % and relatedHandles.Applet would have a deleted handle
            if isempty(relatedHandles(relationIndex).Applet) || ~isvalid(relatedHandles(relationIndex).Applet)
                % If there are relatedHandles for a device, but there is no
                % applet, then we must be in an app initiated close sequence
                % where the app was closed from itself. The device for the once
                % running app is now being removed so clear the AppletRelations
                % for the device
                obj.AppletRelations(relationIndex) = [];
            else
                % Device has applet running for it - close the applet and
                % signal main controller for applet figure document removal
                obj.closeRunningAppletHandler(relatedHandles.Applet);
            end

            relatedHandles.Document.CanCloseFcn = function_handle.empty;

            obj.logAndSet("AppletClosedForDocument", relatedHandles.Document);
        end

        function setSelectedDevice(obj, device)
            %If there is a currently running applet we need to destroy
            %it first
            obj.CurrentDevice = device;
        end

        function showAppletForSelectedDevice(obj, appletStruct)
            % Find applet for given device, If found send focus data
            [relatedHandles, ~] = obj.getAppletRelationsFor(obj.CurrentDevice, 'DeviceInfo');

            if isempty(relatedHandles)
                % Add the grouptag for identifying the document and
                % toolstrip tab
                groupTag = string(appletStruct.AppletName) + obj.CurrentDevice.FriendlyName + obj.CurrentDevice.UUID;
                appletStruct.GroupTag = groupTag;

                % Signal the main controller to initiate a new applet launch
                % by creating a new figure document and client panel
                obj.logAndSet("LaunchAppletRequest", appletStruct);
            else
                msgData = struct('Document', relatedHandles.Document, ...
                    'AppletTsTab', relatedHandles.ToolstripTabHandle);
                obj.logAndSet("AppletFocusRequest",  msgData);
            end
        end

        function handleDeviceForDocRequest(obj, document)

            for i= 1:numel(obj.AppletRelations)
                if obj.AppletRelations(i).Document == document
                    obj.logAndSet("DeviceForDocResponse", obj.AppletRelations(i).DeviceInfo);
                    break;
                end
            end
        end

        function setNewAppletTsTab(obj, newTab)
            obj.NewAppletTsTab = newTab;
        end

        function handleNewFigDocReady(obj, newDoc)
            obj.NewFigDoc = newDoc;
        end

        function handleNewClientPanelReady(obj, newPanel)
            obj.NewClientPanel = newPanel;
        end

        function constructAndLaunchNewApplet(obj, appletToRun)

            appletStruct = appletToRun;

            try
                % Instantiate the applet object first. This is so that we
                % can initialize the view struct before the applet life
                % cycle begins since we may need to cleanup before the
                % doAppletLifeCycle method returns (e.g:
                % applet close during lifecycle, applet error
                % during lifecycle)

                appletCloseFcn = @(closeReason, runningApplet)obj.appletInitiatedClose(closeReason, runningApplet);

                bringToFrontFcn = @(applet)obj.appletBringToFrontHook(applet);

                makeWindowBusyFcn = @(isBusy)obj.appletMakeWindowBusyHook(isBusy);

                obj.logAndSet("DialogParentRequest", true);

                % The hooks are not required for the applet interface class
                % constructor used by client teams and as such are not
                % part of the applet struct. However, they are necessary to
                % be set by the framework for correct functioning of the
                % applet.

                runningApplet = obj.instantiateApplet(appletStruct, bringToFrontFcn, appletCloseFcn, makeWindowBusyFcn);
                

                % Get the AllowMultipleInstances flag and send it to the
                % device list
                allowMultiInstance = runningApplet.AllowMultipleInstances;
                obj.logAndSet("AppletAllowMultipleInstances", allowMultiInstance);

                obj.doAppletLifeCycle(runningApplet, appletStruct);
            catch ex
                % If there was a hard error thrown, capture the error
                % information before rethrowing the error
                obj.logAndSet("AppDduxDataForDevice", obj.AppletUsageData);
                rethrow(ex);
            end

            % Add running applet information to the list of device
            % information we have from the device list
            obj.logAndSet("AppDduxDataForDevice", obj.AppletUsageData);
        end

        function handleDialogParentResponse(obj, dialogParent)
            obj.DialogParentResponse = dialogParent;
        end

        % --- BEGIN CanClose Queries ---%

        function handleCanChangeDeviceRequest(obj)
            closeReason = matlab.hwmgr.internal.AppletClosingReason.DeviceChange;
            canClose = obj.canAppletsCloseForReason(closeReason);

            obj.logAndSet('CanCloseResponse', canClose);
        end


        function handleCanCloseHwmgrWindowRequest(obj)
            closeReason = matlab.hwmgr.internal.AppletClosingReason.AppClosing;
            canClose = obj.canAppletsCloseForReason(closeReason);

            obj.logAndSet('CanCloseResponse', canClose);
        end

        function handleCanCloseAppletDocRequest(obj, appletDoc)


            [relatedHandles, index] = obj.getAppletRelationsFor(appletDoc, 'Document');
            appletToAsk = relatedHandles.Applet;

            % If an applet was found, ask if canClose. Otherwise, assume
            % applet has been closed already and return true
            if isvalid(appletToAsk)
                closeReason = matlab.hwmgr.internal.AppletClosingReason.CloseRunningApplet;

                canClose = obj.canCloseRunningAppletHandler(closeReason, false, appletToAsk);
            else
                % Applet was closed - allow document to close and remove
                % applet relations since the document is about to be
                % closed.
                canClose = true;
                obj.AppletRelations(index) = [];
            end

            obj.logAndSet('CanCloseResponse', canClose);
        end

        function handleCanRefreshRequest(obj)
            closeReason = matlab.hwmgr.internal.AppletClosingReason.RefreshHardware;
            canClose = obj.canAppletsCloseForReason(closeReason);

            obj.logAndSet('CanCloseResponse', canClose);
        end

        function handleCanConfigDeviceRequest(obj)
            closeReason = matlab.hwmgr.internal.AppletClosingReason.CloseRunningApplet;
            canClose = obj.canAppletsCloseForReason(closeReason);

            obj.logAndSet('CanCloseResponse', canClose);
        end

        function handleCanCloseSessionRequest(obj)
            closeReason = matlab.hwmgr.internal.AppletClosingReason.CloseRunningApplet;
            canClose = obj.canAppletsCloseForReason(closeReason);

            obj.logAndSet('CanCloseResponse', canClose);
        end

        function handleCanRemoveDeviceRequest(obj, device)
            closeReason = matlab.hwmgr.internal.AppletClosingReason.DeviceRemove;
            relatedHandles = obj.getAppletRelationsFor(device, 'DeviceInfo');
            if isempty(relatedHandles)
                % Device has no applet running - can close
                canClose = true;
            else
                % Device has apple running - ask applet can close
                canClose = obj.canCloseRunningAppletHandler(closeReason, false, relatedHandles.Applet);
            end
            obj.logAndSet('CanCloseResponse', canClose);
        end
        % --- END Can Close Queries ---%

        function appletMakeWindowBusyHook(obj, isBusy)
            obj.DialogParentResponse.Busy = isBusy;
        end

        function dlgParent = appletBringToFrontHook(obj, applet)
            relatedHandles = obj.getAppletRelationsFor(applet, 'Applet');
            dlgParent = relatedHandles.Document.Figure;
            msgData = struct('Document', relatedHandles.Document, ...
                'AppletTsTab', relatedHandles.ToolstripTabHandle);
            obj.logAndSet("AppletFocusRequest",  msgData);
        end

        function appletInitiatedClose(obj, closeReason, applet)
            % This is the app close callback that gets invoked as a result
            % of an applet invoking its closeApplet() API method.

            % Get the related handles for the applet - we'll need it later
            % for removal
            [relatedHandles, index] = obj.getAppletRelationsFor(applet, 'Applet');

            isAppRunning = applet.AppletState == "Run";
            if isAppRunning && ~isempty(relatedHandles)
                % Bring the app whose callback is being serviced and its device
                % to focus via a device selection change
                obj.appletBringToFrontHook(applet);
            end

            % Grab the applet title before it's closed - it may be needed
            % later to show an app failure message
            appletName = applet.DisplayName;

            % Check if the applet tab is being used by the applet
            isUsingAppletTab = applet.isAppletTabVisible();

            % First thing is to close the applet close method. Note that
            % this is not a forced close - the applet may want to initiate
            % a non-forced close to the user.
            canClose = obj.canCloseRunningAppletHandler(closeReason, false, applet);

            if ~canClose
                return;
            end

            % Once the applet is closed, the document is not cleaned up
            % yet. Either show the AppError message if the app crashed, or
            % remove the view otherwise.

            obj.closeRunningAppletHandler(applet);

            % Check if the app being closed is using a toolstrip tab
            if isUsingAppletTab
                % If the app is closing for app error, then signal the
                % ClientAppController to modify the applet toolstrip tab
                % accordingly
                if closeReason.isAppError
                    obj.logAndSet("SetToolstripForAppError", true);
                else
                % Standard close: Signal the Toolstrip module to remove the
                % existing applet ts tab
                    msgData = struct('IsUsingAppletTsTab', false, ...
                        'AppletTsTab', []);
                    obj.logAndSet("LaunchedAppTsTabReady", msgData);
                end
            end

            if closeReason.isAppError
                % If the appCloseCallback due to error was initiated by
                % the applet during one of the life cycle hooks, the
                % post-applet-run hook may have not gotten a chance to
                % run to update the title, so we need update the title
                % of the document/view here
                newDocTitle = appletName + " - " +  obj.CurrentDevice.FriendlyName;


                % Show the app failure message
                msgData = struct('Document',obj.NewFigDoc, ...
                    'AppletName', appletName, ...
                    'DeviceName', obj.CurrentDevice.FriendlyName);
                obj.logAndSet("AppClosedDueToError", msgData);

                msgData = struct('Document', obj.NewFigDoc, ...
                    'Title', newDocTitle);
                obj.logAndSet("LaunchedAppDocTitleReady", msgData);
            else
                % Standard applet-document close. If there are other
                % applets running, AppContainer will automatically
                % select the previosly focused applet. If there is only
                % one applet running and no previously focused applet,
                % currently an empty document area will be shown. When
                % standalone HWMGR is enabled this needs more design.
                obj.logAndSet("AppletClosedForDocument", obj.NewFigDoc);
            end

        end
        
        % ------ Context Tab Methods ------ %
    
        % Set return value for context tab control invoker methods.
        function setContextTabControlReturnValue(obj, value)
            obj.ContextTabControlReturnVal = value;
        end

        function result = addContextTab(obj, tab, index)
            args = struct("Tab", tab, "Index", index);
            obj.logAndSet("AddContextTab", args);
            result = obj.ContextTabControlReturnVal;
        end

        function result = showContextTab(obj, tab)
            obj.logAndSet("ShowContextTab", tab);
            result = obj.ContextTabControlReturnVal;
        end

        function result = removeContextTab(obj, tab)
            obj.logAndSet("RemoveContextTab", tab);
            result = obj.ContextTabControlReturnVal;
        end

        function removeAllContextTabs(obj)
            obj.logAndSet("RemoveAllContextTabs", true);
        end

        % ------ End Context Tab Methods ------ %

        % %%%%%%%%% END CALLBACKS %%%%%%%%%% %
    end

    methods (Access = ?matlab.unittest.TestCase)
        function autoLoadDataForApplet(obj, appletObj)

            % Load the data saved for all apps
            allAppDataMap = obj.getAllAutoSavedData(appletObj);

            % Get any data saved for auto-load
            autoLoadedData = [];
            if ~isempty(allAppDataMap) && allAppDataMap.isKey(class(appletObj))
                autoLoadedData = allAppDataMap(class(appletObj));
            end

            if ~isempty(autoLoadedData)
                appletObj.AutoLoadedData =  autoLoadedData;
            end
        end

        function destroyRunningApplet(obj, runningApplet)
            % Invoke the destroy() hook to allow the applet to perform any
            % necessary cleanup actions

            % Save any data for loading the next time the applet is run
            obj.saveAppletAutoLoadData(runningApplet);

            for i = 1:numel(obj.RunningApplet)
                if obj.RunningApplet(i) == runningApplet
                    obj.RunningApplet(i)= [];
                    obj.AppletRelations(i) = [];
                    obj.RunningAppletStruct(i) = [];
                    break;
                end
            end

            runningApplet.destroy();

            % Ask the HWMGR window to remove any panels. We do this after
            % the destroy so that all resources needed by the app during
            % destroy are available.
            obj.logAndSet("RemoveClientSidePanels", true);



            % Delete the applet
            delete(runningApplet);

        end

        function saveAppletAutoLoadData(obj, runningApplet)
            % This method will save any data specified by the running
            % applet for auto load

            % If there isn't any data specified, do nothing and return
            if isempty(runningApplet.SaveOnDestroyData)
                return;
            end

            import matlab.hwmgr.internal.util.PrefDataHandler;

            % Get all apps saved data for concatenation
            allAppSavedDatMap = obj.getAllAutoSavedData(runningApplet);

            % Initialize the map used to save all Hardware Manager applet
            % autosave data if it doesn't exist
            if isempty(allAppSavedDatMap)
                allAppSavedDatMap = containers.Map();
            end

            % Update map with the current applet's specified data to save
            allAppSavedDatMap(class(runningApplet)) = runningApplet.SaveOnDestroyData;

            % Write the data out to file
            PrefDataHandler.writeAppConfigDataToCache(allAppSavedDatMap);
        end

        function [allSavedData, errorID] = getAllAutoSavedData(obj, appletObj)
            import matlab.hwmgr.internal.util.PrefDataHandler;

            [allSavedData, errorID] = PrefDataHandler.loadAppConfigDataFromCache();

            % For now, we solve geck 2923958 by deleting the cache file if any error is generated while
            % loading the devices from file. Alert the user without disrupting the workflow. 
            if ~isempty(errorID)
                matlab.hwmgr.internal.util.PrefDataHandler.deleteCacheFile();
            
                title = string(message('hwmanagerapp:devicelist:DeviceConfigErrorDialogTitle').getString);
                msg = string(message('hwmanagerapp:devicelist:DeviceConfigErrorDialogMsg').getString);
                appletObj.showError(title, msg);
            end
        end
    end

    methods (Access = ?hwmgr.AppletRunnerTester)

        function appletClosed = canCloseRunningAppletHandler(obj, closeReason, forceClose, appletObj)
            appletClosed = true;

            if isempty(obj.RunningApplet)
                return;
            end

            if ~forceClose && isempty(closeReason)
                error(message('hwmanagerapp:framework:UnknownCloseReason'));
            end

            if ~forceClose && ~appletObj.canClose(closeReason)
                appletClosed = false;
                return;
            end
        end

        function closeRunningAppletHandler(obj, appletObj)
            % It's possible that the applet is already deleted so there is
            % nothing to do on destroy
            if isvalid(appletObj)
                obj.destroyRunningApplet(appletObj);
            end
        end

        function canClose = canAppletsCloseForReason(obj, reason)
            forceClose = false;

            canCloseResults = false(1,numel(obj.RunningApplet));
            for i = 1:numel(obj.RunningApplet)
                okayToClose = obj.canCloseRunningAppletHandler(reason, forceClose, obj.RunningApplet(i));
                canCloseResults(i) = okayToClose;
                % If a veto was received, don't ask the user again for the
                % remaining apps
                if ~okayToClose
                    break;
                end
            end

            canClose = all(canCloseResults);
        end

    end

    methods (Access = private)

        function [relatedHandles, index] = getAppletRelationsFor(obj, resource, resourceType)
            relatedHandles = [];
            for index = 1:numel(obj.AppletRelations)
                if obj.AppletRelations(index).(resourceType) == resource
                    relatedHandles = obj.AppletRelations(index);
                    break;
                end
            end
        end

        function onAppletConstruct(obj, figDoc, useAppletTab, appletTitle, deviceName, appletTab)

            obj.logAndSet("LaunchedAppNameReady", appletTitle);

            newDocTitle = appletTitle + " - " +  deviceName;

            msgData = struct('Document', figDoc, ...
                'Title', newDocTitle);
            obj.logAndSet("LaunchedAppDocTitleReady", msgData);

            obj.logAndSet("LaunchedAppFigureReady", figDoc.Figure);

            msgData = struct('IsUsingAppletTsTab', useAppletTab, ...
                'AppletTsTab', appletTab);

            obj.logAndSet("LaunchedAppTsTabReady", msgData);
        end

        function appletObj = instantiateApplet(obj, appletStruct, bringToFrontFcn, appletCloseFcn, makeWindowBusyFcn)
            % Method that instantiates the applet class given the
            % appletStruct

            % Instantiate the applet class and return it
            appletObj  = feval(appletStruct.Constructor);

            % Set the bring to front function
            appletObj.setBringToFrontFcn(bringToFrontFcn);

            % Set the closing function for when applets want to signal
            % a close
            appletObj.setCloseAppletFcn(appletCloseFcn);

            % Set the dialog parent so client teams can show dialogs using
            % the ML dialog APIs. Note that this is a temporary solution
            % until we can provide a more robust dialog API
            appletObj.setDialogParent(obj.DialogParentResponse);

            % Set the make window busy hook. This will allow client app
            % teams to be able to make hwmgr busy and remove busy
            appletObj.setMakeWindowBusyFcn(makeWindowBusyFcn)

            % Capture the device and applet usage data
            obj.AppletUsageData = matlab.hwmgr.internal.UsageLogger.extractDeviceData(obj.CurrentDevice, ...
                "", ... % Leave UUID blank since we do not know it here. It will be added later by the logger
                appletStruct.AppletName, ...
                func2str(appletStruct.Constructor), ...
                "success", ...
                "");
        end

        function appletObj = doAppletLifeCycle(obj, appletObj, appletStruct)
            % Set the cannot close flag so all hardware manager close
            % requests are vetoed
            obj.AppletLifecycleProcessing = true;

            assert( ~isempty(obj.CurrentDevice),...
                'Attempt to launch Applet without current device');

            % Capture function handles for Context Tab control to pass to
            % Applet.
            contextualTabControlFcns = struct(...
                'addContextTab',              @obj.addContextTab,...
                'showContextTab',             @obj.showContextTab,...
                'removeContextTab',           @obj.removeContextTab,...
                'removeAllContextTabs',       @obj.removeAllContextTabs...
                );

            % Set the applet relations before running any of the applet
            % lifecycle hooks - this is so that the applet can call the
            % dialog APIs from any of the hooks
            initStruct = struct( ...
                'ToolstripTabHandle',       obj.NewAppletTsTab,...
                'RootWindow',               obj.NewClientPanel,...
                'DeviceInfo',               obj.CurrentDevice,...
                'ContextualTabControlFcns', contextualTabControlFcns...
                );

            relatedHandles = initStruct;
            relatedHandles.Document = obj.NewFigDoc;
            relatedHandles.Applet = appletObj;

            obj.AppletRelations = [obj.AppletRelations; relatedHandles];


            try
                % Ensure applet is of the right type
                validateattributes(appletObj,...
                    {'matlab.hwmgr.internal.AppletBase'},...
                    {'scalar'});

                obj.autoLoadDataForApplet(appletObj);

                % Invoke the init hook
                appletObj.AppletState = 'Init';

                appletObj.init(initStruct);

                % Invoke the construct hook if the applet hasn't closed
                % itself already using closeApplet() during init
                if isvalid(appletObj)
                    appletObj.AppletState = 'Construct';
                    appletObj.construct();
                end

                % Invoke the run hook if the applet hasn't closed itself
                % already using closeApplet() during construct
                if isvalid(appletObj)
                    tabVisibleFlag = appletObj.isAppletTabVisible();
                    obj.onAppletConstruct(obj.NewFigDoc, tabVisibleFlag, appletObj.DisplayName, obj.CurrentDevice.FriendlyName, obj.NewAppletTsTab);
                    appletObj.AppletState = 'Run';
                    appletObj.run();
                end

                if isvalid(appletObj)
                    % Applet successfully running - update the list of
                    % running applets and related handles
                    obj.RunningApplet = [obj.RunningApplet; appletObj;];
                    obj.RunningAppletStruct = [obj.RunningAppletStruct; appletStruct;];
                end

                % Reset the close flag
                obj.AppletLifecycleProcessing = false;


            catch ex

                % Remove the applet relations struct entry since the applet
                % failed to load
                obj.AppletRelations(end) = [];

                % Reset the close flag
                obj.AppletLifecycleProcessing = false;


                % Capture the error usage data
                runResult = "Error: " + string(ex.identifier);
                runErrMsg = string(ex.message);
                obj.AppletUsageData = matlab.hwmgr.internal.UsageLogger.extractDeviceData(obj.CurrentDevice, ...
                    "", ...
                    appletStruct.AppletName, ...
                    func2str(appletStruct.Constructor), ...
                    runResult, ...
                    runErrMsg);


                % Default exception
                errorMessage = 'Internal Error: Exception thrown while loading applet';

                % Two categories of exceptions: Wrong applet interface type
                % and exception thrown while loading applet
                if strcmp(ex.identifier, 'MATLAB:invalidType')
                    errorMessage = 'Internal Error: Applet is not a supported Hardware Manager Applet';
                elseif isvalid(appletObj)
                    obj.destroyRunningApplet(appletObj);

                end
                newException = MException('hwmanagerapp:framework:AppletInternalError', errorMessage);
                addCause(ex, newException);
                rethrow(ex);
            end
        end

        
    end

end