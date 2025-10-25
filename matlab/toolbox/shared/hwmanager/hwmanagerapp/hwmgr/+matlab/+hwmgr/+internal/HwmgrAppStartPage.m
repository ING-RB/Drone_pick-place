classdef HwmgrAppStartPage < matlabshared.mediator.internal.Publisher &...
        matlabshared.mediator.internal.Subscriber &...
        matlab.hwmgr.internal.MessageLogger
    %STARTPAGE Start page back-end of Hardware Manager app

    %   Copyright 2021-2024 The MathWorks, Inc.

    properties(Constant)
        % WebAppPath - path from the MATLABROOT to the Web
        % application main HTML page
        WebAppPath = 'toolbox/shared/hwmanager/hwmanagerapp/web/hwmgr/hwmgr-startpage-ui/index.html';
    end

     properties (Access = {?matlab.unittest.TestCase})
        % StaticChannel - the name of the static channel being used in the
        % connector message service
        StaticChannel = '/HWF/hwmgrstartpage'

        % MessageHandler - Handler of connector communication with client (JS)
        MessageHandler

        % Url - URL of the start page
        Url
    end

    properties
        %AllDevices - All device objects from device list
        AllDevices

        % Service Launcher
        ServiceLauncher

        % SelectedDeviceIndex - index of the selected device on the device
        % list side
        SelectedDeviceIndex
    end

    properties(SetObservable)
        HwmgrWindowUrl
        RefreshRequired
        DeviceRemovedFromHwmgrApp
        SetSuspendClose
        DeviceSelectedOnStartPage
        SelectLastUsedDevice
    end

    methods (Static)
        function out = getPropsAndCallbacks()
            out =  ... % Property to listen to         % Callback function
                [
                "MakeHwmgrWindowBusy"                   "showLoadingDevicesBusyIndicator"; ...
                "DevicesAvailableToShow"                "handleDevicesAvailableToShow";...
                "SelectDeviceInView"                    "handleSelectDeviceInView"; ...
                "LaunchErrorDialog"                     "handleLaunchErrorDialog"; ...
                ];
        end

        function out = getPropsAndCallbacksNoArgs()
            out =  ... % Property to listen to         % Callback function
                [
                "HwmgrWindowUrlRequest"                  "handleHwmgrWindowUrlRequest"
                ];
        end
    end

    methods
        function obj = HwmgrAppStartPage(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);

            obj.ServiceLauncher = matlab.hwmgr.internal.ServiceLauncher();
            obj.MessageHandler = matlab.hwmgr.internal.MessageHandler(obj.StaticChannel);
            obj.MessageHandler.setSubject(obj);
            obj.subscribeToClientActions();
        end

        function subscribeToMediatorProperties(obj, ~, ~)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);

            eventsAndCallbacksNoArgs = obj.getPropsAndCallbacksNoArgs();
            obj.subscribeWithGatewaysNoArgs(eventsAndCallbacksNoArgs, @obj.subscribe);
        end


        function subscribeToClientActions(obj)
            obj.MessageHandler.subscribe("clientOpenLink");
            obj.MessageHandler.subscribe("clientRequestRefresh");
            obj.MessageHandler.subscribe("clientRequestRemoveDevice");
            obj.MessageHandler.subscribe("clientInstallAddOn");
            obj.MessageHandler.subscribe("clientOpenAddOn");
            obj.MessageHandler.subscribe("clientRegFwkAddonInstalled");
            obj.MessageHandler.subscribe("clientRegFwkAddonUninstalled");  
            obj.MessageHandler.subscribe("clientDduxSearchUnsupportedHardware");
            obj.MessageHandler.subscribe("clientDduxInstallAddOn");
            obj.MessageHandler.subscribe("clientDduxAddOnInstallationComplete");
            obj.MessageHandler.subscribe("clientSelectDevice");
            obj.MessageHandler.subscribe("clientLaunchFeature");
        end

        function url = getUrl(obj)
            if ~isempty(obj.Url)
                url = obj.Url;
                return
            end

            url = connector.getUrl(obj.MessageHandler.appendClientIdToUrl(obj.WebAppPath));
        end

        function handleHwmgrWindowUrlRequest(obj)
            url = obj.getUrl();
            obj.logAndSet("HwmgrWindowUrl", url);
            obj.updateClientDatabase();
        end

        % ------------ Start ---- Command to client --------------------

        function updateClientDatabase(obj)
            database = obj.prepareDatabaseForClient();
            obj.MessageHandler.publish('updateDatabase', database);
        end

        function updateClientAddOnInstallationStatus(obj, baseCode, installedFlag)
            % Change AddOn installation status to true on front-end
            data = struct("baseCode", baseCode, "installedStatus", installedFlag);
            obj.MessageHandler.publish('updateAddOnInstallStatus', data);
        end

        function refreshClientDeviceList(obj, devices)
            obj.MessageHandler.publish('refreshDeviceList', devices);
        end

        function showBusyIndicator(obj, data)
            % data has two fields: flag and text
            obj.MessageHandler.publish('showBusyIndicator', data);
        end

        % ------------ End ---- Command to client --------------------

        % ------------ Start --- Respond to client requests -------------

        function clientOpenLink(obj, linkData)
            if isfield(linkData, "TopicId")
                try
                    % Try to open with helpview first
                    obj.ServiceLauncher.openWithHelpView(linkData.ShortName, linkData.TopicId);
                catch ME
                    % helpview cannot open due to AddOn not installed
                    % Open URL in browser directly
                    obj.ServiceLauncher.openUrlInBrowser(linkData.Url);
                end
            else
                obj.ServiceLauncher.openUrlInBrowser(linkData.Url);
            end
        end

        function clientRequestRefresh(obj, ~)
            obj.refreshDevices();
        end

        function clientRequestRemoveDevice(obj, deviceId)
            obj.logAndSet("DeviceRemovedFromHwmgrApp", deviceId + 1);
        end

        function clientLaunchFeature(obj, featureData)
            featureIdentifier = featureData.Identifier;
            deviceId = featureData.DeviceId;
            frontEndArgs = featureData.FrontEndArgs;

            % Retrieve the data plugin launchable data from the data store based on the feature identifier
            launchableData = matlab.hwmgr.internal.DataStoreHelper.getDataStore().getLaunchableData(featureIdentifier);

            if isempty(deviceId)
                selectedDevice = [];
            else
                selectedDevice = obj.AllDevices(deviceId + 1);
            end

            try
                launchable = matlab.hwmgr.internal.data.DataFactory.createFeatureLaunchable(launchableData, selectedDevice, frontEndArgs);
                featureLauncher =  matlab.hwmgr.internal.FeatureLauncher(launchable);
                featureLauncher.launch();
            catch ex
                % we should handle all errors in the classes involved in the launch
                backtraceState = warning("backtrace").state;
                % Don't display the stack trace. Only show the warning message.
                warning("off", "backtrace");
                warning(ex.identifier, '%s', "Failed to launch " + string(launchableData.Category) + ": " + ex.message);
                warning(backtraceState, "backtrace");
            end
        end

        function clientInstallAddOn(obj, baseCode)
            installerType = obj.ServiceLauncher.installAddOn(baseCode, @(~, ~)obj.ssiWindowClosedCallback);
            if installerType == "SSI"
                obj.showInstallingAddOnBusyIndicator(true);
            end
        end

        function clientOpenAddOn(obj, ~)
           obj.ServiceLauncher.openAddOnExplorer();
        end

        function clientRegFwkAddonInstalled(obj, baseCode)
            obj.updateClientAddOnInstallationStatus(baseCode, true);
            obj.showInstallingAddOnBusyIndicator(false);
            obj.refreshDevices();

            % Reset the selected device index since the device list was
            % just refreshed
            obj.SelectedDeviceIndex = [];

            % Request the device list to find/match the last selected
            % device prior to the refresh and select it after the refresh.
            % A specific device corresponding to a previously selected
            % generic or client enumerated device could now be available so
            % select it if available.
            obj.logAndSet("SelectLastUsedDevice", true);

            % If the SelectedDeviceIndex is not empty, this means that the
            % device list was able to successfully match and select the
            % previously selecte
            if ~isempty(obj.SelectedDeviceIndex)
                % Select the device on the front end. This will select the
                % new device card but the existing dialog will still be
                % shown with updated information
                obj.MessageHandler.publish("selectDevice", obj.SelectedDeviceIndex-1);
            end
        end

        function clientRegFwkAddonUninstalled(obj, baseCode)
            % Simply update the front-end database without doing anything
            % else because there is no UI in Hardware Manager that can
            % initiate an AddOn uninstallation.
            obj.updateClientAddOnInstallationStatus(baseCode, false);
		end
        function clientDduxSearchUnsupportedHardware(obj, searchData)
            matlab.hwmgr.internal.HwmgrAppDduxBridge.logHardwareSearchAddHardwareDlg(searchData);
        end

        function clientDduxInstallAddOn(obj, jsDduxData)                
            % Check the dialog type to call the correct ddux logging event
            if jsDduxData.DialogType == "AddDevice"
                matlab.hwmgr.internal.HwmgrAppDduxBridge.logAddonInstallAddHardwareDlg(jsDduxData);
            else
                % Device Detail Dialog
                selectedDevice = obj.AllDevices(jsDduxData.DeviceIndex + 1);
                matlab.hwmgr.internal.HwmgrAppDduxBridge.logAddonInstallDeviceDetailDlg(jsDduxData, selectedDevice);
            end
        end

        function clientDduxAddOnInstallationComplete(obj, jsDduxData)
            if jsDduxData.DialogType == "AddDevice"
                matlab.hwmgr.internal.HwmgrAppDduxBridge.logAddonInstallAddHardwareDlg(jsDduxData);
            else
                % Device Detail Dialog
                selectedDevice = obj.AllDevices(jsDduxData.DeviceIndex + 1);
                matlab.hwmgr.internal.HwmgrAppDduxBridge.logAddonInstallDeviceDetailDlg(jsDduxData, selectedDevice);
            end        
        end

        function clientSelectDevice(obj, deviceIndex)
            % Inform controller of selected device. The front-end device
            % indexing is 0 based, so add 1 to convert to MATLAB indexing
            obj.logAndSet("DeviceSelectedOnStartPage", deviceIndex + 1);
        end

        % ------------ End --- Respond to client requests -------------

        function showLoadingDevicesBusyIndicator(obj, flag)
            data = struct("flag", flag, "text", message('hwmanagerapp:hwmgrstartpage:LoadingDevices').getString);
            obj.showBusyIndicator(data);
        end

        function handleLaunchErrorDialog(obj, data)
            obj.MessageHandler.publish('launchErrorDialog', data);
        end
        
        function showInstallingAddOnBusyIndicator(obj, flag)
            data = struct("flag", flag, "text", message('hwmanagerapp:hwmgrstartpage:InstallingAddOn').getString);
            obj.showBusyIndicator(data);
        end
        
        function refreshDevices(obj)
            obj.showLoadingDevicesBusyIndicator(true);
            obj.logAndSet("SetSuspendClose", true);
            obj.logAndSet("RefreshRequired", true)
            obj.logAndSet("SetSuspendClose", false);
            obj.showLoadingDevicesBusyIndicator(false);
        end

        function setAllDevices(obj, devices)
            obj.AllDevices = devices;
        end

        function refreshDevicesView(obj)
            messageElementCount = numel(obj.AllDevices);
            listToSend = cell(1, messageElementCount);

            for i = 1: messageElementCount
                listToSend{i} = obj.AllDevices(i).toDeviceCardStruct();
            end
            % Update device cards on front-end
            obj.refreshClientDeviceList(listToSend);
        end
        
        function handleDevicesAvailableToShow(obj, devicesToShow)
            obj.setAllDevices(devicesToShow);

            obj.refreshDevicesView();
        end

        function handleSelectDeviceInView(obj, deviceIndex)
            % This callback gets invoked in response to a message from the
            % Device List model right after the model updates the selected
            % device object. Although we knew the device index already from
            % the front end, we use this message from the device list model
            % to know that the device selection on the model was
            % successful. 
            obj.SelectedDeviceIndex = deviceIndex;
        end

        function ssiWindowClosedCallback(obj)
            % The current installation process has been completed/canceled.
            obj.showInstallingAddOnBusyIndicator(false);
        end

        % -------------------- Utility functions -------------------------

        function database = prepareDatabaseForClient(obj)
            % Convert enum and map data to be compatible with front-end

            dataStore = matlab.hwmgr.internal.DataStoreHelper.getDataStore();

            % Temporarily trun off the object to struct conversion
            % warning issued by struct(Object)
            warning('off', 'MATLAB:structOnObject');

            % Add installation info in AddOn

            if isempty(dataStore.AddOnData)
                addOnData = [];
            else
                addonsInstalled = matlab.hwmgr.internal.util.getInstalled();
                for i = 1:length(dataStore.AddOnData)
                    newAddOnStruct = struct(dataStore.AddOnData(i));
                    newAddOnStruct.Installed = matlab.hwmgr.internal.util.isInstalled(newAddOnStruct.BaseCode, addonsInstalled);
                    addOnData(i) = newAddOnStruct;
                end
            end

            if isempty(dataStore.HardwareKeywordData)
                keywordData = [];
            else
                for i = 1:length(dataStore.HardwareKeywordData)
                    keywordData(i) = struct(dataStore.HardwareKeywordData(i));
                    keywordData(i).Categories = string(keywordData(i).Categories);
                    if isempty(keywordData(i).Manufacturers)
                        keywordData(i).Manufacturers = [];
                    else
                        keywordData(i).Manufacturers = struct('Name', keywordData(i).Manufacturers.keys, ...
                            'BaseCodes', keywordData(i).Manufacturers.values);
                    end
                end
            end

            % Need to wrap array of objects into cells for front-end to interpret them correctly.
            database = struct('AddOnData', {num2cell(addOnData)}, ...
                'KeywordData', {num2cell(keywordData)});

            categories = string(enumeration('matlab.hwmgr.internal.data.FeatureCategory'));
            for i = 1:length(categories)
                propertyName = categories(i) + "Data";
                launchableData = obj.translateLaunchableDataToFrontEnd(dataStore, propertyName);
                database.(propertyName) = launchableData;
            end

            warning('on', 'MATLAB:structOnObject');
        end

        function launchableData = translateLaunchableDataToFrontEnd(~, dataStore, propertyName)
            if isempty(dataStore.(propertyName))
                launchableData = {};
            else
                launchableData = num2cell(dataStore.(propertyName));
                for j = 1:length(launchableData)
                    launchableData{j}.Category = string(launchableData{j}.Category);
                end
            end
        end
    end
end
