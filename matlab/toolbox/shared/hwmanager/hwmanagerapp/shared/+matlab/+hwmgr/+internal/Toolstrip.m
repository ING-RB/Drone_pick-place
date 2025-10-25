classdef Toolstrip < matlabshared.mediator.internal.Publisher &...
        matlabshared.mediator.internal.Subscriber & ...
        matlab.hwmgr.internal.MessageLogger
    % TOOLSTRIP - Module class for maintaining all the hardware
    % manager toolstrip tabs - the main tab, the device tab, the applet tab
    % and the non-enumerable device configuration modal tab.

    % Copyright 2016-2024 The MathWorks, Inc.

    properties (Access = {?matlab.hwmgr.internal.Toolstrip})
        % APPCONTAINER - Handle to the AppContainer used as the Hardware
        % Manager Window. This object provides APIs to control the
        % Toolstrip
        AppContainer
        % APPLETTAB - Handle to the applet tab
        AppletTab
        % MAINTAB - The main hardware manager tab
        MainTab
        % MAINTABGROUP - The main tab group containing the hardware manager
        % tab
        MainTabGroup
        % APPLETSAVAILABLE - a cell array of applet classes for the
        % currently selected device
        AppletsAvailable
        % DEVICEPARAMDESCRIPTORS - array of non enumerable device parameter
        % descriptors
        DevParamDescriptors
        % CONFIGPARAMDESCRIPTORS - array of enumerable device parameter
        % descriptors
        ConfigParamDescriptors
        % MODALTABHANDLER - A handle to the ParamTabHandler object that
        % manages the modal tab
        ModalTabHandler
        % DEVICETABHANDLER - Class that manages the device tab
        DeviceTabHandler
        % DEVICE - A handle to the selected device object
        Device
        % RUNNINGAPPLETSTRUCT - The applet struct of the running applet
        RunningAppletStruct
        % APPLETPROVIDERS - An array of hardware manager applet providers.
        % The applet providers are client APIs used to tell hardware
        % manager about available client apps/applets
        AppletProviders
        % LAUNCHAPPLETONDEVICECHANGE - A boolean flag used to indicate
        % whether an applet should be launched on device selection. Can be
        % used to switch between "Applet mode" and "Standalone HWMGR mode".
        LaunchAppletOnDeviceChange
        % CANCLOSERESPONSE - A boolean flag that is used to capture the
        % Applet Runner's response to asking whether the running applet can
        % close to the user clicking on the close session button
        CanCloseResponse
    end

    properties (SetObservable)
        % Run the following command to see listeners for these properties:
        % matlab.hwmgr.internal.util.displayPropListeners('matlab.hwmgr.internal.Toolstrip');
        AddDeviceButtonEnabled
        NewAppletTsTab
        UserAddingDevice
        CanConfigDeviceRequest
        CanCloseSessionRequest
        DeviceAdded
        UserDoneAddingDevice
        ShowNoDevicesMsgByTag
        MainTsTabRequest
        AppletsForDeviceResponse
        SetCollapseToolstrip
        DialogParentRequest
        UserClosingSession
        ContextTabControlReturnVal
        DeviceUpdated
        UserDoneConfiguringDevice
        ShowSingleDocumentLayout
        RemoveAllPanels
        RequestDeviceByIndex
    end

    properties (Constant)
        ContextTabTag = "ContextTabTag";
    end

    methods (Static)
        function out = getPropsAndCallbacks()
            out =  ... % Property to listen to         % Callback function
                ["FoundDeviceDescriptors"           "setDeviceParamDescriptors"; ...
                "FoundAppletProviders"              "setAppletProviders"; ...
                "SelectedDeviceUpdate"              "setSelectedDevice"
                "CreateAppletTsTab"                 "createAppletTsTab"; ...
                "ReplaceAppletTsTab"                "replaceAppletTsTab"; ...
                "CanCloseResponse"                  "handleCanCloseResponse";...
                "MainTsTabResponse"                 "handleMainTsTabResponse";...
                "AppletsForDeviceRequest"           "handleAppletsForDeviceRequest"; ...
                "UserAddNonEnumDeviceStartPage"   	"handleUserAddNonEnumDeviceStartPage"; ...
                "UserAddNonEnumDeviceInDeviceList"  "handleUserAddNonEnumDeviceInDeviceList"; ...
                "DialogParentResponse"              "handleDialogParentResponse"; ...
                "AddContextTab"                     "addContextTab"; ...
                "ShowContextTab"                    "showContextTab"; ...
                "RemoveContextTab"                  "removeContextTab"; ...
                "UserConfigureDeviceStartPage"      "handleUserConfigureDeviceStartPage"; ...
                "UserConfigureDeviceInRunningApp"   "handleUserConfigureDeviceInRunningApp"; ...
                "DeviceByIndexResponse"             "setSelectedDevice"; ...
                "FoundDeviceConfigDescriptors"      "setDeviceConfigDescriptors";...
                ];
        end

        function out = getPropsAndCallbacksNoArgs()
            out =  ... % Property to listen to         % Callback function
                ["RefreshNonEnumDeviceGallery"      "refreshNonEnumDeviceGallery";...
                "RemoveDeviceTsTab"                 "removeDeviceTsTab"; ...
                "ShowNoDevicesMsgInDoc"             "showNoDevicesMsgInDoc";...
                "RemoveAllContextTabs"              "removeAllContextTabs";...
                ];

        end
    end

    % Module-specific API methods
    methods (Access = public)

        function obj = Toolstrip(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
        end

        function subscribeToMediatorProperties(obj, src, evt)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);

            eventsAndCallbacksNoArgs = obj.getPropsAndCallbacksNoArgs();
            obj.subscribeWithGatewaysNoArgs(eventsAndCallbacksNoArgs, @obj.subscribe);
        end

        % %%%%%%%%%% CALLBACKS %%%%%%%%%%% %
        
        function handleUserAddNonEnumDeviceStartPage(obj, descriptor)
            obj.startNonEnumDeviceConfig(descriptor, "StartPage");
        end

        function handleUserAddNonEnumDeviceInDeviceList(obj, descriptor)
            obj.startNonEnumDeviceConfig(descriptor, "DeviceList");
        end

        function handleUserConfigureDeviceStartPage(obj, msg)
            obj.UserConfigureDevice(msg, "StartPage");
        end

        function handleUserConfigureDeviceInRunningApp(obj, msg)        
            obj.UserConfigureDevice(msg, "RunningApp");
        end

        function refreshNonEnumDeviceGallery(obj)
            % Clear the existing non enum device gallery
            obj.clearNonEnumDeviceGallery();

            % Populate the non-enum device gallery with the new descriptors
            obj.populateNonEnumDeviceGallery(obj.DevParamDescriptors, @obj.startNonEnumDeviceConfig);

            % The Add Device button will be enabled/disabled by the
            % HwmgrWindow
            isNonEnumDeviceGalleryEnabled = ~isempty(obj.DevParamDescriptors);
            obj.logAndSet("AddDeviceButtonEnabled", isNonEnumDeviceGalleryEnabled);
        end

        function setDeviceParamDescriptors(obj, descriptors)
            obj.DevParamDescriptors = descriptors;
        end

        function setDeviceConfigDescriptors(obj, descriptors)
            obj.ConfigParamDescriptors = descriptors;
        end

        function setAppletProviders(obj, providers)
            % Set the available applet providers
            obj.AppletProviders = providers;
        end

        function removeDeviceTsTab(obj)
            if ~isempty(obj.DeviceTabHandler)
                obj.DeviceTabHandler.removeTabFromGroup();
                delete(obj.DeviceTabHandler);
                obj.DeviceTabHandler = [];
            end
        end

        function setSelectedDevice(obj, device)
            obj.Device = device;
            if isempty(device)
                return
            end
            appletsForDevice = obj.getAppletsForDeviceFromProviders(obj.Device);
            obj.setAppletsAvailable(appletsForDevice);

            if matlab.hwmgr.internal.isHardwareManagerFeatureOn
                % Replace the existing device tab with a new device tab
                obj.removeDeviceTsTab();

                obj.showNewDeviceTab(@obj.launchApplet, @obj.editButtonCallback);
            end
        end

        function newAppletTab = createAppletTsTab(obj, appletStruct)
            % Method to respond to an applet launch request

            % Create new applet tab
            newAppletTab = obj.constructAppletTsTab(appletStruct);
            obj.logAndSet("NewAppletTsTab", newAppletTab);
        end

        function closeSession(obj)
            % Callback for the close device session button

            obj.logAndSet("CanCloseSessionRequest", []);

            % If vetoed, do nothing
            if ~obj.CanCloseResponse
                return;
            end

            % Indicate to the Controller the user is now closing and going
            % back to the Start Page.
            obj.logAndSet("UserClosingSession", []);
        end

        function replaceAppletTsTab(obj, args)
            % This method will remove any existing applet tooltstrip tab.
            % Then it will optionally add another applet tooltstrip tab if
            % one is provided. If no applet toolstrip tab is provided, the
            % existing applet tooltstrip tab (if any) is removed.
            isUsingTab = args.IsUsingAppletTsTab;
            appletTsTab = args.AppletTsTab;

            if isempty(obj.MainTabGroup)
                obj.logAndSet("MainTsTabRequest", true);
            end

            % Remove any existing applet tab
            if ~isempty(obj.AppletTab)
                obj.removeAppletTab(obj.AppletTab);

                % Remove contextual tabs as well
                obj.removeAllContextTabs();
            end

            if isUsingTab
                % Applet has indicated it intends to use the tab - add
                % it to the Tab Group and bring it to focus

                % Decorate the client app's toolstrip tab with the close device
                % session button before adding it to the tabgroup
                obj.addCloseSessionButton(appletTsTab);

                obj.addAndSelectTab(appletTsTab);
            else
                % If the applet indicated that it does not intend to
                % use the toolstrip tab, then don't make it visible and
                % remove it.
                obj.destroyAppletTab(appletTsTab);
            end

        end


        function showNoDevicesMsgInDoc(obj)

            if isempty(obj.DevParamDescriptors)
                msgTag = "DAQ";
            elseif isa(obj.DevParamDescriptors, 'raspi.resourcemonitor.RaspiTCPIPDescriptor')
                msgTag = "RASPI";
            elseif isa(obj.DevParamDescriptors, 'arduinoioapplet.descriptors.USBDeviceDescriptor')
                msgTag = "ARDUINO";
            elseif isa(obj.DevParamDescriptors, "transportapp.tcpclient.internal.TcpclientDescriptor")
                msgTag = "TCPCLIENT_APP";
            else
                msgTag = "MODBUS";
            end

            obj.logAndSet("ShowNoDevicesMsgByTag", msgTag);

        end

        function handleCanCloseResponse(obj, response)
            obj.CanCloseResponse = response;
        end

        function handleMainTsTabResponse(obj, args)
            obj.MainTabGroup = args.MainTabGroup;
        end

        function handleAppletsForDeviceRequest(obj, device)
            applets = obj.getAppletsForDeviceFromProviders(device);
            obj.logAndSet("AppletsForDeviceResponse", applets);
        end

        function handleDialogParentResponse(obj, parent)
            obj.AppContainer = parent;
        end

        %{ Contextual toolstrip tab control methods. %}

        function addContextTab(obj, args)
            % Add tab to the MainTabGroup to show it. Requires that tab be a
            % valid MATLAB tab object.

            % Extract arguments
            newTab = args.Tab;
            index = args.Index;
            result = false;

            % Skip if tab is already present
            if (ismember(newTab, obj.MainTabGroup.findAll(obj.ContextTabTag)))
                return;
            end

            if isempty(index)
                % If no index is provided, just call TabGroup.add to append
                % tab.
                obj.MainTabGroup.add(newTab);
                result = true;
                drawnow;

            else
                % If index is provided, check that index is valid before
                % adding. Invalid index will be ignored by TabGroup.add,
                % but we need to know to return false.
                if index <= length(obj.MainTabGroup) + 1
                    obj.MainTabGroup.add(newTab, index);
                    result = true;
                    drawnow;
                end
            end

            % Return result
            obj.logAndSet("ContextTabControlReturnVal", result);
        end

        function showContextTab(obj, tab)
            % Change SelectedTab to the given tab. Returns true if tab was
            % focused, false if tab was not focused.
            % Required that tab be a valid MATLAB tab object.

            % Ensures tab that we're about to change to is currently being
            % shown, or it's the main tab.
            if ( isequal(tab, obj.MainTab) || ismember(tab, obj.MainTabGroup.findAll(obj.ContextTabTag)))
                obj.MainTabGroup.SelectedTab = tab;
                obj.logAndSet("ContextTabControlReturnVal", true);
            else
                obj.logAndSet("ContextTabControlReturnVal", false);
            end 
        end

        function removeContextTab(obj, tab)
            % Remove tab from the MainTabGroup to hide it. Return true if we
            % indeed hide a tab, false if tab was not shown or if tab was the main 
            % toolstrip tab. Requires that tab be a valid MATLAB tab object.

            % Ensure we're hiding a shown context tab and not hiding the main tab.
            if (~ismember(tab, obj.MainTabGroup.findAll(obj.ContextTabTag)))
                obj.logAndSet("ContextTabControlReturnVal", false);
                return;
            end

            % If selecting a tab that's about to be hidden, change focus to
            % main tab.
            if (obj.MainTabGroup.SelectedTab == tab)
                obj.MainTabGroup.SelectedTab = obj.MainTab;
            end

            obj.MainTabGroup.remove(tab);
            obj.logAndSet("ContextTabControlReturnVal", true);
        end

        function removeAllContextTabs(obj)
            % Remove all currently shown context tabs from the toolstrip.
            obj.MainTabGroup.SelectedTab = obj.MainTab;
            for tab = obj.MainTabGroup.findAll(obj.ContextTabTag)'
                obj.MainTabGroup.remove(tab);
            end
        end

        % %%%%%%%%%% END CALLBACKS %%%%%%% %
    end

    methods (Access = {?hwmgr.DeviceListTester, ?matlab.unittest.TestCase, ?matlab.hwmgr.internal.Toolstrip})
        function addCloseSessionButton(obj, appletTsTab)
            % This method will take an applet toolstrip tab and add a close
            % session button to it. The callback of the button is a
            % method in this module that will initiate a canClose sequence
            % of mediator messages with the Applet Runner. If approved,
            % then the Controller will be notified that the user intends to
            % close the running app session for the selected device, and go
            % back to the Client App Start Page. All devices will also be
            % deselected.


            % If this tab already has a "Close" section then skip adding
            % the button again. This can happen if the same tab is simply
            % removed and added back.
            
            sections = appletTsTab.getChildByIndex();
            
            % In the possibility of a toolstrip tab that does not have any
            % sections or anything added to it
            if numel(sections)> 0
                allTitles = string({sections.Title});
                if any(allTitles.contains(message("hwmanagerapp:framework:ToolstripCloseSessionButtonSectionTitle").getString()))
                    return;
                end
            end

            % Assume that the client app has already added their sections.
            % We now add the "close" section
            closeSection = appletTsTab.addSection(message("hwmanagerapp:framework:ToolstripCloseSessionButtonSectionTitle").getString());
            closeButtonColumn = closeSection.addColumn();

            closeButton = matlab.ui.internal.toolstrip.Button(sprintf(message("hwmanagerapp:framework:ToolstripCloseSessionButtonTitle").getString()), "close");
            closeButton.ButtonPushedFcn = @(~,~)obj.closeSession();
            closeButton.Description = message("hwmanagerapp:framework:ToolstripCloseSessionButtonDescription").getString();

            closeButtonColumn.add(closeButton);
        end

        function appletStructArray = getAppletsForDeviceFromProviders(obj, device)
            % This method will return the applet structs that are applicable for
            % the current device by running through all applet providers
            % and asking for applets that support the current device
            % Returned appNameConstructorPairs is a struct array with fields AppletName
            % and Constructor

            appletNames = {};
            % first get all the applet names from all providers
            for i = 1:numel(obj.AppletProviders)
                try
                    tempApplets = obj.AppletProviders(i).getAppletsByDevice(device);
                catch ex
                    msgID = 'hwmanagerapp:devicelist:BrokenAppletProvider';
                    warning(message(msgID, class(obj.AppletProviders(i)), ex.message));
                    continue;
                end
                appletNames =  [appletNames tempApplets]; %#ok<AGROW>
            end

            % We only try to list the  Hardware Setup Applet with the
            % device if the Hardware Setup Applet was NOT already specified
            % by the applet providers getAppletDevice methods
            if ~obj.containsHardwareSetupApplet(appletNames)
                % Get the default hardware setup applet if the device has
                % hardware setup
                hwSetupApp = matlab.hwmgr.internal.AppletProviderBase.getHardwareSetupAppletByDevice(device);
                appletNames = [appletNames, hwSetupApp];
            end

            % for each applet name, get all available constructor options
            appletStructArray = struct('AppletName', {}, 'Constructor', {});
            for i = 1:numel(appletNames)
                appletStruct = matlab.hwmgr.internal.util.convertToAppletStruct(appletNames{i}, device);
                appletStructArray = [appletStructArray, appletStruct]; %#ok<AGROW>
            end
        end

        function descriptorMakeWindowBusyHook(obj, isBusy)
            obj.AppContainer.Busy = isBusy;
        end

    end

    methods (Access = {?matlab.hwmgr.internal.Toolstrip})


        function showNonEnumDeviceConfigTab(obj, descriptor, cancelDestination)

            % DESCRIPTOR - the client device params descriptor object to
            % use to show the device configuration tooltstrip tab for.

            % CANCELDESTINATION - The page that the user is taken to upon
            % cancelling the device configuration.

            % Create the modal tab for getting device parameters
            obj.showModalTsTab(descriptor, @obj.confirmAddDevice, @()obj.cancelConfiguringDevice(cancelDestination), false);

            % Remove the all other tabs (i.e. any device tab and the
            % main tab).
            obj.removeDeviceTsTab();
        end

        function showDeviceConfigTab(obj, descriptor, cancelDestination)

            % DESCRIPTOR - the client device params descriptor object to
            % use to show the device configuration tooltstrip tab for.

            % CANCELDESTINATION - The page that the user is taken to upon
            % cancelling the device configuration.

            % Create the modal tab for getting device parameters
            obj.showModalTsTab(descriptor, @obj.confirmConfigDevice, @()obj.cancelConfiguringDetectedDevice(cancelDestination), true);

            % Remove the all other tabs (i.e. any device tab and the
            % main tab).
            obj.removeDeviceTsTab();
        end
        function startNonEnumDeviceConfig(obj, descriptor, cancelDestination)
            % Callback function for non enumerable device gallery
            % item/button push
            obj.logAndSet("CanConfigDeviceRequest", []);

            if obj.CanCloseResponse
                
                if isempty(obj.AppContainer)
                     obj.logAndSet("DialogParentRequest", true);
                end

                % Setting the dialog parent here is a temporary solution to
                % allow teams to create ui* dialogs from the descriptor,
                % until a more robust solution is provided
                descriptor.setDialogParent(obj.AppContainer);

                % Initialize the make window busy hook so descriptor
                % clients can make the window busy during long standing
                % operations if required.
                descriptor.setMakeWindowBusyFcn(@(isBusy)obj.descriptorMakeWindowBusyHook(isBusy));
                
                msgData = struct('Descriptor', descriptor, ...
                    'HasHelpPage', descriptor.hasHelpPage());
                obj.logAndSet("UserAddingDevice", msgData);
                obj.showNonEnumDeviceConfigTab(descriptor, cancelDestination);
                obj.logAndSet("SetCollapseToolstrip", false);
            end

        end

        function UserConfigureDevice(obj, msg, cancelDestination)
            
            deviceIndex = msg{1};
            appletClass = msg{2};
            % Select the device and response sets it to obj.Device
            obj.logAndSet("RequestDeviceByIndex", deviceIndex);
            
            % get the descriptorString that is applicable to this device
            descriptorString = "";
            for i = 1:length(obj.Device.DeviceEnumerableConfigData)
                if(obj.Device.DeviceEnumerableConfigData.AppletClass == appletClass)
                    descriptorString = obj.Device.DeviceEnumerableConfigData.EnumerableDeviceDescriptor;
                end
            end

            % get the descriptor object equal to the descriptorString
            descriptorClass = [];
            for a = 1: length(obj.ConfigParamDescriptors)
                if (strcmp(class(obj.ConfigParamDescriptors(a)),descriptorString))
                    descriptorClass = obj.ConfigParamDescriptors(a);
                    break
                end
            end
            
            obj.startDeviceConfig(descriptorClass, cancelDestination);
        end

        function startDeviceConfig(obj, descriptor, cancelDestination)
            % Remove devicelist panel in case the config is called from
            % running app
            obj.logAndSet("RemoveAllPanels", true);

            if isempty(obj.AppContainer)
                 obj.logAndSet("DialogParentRequest", true);
            end

            % Setting the dialog parent here is a temporary solution to
            % allow teams to create ui* dialogs from the descriptor,
            % until a more robust solution is provided
            descriptor.setDialogParent(obj.AppContainer);

            % Initialize the make window busy hook so descriptor
            % clients can make the window busy during long standing
            % operations if required.
            descriptor.setMakeWindowBusyFcn(@(isBusy)obj.descriptorMakeWindowBusyHook(isBusy));
            
            msgData = struct('Descriptor', descriptor, ...
                'HasHelpPage', descriptor.hasHelpPage());
            % closes all applets/documents, and load help page
            obj.logAndSet("UserAddingDevice", msgData);
            obj.showDeviceConfigTab(descriptor, cancelDestination);
            obj.logAndSet("SetCollapseToolstrip", false);

        end

        function confirmAddDevice(obj, device)
            % Callback method for the "Confirm" button in the non enum
            % device configuration tab

            % Close the configuration tab
            obj.closeModalTsTab();

            % Send the new device to the device list
            obj.logAndSet("DeviceAdded",device);

            % Send a message to the main controller to exit the config mode
            % and to select the first device (newly added device)
            obj.logAndSet("UserDoneAddingDevice", 1);
        end

        function confirmConfigDevice(obj, device)
            % Callback method for the "Confirm" button in the
            % device configuration tab

            % Close the configuration tab
            obj.closeModalTsTab();

            obj.logAndSet("DeviceUpdated",device);
            % Send a message to the main controller to exit the config mode
            % and to select the device (configured device)
            obj.logAndSet("UserDoneConfiguringDevice", device);
        end

        function cancelConfiguringDetectedDevice(obj, cancelDestination)
            % Callback method for the "Confirm" button in the
            % device configuration tab for a detected device configuration

            % Close the configuration tab
            obj.closeModalTsTab();

            % Send a message to the main controller to exit the config mode
            % and to select the last device if cancelDestination is Running
            % App and to go back to start page if cancelDestination is
            % StartPage
            obj.logAndSet("UserDoneConfiguringDevice", cancelDestination);
        end

        function cancelConfiguringDevice(obj, cancelDestination)
            % This method is provided to the param tab handler to invoke on
            % "Cancel" button click

            % Close the configuration tab
            obj.closeModalTsTab();

            % Send a message to the main controller to exit the config mode
            % and to select the previously selected device
            if cancelDestination == "DeviceList"
                obj.logAndSet("UserDoneAddingDevice", 0);
            else
                obj.logAndSet("UserDoneAddingDevice", cancelDestination);
            end
        end

        function setAppletsAvailable(obj, applets)
            obj.AppletsAvailable = applets;
        end

        function showNewDeviceTab(obj, launchAppletBtnFcn, editDeviceBtnFcn)
            obj.DeviceTabHandler = matlab.hwmgr.internal.toolstrip.DeviceTabHandler(...
                obj.MainTabGroup, ...
                obj.AppletsAvailable, ...
                obj.Device, ...
                launchAppletBtnFcn, ...
                editDeviceBtnFcn);

            % Set the device tab as the selected tab
            obj.DeviceTabHandler.setAsSelectedTab();
        end

        function addAndSelectTab(obj, appletTab)
            if ~isempty(appletTab) && isvalid(appletTab)
                tabGroup = obj.MainTabGroup;
                tabGroup.add(appletTab);
                obj.setCurrentAppletTab(appletTab);
                obj.setSelectedTab(appletTab);
                drawnow;
            end
        end

        function setCurrentAppletTab(obj, tab)
            obj.AppletTab = tab;
            obj.MainTab = tab;
        end


        function setSelectedTab(obj, tab)
            tabGroup = obj.MainTabGroup;
            tabGroup.SelectedTab = tab;
        end


        function disableMainTab(obj)
            obj.MainTab.disableAll();
            % We need the drawnow to force the JS callbacks to execute,
            % otherwise there is a lag
            drawnow;
        end

        function enableMainTab(obj)
            obj.MainTab.enableAll();
            % We need the drawnow to force the JS callbacks to execute,
            % otherwise there is a lag
            drawnow;
        end

        function removeMainTsTab(obj)
            % Remove the main tab
            tabGroup = obj.MainTabGroup;
            tabGroup.remove(obj.MainTab);
        end

        function restoreMainTsTab(obj)
            % Restore the main tab
            obj.enableMainTab();
            tabGroup = obj.MainTabGroup;
            tabGroup.add(obj.MainTab);
        end


        function descriptor = getDescriptorByName(obj, name)
            % This method will find the param descriptor with the given name
            % in the list of param descriptors and return it
            descriptor = [];
            for i = 1:numel(obj.DevParamDescriptors)
                currDescriptor = obj.DevParamDescriptors(i);
                if strcmp(currDescriptor.getName(), name)
                    descriptor = currDescriptor;
                    break;
                end
            end
        end


        function showModalTsTab(obj, descriptor, confirmBtnFcn, cancelBtnFcn, sendDevice)
            % This method will create the modal tab and send requests to
            % make the device list and  root pane busy until the modal
            % operation is complete

            % Create the param tab handler. The param tab handler manages
            % the operation of the modal tab
            tabGroup = obj.MainTabGroup;
            % sends Device info if configuring a detected device
            if sendDevice
                obj.ModalTabHandler = matlab.hwmgr.internal.toolstrip.ParamTabHandler(...
                    tabGroup, ...
                    descriptor, ...
                    confirmBtnFcn, ...
                    cancelBtnFcn, ...
                    obj.AppContainer, ...
                    obj.Device);
            else
                    obj.ModalTabHandler = matlab.hwmgr.internal.toolstrip.ParamTabHandler(...
                    tabGroup, ...
                    descriptor, ...
                    confirmBtnFcn, ...
                    cancelBtnFcn, ...
                    obj.AppContainer);
            end
        end

        function closeModalTsTab(obj)
            % Remove the modal tab
            delete(obj.ModalTabHandler);
            drawnow;
        end

        function newAppletTab = constructAppletTsTab(obj, appletStruct)
            newAppletTab = matlab.ui.internal.toolstrip.Tab(appletStruct.AppletName);
            % Use group tag to uniquely identify the toolstrip tab
            newAppletTab.Tag = appletStruct.GroupTag;
        end

        function removeAppletTab(obj, appletTab)
            % Remove any currently running applet tab
            if ~isempty(appletTab) && isvalid(appletTab)
                tabGroup = obj.MainTabGroup;
                % Only remove when the applet tab is a child of the
                % tabgroup
                allTabs = tabGroup.getChildByIndex();
                if ismember(appletTab, allTabs)
                    tabGroup.remove(appletTab);
                end
                obj.setCurrentAppletTab([]);
            end
        end

        function button = getNonEnumDeviceGalleryButton(obj)
            % Method to find the NonEnumDeviceGallery from child widgets of
            % the main tab
            obj.logAndSet("MainTsTabRequest", true);
            button = obj.MainTab.getChildByTag('hwmgr_main_tab_devsection').getChildByTag('hwmgr_nonenumdev_column').getChildByTag('hwmgr_nonenumdev_gallery_button');
        end

        function destroyAppletTab(obj, appletTab)
            delete(appletTab);
            obj.AppletTab = [];
            obj.MainTab = [];
        end

        function galleryCategory = getNonEnumDeviceGalleryCategory(obj)
            % Method to find the non emum device gallery category from the
            % DropDownGalleryButton Popup menu object.

            % A DropDownGalleryButton is made up of popups, which contain categories.
            % Each category contains one or more gallery items
            pButton = obj.getNonEnumDeviceGalleryButton();
            galleryPopup = pButton.Popup;
            galleryCategory = galleryPopup.getChildByIndex(1);
        end

        function clearNonEnumDeviceGallery(obj)
            % Method to clear all items in the non enumerable device
            % gallery category

            % A Gallery is made up of popups, which contain categories.
            % Each category contains one or more gallery items

            galleryCategory = obj.getNonEnumDeviceGalleryCategory();
            % This returns all the items
            galleryItems = galleryCategory.getChildByIndex();
            for i = 1:numel(galleryItems)
                galleryCategory.remove(galleryItems(i));
            end
        end

        function populateNonEnumDeviceGallery(obj, descriptors, buttonPressFcn)
            % This method will add gallery items into the gallery category.
            % The gallery items are based on non enumerable device param
            % descriptors
            galleryCategory = obj.getNonEnumDeviceGalleryCategory();
            for i = 1:numel(descriptors)
                % Get the current descriptor
                currDescriptor = descriptors(i);
                % Create the NonEnumDevice item
                item = matlab.ui.internal.toolstrip.GalleryItem(currDescriptor.getName(), currDescriptor.getIcon());
                % Set the callback on the item
                item.ItemPushedFcn = buttonPressFcn;
                % Set the tag for automation
                item.Tag = ['NEDGALLERY_ITEM_' char(upper(currDescriptor.getGalleryButtonTag()))];
                % Enable or disable the button
                item.Enabled = currDescriptor.ButtonEnable;
                % Set the tooltip text
                item.Description = currDescriptor.ButtonTooltipText;
                % Add it to the gallery
                galleryCategory.add(item);
            end
        end
    end

    methods (Static, Access = {?matlab.hwmgr.internal.Toolstrip})
        function result = containsHardwareSetupApplet(appletNames)
            result = false;
            for i = 1:numel(appletNames)
                if isHardwareSetupApplet(appletNames{i})
                    result = true;
                    return;
                end
            end

            % Nested utility function
            function result = isHardwareSetupApplet(appletClass)
                result = false;
                info = meta.class.fromName(appletClass);
                superClassList = info.SuperclassList;

                for k=1:numel(superClassList)
                    className =  superClassList(k).Name;
                    if strcmp(className, 'matlab.hwmgr.applets.internal.HardwareSetupApplet')
                        result = true;
                        return;
                    end
                end
            end

        end

    end

end
