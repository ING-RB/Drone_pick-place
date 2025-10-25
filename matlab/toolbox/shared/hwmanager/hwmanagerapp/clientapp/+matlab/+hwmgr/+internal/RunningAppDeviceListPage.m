classdef RunningAppDeviceListPage < matlabshared.mediator.internal.Publisher &...
        matlabshared.mediator.internal.Subscriber & ...
        matlab.hwmgr.internal.MessageLogger
    % RUNNINGAPPDEVICELISTPAGE - Back-end class for the device list that is
    % shown in a side panel alongside a running app instance.
    %
    % This class is responsible for communicating with the device list
    % front end that sits in the appcontainer side panel. The device list
    % "model" class commuicates with this "view" class.

    %   Copyright 2021-2024 The MathWorks, Inc.


    properties(Access = {?matlab.unittest.TestCase})
        % STATICCHANNEL - the name of the static channel being used in the
        % connector message service
        StaticChannel = '/HWF/devicelist'

        % PANEL - Handle to the device list panel
        Panel

        % MESSAGEHANDLER - Handler of connector communication with client (JS)
        MessageHandler
    end

    properties
        % Client App context. This is needed to know the running applet
        % class name
        Context
                
        % List of devices to send to the front end
        DevicesToShow
        
        % Index of the currently selected device
        SelectedDeviceIndex 

        % The currently selected device
        SelectedDevice
        

        % Result of the query for a Device object whose index was provided
        DeviceByIndexResponse

        % Response from the Applet Runner module as to whether the running
        % app instance can be closed
        CanCloseResponse

        % Response from the Client App Window as to whether the user chose
        % "Cancel" or "OK" for the can close dialog shown for removing a
        % device that is not selected/does not have an app instance running
        % for it
        ShowWindowConfirmationResponse

        % Logical flag to indicate whether the app specified context menu
        % items to lauch in new window has been created and applied on the
        % device cards in the front end. This flag is used to ensure that
        % the context menu object is created and applied only once per
        % refresh of the device list
        IsAllowMultipleInstancesMenuApplied (1,1) logical
    end

    properties(SetObservable)
        SelectDeviceByIndex
        ShowWindowConfirmationDlg
        RequestSelectedDeviceIndex
        RequestSelectedDevice
        RequestDeviceByIndex
        CanChangeDeviceRequest
        CanRefreshRequest
        CanRemoveDeviceRequest
        RemoveDeviceByIndex
        UserRefreshingHwmgrDeviceList
        SelectDeviceAfterRefresh
        RunningAppClientId
        UserConfigureDeviceInRunningApp
    end

    methods (Static)

        function flag = isDebugWebApp()
            flag = strcmp(getenv('HWMGR_DEVLIST_DEBUG'), 'true');
        end

        % ----------------------------------------------------------
        % Mediator subscriber/listener mappings
        %-----------------------------------------------------------
        function out = getPropsAndCallbacks()
            out  = ...
                ... % Property to listen to         % Callback function
                ["AddDeviceListPanelReady"           "handleAddDeviceListPanelReady";... 
                "CanCloseResponse"                   "handleCanCloseResponse"; ...
                "ShowWindowConfirmationResponse"     "handleShowWindowConfirmationResponse";
                "DevicesAvailableToShow"             "handleDevicesAvailableToShow"; ...
                "SelectedDeviceIndexResponse"        "handleSelectedDeviceIndexResponse"; ...
                "SelectedDeviceResponse"             "handleSelectedDeviceResponse"; ...
                "DeviceByIndexResponse"              "handleDeviceByIndexResponse"; ...
                "AppletAllowMultipleInstances"       "handleAppletAllowMultipleInstances";...
                "SelectDeviceInView"                 "selectDeviceInView"; ...
                ];

        end

        function out = getPropsAndCallbacksNoArgs()
            out  = ...
                ... % Property to listen to         % Callback function
                [
                "ShowDevicesInDevList"              "showDevicesInDevList";...
                "DisableDeviceList"                 "disableDeviceList";...
                "EnableDeviceList"                  "enableDeviceList"; ...
                "ReloadDeviceListFrontEnd"          "refreshView"; ...
                "ShowLoadingInDevList"              "showLoadingInDevList"; ...
                "RequestRunningAppClientId"         "setRunningAppClientId"; ...
                ];
        end
    end

    methods

        % ----------------------------------------------------------
        % Constructor and initialization methods
        %-----------------------------------------------------------
        function obj = RunningAppDeviceListPage(mediator)
            arguments
                % Default value for mediator to allow for mocking in unit
                % tests
                mediator = matlabshared.mediator.internal.Mediator;
            end

            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);

            obj.MessageHandler = matlab.hwmgr.internal.MessageHandler(obj.StaticChannel);

            obj.MessageHandler.setSubject(obj);
            obj.subscribeToClientActions();
            obj.IsAllowMultipleInstancesMenuApplied = false;
        end

        function subscribeToMediatorProperties(obj, ~, ~)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);

            eventsAndCallbacksNoArgs = obj.getPropsAndCallbacksNoArgs();
            obj.subscribeWithGatewaysNoArgs(eventsAndCallbacksNoArgs, @obj.subscribe);
        end

        function subscribeToClientActions(obj)
            obj.MessageHandler.subscribe("clientSelectDevice");
            obj.MessageHandler.subscribe("clientRemoveDevice");
            obj.MessageHandler.subscribe("clientRefresh");
            obj.MessageHandler.subscribe("clientRightClickDevice");
            obj.MessageHandler.subscribe("clientConfigureDevice");
        end

        function loadView(obj)
            obj.MessageHandler.clearCachedMessages();
            obj.MessageHandler.resetPubSubReady();
            obj.MessageHandler.publish('setViewModes', struct("ShowInstalledAddOns", false, "ShowInPanel", true));
            obj.refreshView();
        end


        % ----------------------------------------------------------
        % Front-end callbacks
        %-----------------------------------------------------------

        function clientSelectDevice(obj, msg)
            % Find the corresponding MATLAB device for the JS device index
            jsDevice = msg;
            deviceIndex = jsDevice.Uuid + 1;
            
            obj.logAndSet("RequestSelectedDeviceIndex", true);

            % If the same device is selected, do nothing
            if isequal(obj.SelectedDeviceIndex, deviceIndex)
                return;
            end
            
            % Temporarily disable device list to avoid it being clicked in
            % quick succesion when an applet is being loaded. This will
            % avoid adding and removing toolstrip tabs in quick succession
            % which causes error.
            obj.disableDeviceList();

            % Ask the AppletRunner module if it is okay to close
            % any currently running applet and broadcast a
            % DeviceSelected event to all the modules

            obj.logAndSet("CanChangeDeviceRequest", true);

            if obj.CanCloseResponse
                obj.logAndSet("SelectDeviceByIndex", deviceIndex);

                % Fire off a message to the VIEW (web app) to highlight the selected
                % device
                obj.selectDeviceInView(deviceIndex);


                % Since device selection makes the HWMGR app busy in the
                % client app context, it's possible the framework has been
                % destroyed by the UI's close callback at this point.
                if ~isvalid(obj)
                    return;
                end
            else
                obj.selectDeviceInView(obj.SelectedDeviceIndex);
            end

            % Enable device list after callback is handled and applet is
            % launched
            obj.enableDeviceList();
        end

        function clientConfigureDevice(obj, msg)
            % Find the corresponding MATLAB device for the JS device index
            jsDevice = msg;
            deviceIndex = jsDevice.Uuid + 1;

            % Temporarily disable device list to avoid it being clicked in
            % quick succesion when an applet is being loaded. This will
            % avoid adding and removing toolstrip tabs in quick succession
            % which causes error.
            obj.disableDeviceList();

            obj.logAndSet("CanChangeDeviceRequest", true);
            if obj.CanCloseResponse
                % Send a message that configure has been clicked from the
                % running app device list
                obj.logAndSet('UserConfigureDeviceInRunningApp', {deviceIndex, obj.Context.AppletClass});
            end
            % Enable device list after callback is handled and applet is
            % launched
            obj.enableDeviceList();
        end

        function clientRemoveDevice(obj, msg)
            % Remove the device with the given index
            % First convert the JS zero based index to ML based
            % index
            jsDevice = msg;
            deviceIndex = jsDevice.Uuid + 1;

            % Temporarily disable device list for callback to complete then
            % enable device list
            obj.disableDeviceList();
            obj.askAndRemoveDevice(deviceIndex);
            obj.enableDeviceList();
            % Reset the IsAllowMultipleInstancesMenuApplied flag
            obj.IsAllowMultipleInstancesMenuApplied = false;

        end

        function clientRefresh(obj, ~)
            closeReason = matlab.hwmgr.internal.AppletClosingReason.RefreshHardware;
            obj.logAndSet("CanRefreshRequest", closeReason);

            if obj.CanCloseResponse
                obj.logAndSet("UserRefreshingHwmgrDeviceList", true);
            end

            obj.logAndSet("SelectDeviceAfterRefresh", true);
        end

        function clientRightClickDevice(obj, msg)
            obj.logAndSet("RequestDeviceByIndex", msg.Uuid + 1);
            % Right click open in new window should always do a soft load so
            % that the parent app is not affected by a hard refresh
            doSoftLoad = true;
            matlab.hwmgr.internal.launchAppletForDevice(obj.Context.AppletClass, obj.Context.PluginClass, obj.DeviceByIndexResponse, doSoftLoad);
        end

        % ----------------------------------------------------------
        % Mediator callbacks
        %-----------------------------------------------------------

        function handleAddDeviceListPanelReady(obj, panel)
            % Device list panel is rendered and ready
            obj.Panel = panel;
            obj.loadView();
        end

        function handleShowWindowConfirmationResponse(obj, response)
            obj.ShowWindowConfirmationResponse = response;
        end

        function handleDevicesAvailableToShow(obj, devices)
            obj.DevicesToShow = devices;
            % Whenever the device list "model" provides new devices, flush
            % these devices to the front end to show the user.
            obj.refreshView();
        end

        function handleSelectedDeviceIndexResponse(obj, index)
            obj.SelectedDeviceIndex = index;
        end

        function handleSelectedDeviceResponse(obj, device)
            obj.SelectedDevice = device;
        end

        function handleDeviceByIndexResponse(obj, device)
            obj.DeviceByIndexResponse = device;
        end

        function handleCanCloseResponse(obj, response)
            obj.CanCloseResponse = response;
        end

        function handleAppletAllowMultipleInstances(obj, flag)
            % Check the IsAllowMultipleInstancesMenuApplied flag to ensure
            % the device cards are only decorated once with the context
            % menu
            if ~obj.IsAllowMultipleInstancesMenuApplied
                obj.setLaunchInNewWindowMenu(flag);
                obj.IsAllowMultipleInstancesMenuApplied = true;
            end
        end

        function setRunningAppClientId(obj)
            % Publish ClientId for MessageClient to be used for
            % communication with front end (needed by Device List Panel)
            obj.RunningAppClientId = obj.MessageHandler.ClientId;
        end


        % ----------------------------------------------------------
        % Front - end manipulation methods
        %-----------------------------------------------------------

        function showLoadingInDevList(obj)
            % Prepare and publish a message to send
            % to the device list web application to show a "loading" message
            % while a list of devices is being gathered
            obj.MessageHandler.publish("showLoading");
        end

        function disableDeviceList(obj)
            % Send command to JS side to disable clicks and show
            % glass pane effect
            obj.MessageHandler.publish('makeDisabled');
        end

        function enableDeviceList(obj)
            % Send command to JS side to enable clicks and remove
            % glass pane effect
            obj.MessageHandler.publish('makeEnabled');
        end

        function refreshView(obj)
            obj.refreshDeviceListView();
        end

        function refreshDeviceListView(obj)
            % Prepare and publish a message to send to
            % the device list web application containing all of the current
            % devices

            % Send the empty device list to the front end so the no devices
            % message is shown in the device list
            messageElementCount = numel(obj.DevicesToShow);
            listToSend = cell(1, messageElementCount);

            for i = 1: messageElementCount
                listToSend{i} = obj.DevicesToShow(i).toDeviceCardStruct();
            end

            obj.MessageHandler.publish("refreshDevices", listToSend);      

            % Reset the IsAllowMultipleInstancesMenuApplied flag
            obj.IsAllowMultipleInstancesMenuApplied = false;

        end

        function showDevicesInDevList(obj)
            obj.refreshView();
        end

        function askAndRemoveDevice(obj, deviceIndex)
            % First determine whether the device being removed is the one
            % that is currently selected as well
            
            obj.logAndSet("RequestSelectedDeviceIndex", true);

            obj.logAndSet("RequestSelectedDevice", true);

            deviceRemovedWasSelected = isequal(deviceIndex, obj.SelectedDeviceIndex);

            % Set the default value of the client app can close response
            % and the default value of the can remove hardware response
            obj.ShowWindowConfirmationResponse = string(message('hwmanagerapp:devicelist:Cancel').getString());
            
            % Default response (applicable for Hardware Manager app)
            obj.CanCloseResponse = true;

            if deviceRemovedWasSelected
                % If the device being removed is selected confirm via the
                % any running app whether can close.

                obj.CanCloseResponse = false;

                obj.logAndSet("CanRemoveDeviceRequest", obj.SelectedDevice);
            else
                % Device being removed isn't selected. Show alternative
                % confirmation dialog.

                deviceName = obj.SelectedDevice.FriendlyName;

                appName  = feval(obj.Context.AppletClass).DisplayName;
                dialogData = struct;
                dialogData.DlgTitle = string(message('hwmanagerapp:devicelist:RemoveHardware').getString());
                dialogData.DlgMessage = string(message('hwmanagerapp:devicelist:RemoveHardwareMessage', deviceName, appName).getString());
                dialogData.DlgOptions = [string(message('hwmanagerapp:devicelist:Remove').getString), string(message('hwmanagerapp:devicelist:Cancel').getString())];
                dialogData.DlgDefaultOption = string(message('hwmanagerapp:devicelist:Cancel').getString());
                
                obj.logAndSet("ShowWindowConfirmationDlg", dialogData);

                if obj.ShowWindowConfirmationResponse ==  string(message('hwmanagerapp:devicelist:Cancel').getString())
                    obj.MessageHandler.publish('removeDeviceBeingDeletedHighlight', deviceIndex-1);
                    return;
                end
            end

            % If device removal was rejected by the user then remove the
            % highlight on the device card's close [x] icon.
            if ~obj.CanCloseResponse
                obj.MessageHandler.publish('removeDeviceBeingDeletedHighlight', deviceIndex-1);
                return
            end

            % Request device removal from the device list
            obj.logAndSet("RemoveDeviceByIndex", deviceIndex);

            if deviceRemovedWasSelected && ~isempty(obj.DevicesToShow)
                % If the removed device was selected, select the first
                % device in the list (hwmgr currently does not maintain
                % history of device selection)
                obj.logAndSet("SelectDeviceByIndex", 1);
                obj.selectDeviceInView(1);
            else
                % Otherwise, just maintain the currently selected device in
                % the device list view. This is okay to call if the device
                % list is empty.

                % Request the selected device index again since the list
                % has changed
                obj.logAndSet("RequestSelectedDeviceIndex", true);
                obj.selectDeviceInView(obj.SelectedDeviceIndex);
            end
        end

        function selectDeviceInView(obj, selectedDeviceIndex)
            % Sends a message via the connector to highlight a device node
            % for selection

            if isempty(selectedDeviceIndex)
                return;
            end

            obj.MessageHandler.publish('selectDevice', selectedDeviceIndex-1);
        end

        function setLaunchInNewWindowMenu(obj, flag)
            obj.MessageHandler.publish('setLaunchInNewWindow', flag);
        end

        

    end
end
