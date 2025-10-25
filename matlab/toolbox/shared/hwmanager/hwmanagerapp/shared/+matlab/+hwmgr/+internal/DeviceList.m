classdef DeviceList < matlabshared.mediator.internal.Publisher &...
        matlabshared.mediator.internal.Subscriber & ...
        matlab.hwmgr.internal.MessageLogger
    %DEVICELIST - The Device List Controller is the main class for
    %providing the Device List capabilities to the Hardware Manager
    %Framework.

    %   Copyright 2016-2024 The MathWorks, Inc.

    properties(SetObservable)
        % Run the following command to see listeners for these properties:
        % matlab.hwmgr.internal.util.displayPropListeners('matlab.hwmgr.internal.DeviceList');
        SelectedDeviceUpdate
        DeviceSelectionChanged
        EmptyDeviceList
        UserRemovingDevice
        DeviceListForDdux
        AppletsForDeviceRequest
        FoundDeviceDescriptors
        DevicesAvailableToShow
        ShowDevicesLoadingView
        SelectedDeviceIndexResponse
        SelectedDeviceResponse
        DeviceByIndexResponse
        SelectDeviceInView
        LastUsedDeviceIndexResponse
        LaunchErrorDialog
        FoundDeviceConfigDescriptors
    end

    properties
        Context
        SelectedDevice
    end

    properties(Access = {?matlab.unittest.TestCase})
        % LastRefreshSoft - Boolean indicating whether the last refresh was
        % a soft refresh
        LastRefreshSoft
        
        % LastSelectedDeviceUUID - A string capturing what the previously
        % selected device's UUID was. Used to remember the user's
        % previous device selection when the device list is refreshed
        LastSelectedDeviceUUID = ""
    end

    properties(Access = ?matlab.unittest.TestCase)
        % DEVICEPROVIDERS - an array of device providers
        DeviceProviders

        % DEVICEDESCRIPTORS - an array of device descriptors for non
        % enumerable devices
        DeviceDescriptors

        % CONFIGDESCRIPTORS - an array of device configuration descriptors
        ConfigDescriptors

        % DEVICELIST - a cache of available devices retrieved from the
        % providers. Note that the FILTERDDEVICELIST is what is shown in
        % the device list web app. This is a column vector
        DevList

        % FILTEREDDEVICELIST - a cache of devices that are shown in the
        % device list. This is a filtered subset of DEVICELIST. This is a
        % parallel list of devices to the list of devices available to the
        % web application. This is a column vector.
        FilteredDeviceList

        % LAUNCHAPPLETONDEVICECHANGE - flag to indicate that the applet used
        % for filtering should be launched on device change
        LaunchAppletOnDeviceChange

        % DEVICELISTFILTER - The criteria that can be used to filter the
        % list of devices if necessary
        DeviceListFilter

        % APPLETSFORDEVICERESPONSE - The response recieved from the
        % Toolstrip for the request to provide the list of applets for a
        % given device
        AppletsForDeviceResponse
    end

    methods (Static)

        function index = getDeviceIndexFromList(deviceList, deviceToFind)
            index = [];
            for i = 1:numel(deviceList)
                if deviceList(i) == deviceToFind
                    % Use == here because we have over overridden "eq" of
                    % the Device class to compare UUID. Also, due to the
                    % applyUUIDToDevices method being applied to all
                    % devices, they are guaranteed to have a UUID.
                    index = i;
                    break;
                end
            end
        end

        function out = getPropsAndCallbacks()
            out  = ...
                ... % Property to listen to         % Callback function
                ["FoundDeviceProviders"             "setDeviceProviders";...
                "SelectDeviceByIndex"               "selectDeviceByIndex"; ...
                "SelectDeviceByObject"              "selectDeviceByObject"; ...
                "DeviceAdded"                       "handleDeviceAdded"; ...
                "DeviceRemovedOnStartPage"        	"removeDeviceByIndex"; ...
                "DeviceUpdated"                     "updateDeviceByObject"; ...
                "AppletsForDeviceResponse"          "handleAppletsForDeviceResponse";...
                "DeviceSelectedOnStartPage"       	"handleDeviceSelectedOnStartPage"; ...
                "RefreshDeviceList"                 "refreshDeviceList"; ...
                "DeviceRemovedFromHwmgrApp"         "handleDeviceRemovedFromHwmgrApp"; ... 
                "RequestDeviceByIndex"              "handleRequestDeviceByIndex"; ...
                "RemoveDeviceByIndex"               "removeDeviceByIndex"; ...
                "SelectDeviceByPriority"            "handleSelectDeviceByPriority"; ...
                "ShowAppletAfterConfiguring"        "handleShowAppletAfterConfiguring"; ...
                ];
        end

        function out = getPropsAndCallbacksNoArgs()
            out  = ...
                ... % Property to listen to         % Callback function
                [
                "RequestSelectedDeviceIndex"        "handleRequestSelectedDeviceIndex"; ...
                "RequestSelectedDevice"             "handleRequestSelectedDevice"; ...
                "DeselectDevice"                    "deselectDevice"; ...
                "RequestLastUsedDeviceIndex"        "handleRequestLastUsedDeviceIndex"; ...
                ];
        end
    end

    methods
        % Constructor
        function obj = DeviceList(mediator)
            arguments
                % Default value for mediator to allow for mocking in unit
                % tests
                mediator = matlabshared.mediator.internal.Mediator;
            end
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);

            % Initialize filter to show all devices;
            obj.DeviceListFilter = struct('FilterType', 'None', 'FilterValue', '');

            % Don't launch applets on device change by default
            obj.LaunchAppletOnDeviceChange = false;
        end

        function subscribeToMediatorProperties(obj, ~, ~)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);

            eventsAndCallbacksNoArgs = obj.getPropsAndCallbacksNoArgs();
            obj.subscribeWithGatewaysNoArgs(eventsAndCallbacksNoArgs, @obj.subscribe);
        end

        % %%%%%%%%% CALLBACKS %%%%%%%%%%%% %
        
        function handleDeviceSelectedOnStartPage(obj, deviceIndex)
            
            % Note that the deviceIndex argument to this method is a 1
            % based MATLAB array index.
            if obj.Context.IsHwmgrApp
                if (deviceIndex == 0)
                    deviceIndex = obj.getSelectedDeviceIndex();
                end
                % Clear previous selected device, otherwise clientSelectDevice may
                % simply return on same device

                obj.setSelectedDevice([]);
            end
            obj.selectDeviceByIndex(deviceIndex);
        end

        function handleDeviceRemovedFromHwmgrApp(obj, index)
            obj.removeDevice(index);
            allDevices = obj.getFilteredDeviceList();
            % Send device list to HWMGR app
            obj.logAndSet("DevicesAvailableToShow", allDevices);
        end

        function setDeviceProviders(obj, providers)
            % Set the available device providers
            obj.DeviceProviders = providers;
            obj.setDeviceDescriptorsFromProviders(providers);
            obj.setDeviceConfigDescriptorsFromProviders(providers);
        end

        function refreshDeviceList(obj, doSoftLoad)
            arguments
               obj
               doSoftLoad (1,1) logical = false;
            end

            % Show loading message in the device list
            obj.logAndSet("ShowDevicesLoadingView", true);

            % Unset any selected device
            obj.setSelectedDevice([]);

            % Get the devices from plugins - this can be time consuming.
            % Note that this also loads the cached/previously added
            % non-enumerable devices
            obj.refreshDeviceListCache(doSoftLoad);

            % This is needed to allow objects to be deleted properly when
            % user closes the app during app initilization
            drawnow;

            % The user may have closed the UI and thus deleted the
            % framework during the long refresh operation
            if ~isvalid(obj)
                return;
            end

            % Filter the device list if a filter is present
            obj.filterDeviceList();

            allDevices = obj.getFilteredDeviceList();

            % Send device list to all the modules that have a device list
            % view
            obj.logAndSet("DevicesAvailableToShow", allDevices);
            
            obj.logAndSet("DeviceListForDdux", allDevices);

            obj.applyUpdatedDeviceListChecks();
        end

        function selectDeviceByIndex(obj, deviceIndex)
            % Select the device requested by the framework from the list of
            % devices in view. This method is called whenever a client
            % would like a device to be selected.

            % This method handles the case when the same device is selected
            % or there are no devices available for selection so is safe to
            % call. Prefer this over the closeAppAndSelectDevice() method
            % or the selectDevice() method.

            % In the following two checks, we use FilteredDeviceList
            % instead of the raw DeviceList. This is because
            % FilteredDeviceList is actually the the devices in view.

            if deviceIndex == 0
                % "0" means the user canceled adding device in the modal tab
                % and cancelPramsHook requests to select previously selected device
                deviceIndex = obj.getSelectedDeviceIndex();
            elseif deviceIndex == obj.getSelectedDeviceIndex()
                % If the same device is requested to be selected, then return
                % (no-op). Note that this is possible via a direct framework
                % API call to selectDevice(). It is not possible to select the
                % same device via the UI since clicking on the same device does
                % not trigger a MATLAB callback via the device list web app.
                return;
            end

            obj.selectDevice(deviceIndex);

            selectedDevice = obj.getSelectedDevice();

            if isempty(selectedDevice)
                return;
            end

            % This will update the copy of the selected device object that
            % all the modules have
            obj.logAndSet("SelectedDeviceUpdate", selectedDevice);

            % This will trigger controller actions due to device selection
            % change
            obj.logAndSet("DeviceSelectionChanged", obj.DeviceListFilter.FilterValue);

            obj.logAndSet("SelectDeviceInView", deviceIndex);

        end

        function handleShowAppletAfterConfiguring(obj, selectedDevice)
            % Select the device requested by the framework from the list of
            % devices in view. This method is called whenever a client
            % would like a device to be selected.
            obj.selectDeviceByObject(selectedDevice);
            % This will update the copy of the selected device object that
            % all the modules have
            obj.logAndSet("SelectedDeviceUpdate", obj.getSelectedDevice());

            % This will trigger controller actions due to device selection
            % change
            obj.logAndSet("DeviceSelectionChanged", obj.DeviceListFilter.FilterValue);
        end

        function success = selectLastSelectedDevice(obj)
            % This method will select the user's previously selected
            % device. 

            % If the currently selected device is the same as the
            % previously selected device this method is a no-op

            success = true;

            previouslySelectedDeviceIndex = obj.getLastSelectedDeviceIndex();

            if isempty(previouslySelectedDeviceIndex)
                success = false;
                return;
            end

            obj.selectDeviceByIndex(previouslySelectedDeviceIndex);
        end

        function selectDeviceByObject(obj, device)
            index = obj.getDeviceIndexForDevice(device);
            obj.selectDeviceByIndex(index);
        end

        function handleDeviceAdded(obj, newDevice)
            % This method will add the requested non enumerable device to
            % the top of the list of devices

            % Note: There is no check right now of duplicate non-enum
            % devices being added. This is currently on the downstream
            % teams to ensure duplicate non-enum devices are not added to
            % the list

            % First, we need to update the overall device list Add the
            % non-enum device to the beginning of the device list cache
            currentDevices = obj.getDeviceList();

            devices = [newDevice; currentDevices];

            % Apply default UUIDs to devices if they have not been supplied
            % by the providers
            devices = matlab.hwmgr.internal.util.applyUUIDToDevices(devices);

            % Update the device provider for the non-enum device
            obj.addDevicesToProvidersCache(devices(1));

            obj.setDeviceList(devices);

            % We should cache non-enum devices, filter devices to get
            % those with non-empty descriptor and cache enum devices that
            % need cache
            devicesToCache = [devices(arrayfun(@(x) ~isempty(x.Descriptor), devices)); devices(arrayfun(@(x) (x.CacheDevice), devices))];

            % Also update the user's preference cache of devices
            matlab.hwmgr.internal.util.PrefDataHandler.writeDevicesToCache(devicesToCache);

            % Next we need to update the filtered device list
            obj.filterDeviceList();

            % Send device list to all the modules that have a device list
            % view
            allDevices = obj.getFilteredDeviceList();
            obj.logAndSet("DevicesAvailableToShow", allDevices);

            obj.applyUpdatedDeviceListChecks();
        end

        function handleAppletsForDeviceResponse(obj, applets)
            obj.AppletsForDeviceResponse = applets;
        end
        
        function handleRequestSelectedDeviceIndex(obj)
            index = obj.getSelectedDeviceIndex();
            obj.logAndSet("SelectedDeviceIndexResponse", index);
        end

        function handleRequestSelectedDevice(obj)
            device = obj.getSelectedDevice();
            obj.logAndSet("SelectedDeviceResponse", device);
        end

        function handleRequestDeviceByIndex(obj, index)
            device = obj.getDeviceByIndex(index);
            obj.logAndSet("DeviceByIndexResponse", device);
        end

        function deselectDevice(obj)
            obj.setSelectedDevice([]);
        end

        function handleRequestLastUsedDeviceIndex(obj)
            % This API method will return the calling module the last used
            % or last selected device index
 
            obj.logAndSet("LastUsedDeviceIndexResponse", obj.getLastSelectedDeviceIndex());
        end

        function handleSelectDeviceByPriority(obj, priority)
            % This method will try to select the device indicated in the
            % priority array starting from the first element of the first
            % array.

            % Valid priority arrays
            % [1] - Select the first device
            % [-1] - Select the last selected device if possible.
            % [-1 1] - Select the last selected device if possible,
            % otherwise select the first device 

            for i = 1:numel(priority)

                if priority(i) == -1
                    % Try to select the previously selected device. If
                    % successful, return.
                    if obj.selectLastSelectedDevice()
                        return;
                    end
                else
                    % Otherwise select device by priority index and return
                    obj.selectDeviceByIndex(priority(i));
                    return;
                end

            end
        end

        % %%%%%%%%% END CALLBACKS %%%%%%%% %


        % %%%%%%%%% API METHODS %%%%%%%% %
        function out = getDeviceProviders(obj)
            out = obj.DeviceProviders;
        end

        function setDeviceListFilter(obj, filter)
            % Set the filter for displaying devices

            obj.DeviceListFilter = filter;
            % Filter the device list with the given filter
            obj.filterDeviceList();

            % After filtering, update the device list view
            filteredDeviceList = obj.getFilteredDeviceList();
            if isempty(filteredDeviceList)
                obj.setSelectedDevice([]);

                %  Tell the Main Controller that the device list is empty
                obj.logAndSet("EmptyDeviceList", "");
            end
        end
                
        function deviceList = getDeviceList(obj)
            % Returns the list of devices available to the module
            deviceList = obj.DevList;
        end

        function filteredDeviceList = getFilteredDeviceList(obj)
            % Returns the list of devices that are provided to the device
            % list web app for display

            filteredDeviceList = obj.FilteredDeviceList;
            % Update the configuration params to show config option and
            % warning
            filteredDeviceList = obj.updateConfigParams(filteredDeviceList);
        end

        function device = getSelectedDevice(obj)
            % Returns the device the is currently selected
            device = obj.SelectedDevice;
        end

        function index = getSelectedDeviceIndex(obj)
            index = obj.getDeviceIndexForDevice(obj.SelectedDevice);
        end

        function setLaunchAppletOnDeviceChange(obj, launchFlag)
            % Set a flag to indicate to the device list module whether to
            % request launching the filtering applet on device selection
            % change
            obj.LaunchAppletOnDeviceChange = launchFlag;
        end

        function removeDeviceByIndex(obj, deviceIndex)

            device = obj.getDeviceByIndex(deviceIndex);

            % Since device removal was approved, signal to the main
            % controller that the user is going ahead with device removal.
            obj.logAndSet("UserRemovingDevice", device);

            % Remove the device and refresh the device list view. Note that
            % the following method will also notify the controller if the
            % device list is now empty.
            obj.removeDevice(deviceIndex);

            allDevices = obj.getFilteredDeviceList();
            % Send device list to all the modules that have a device list
            % view
            obj.logAndSet("DevicesAvailableToShow", allDevices);

            obj.applyUpdatedDeviceListChecks();
        end

        function updateDeviceByObject(obj, device)
            % updates device in provider cache as well as user's pref dir
            if isstring(device)
                return
            end

            % Update the device and refresh the device list view
            obj.updateDevice(device);

            allDevices = obj.getFilteredDeviceList();

            % Send device list to all the modules that have a device list
            % view
            obj.logAndSet("DevicesAvailableToShow", allDevices);

            obj.applyUpdatedDeviceListChecks();
        end


    end

    methods (Access = private)


        function index = getLastSelectedDeviceIndex(obj)
            % This method returns the index of the last selected device
            % from the list of devices currentlty in the filtered device
            % list. If no match is found (i.e. no previously selected
            % device or previously selected device cannot be found in the
            % device list) then the index returned is empty.

            deviceList = obj.getFilteredDeviceList();

            allUUIDs = [deviceList.UUID];

            index = find(allUUIDs == obj.LastSelectedDeviceUUID);
            if isempty(index)
                index = [];
            end

        end

        function provider = getProviderForDevice(obj, device)
            provider = [];
            for i = 1:numel(obj.DeviceProviders)
                if string(class(obj.DeviceProviders(i))) == device.ProviderClass
                    provider = obj.DeviceProviders(i);
                    break;
                end
            end

        end

        function setDeviceDescriptorsFromProviders(obj, devProviders)
            % Get the descriptors from the device providers
            obj.DeviceDescriptors = [];
            for i = 1:numel(devProviders)
                newDescriptors = devProviders(i).getDeviceDescriptorsAndInit();

                obj.DeviceDescriptors = [obj.DeviceDescriptors; newDescriptors];
            end

            % Send the list of device descriptors to the Toolstrip module
            % and the ClientAppStartPage
            obj.logAndSet("FoundDeviceDescriptors", obj.DeviceDescriptors);
        end

        function setDeviceConfigDescriptorsFromProviders(obj, devProviders)
            % Get the descriptors from the device providers
            obj.ConfigDescriptors = [];
            for i = 1:numel(devProviders)
                newDescriptors = devProviders(i).getConfigureDescriptorsAndInit();

                obj.ConfigDescriptors = [obj.ConfigDescriptors; newDescriptors];
            end

            % Send the list of device descriptors to the Toolstrip module
            obj.logAndSet("FoundDeviceConfigDescriptors", obj.ConfigDescriptors);
        end

        function addDevicesToProvidersCache(obj, devices)
            % This method will take an array of devices and add
            % each device to its parent provider's "DevicesProvided"
            % list
            for i = 1:numel(devices)
                newDevice = devices(i);

                % Add the new device to its parent provider's devices
                % provided list
                devProvider = obj.getProviderForDevice(newDevice);
                devProvider.addToDevicesProvided(newDevice);
            end
        end

        function removeDevicesFromProviderCache(obj, devicesToRemove)
            for i = 1:numel(devicesToRemove)
                device = devicesToRemove(i);
                devProvider = obj.getProviderForDevice(device);
                % If no device provider was found it means the plugin for
                % the device has been unloaded/is no longer tracked by the
                % device list. As such, skip updating the DevicesProvided
                % property
                if ~isempty(devProvider)
                    devProvider.removeFromDevicesProvided(device);
                end
            end
        end

        function updateDevicesInProviderCache(obj, devicesToUpdate)
            for i = 1:numel(devicesToUpdate)
                device = devicesToUpdate(i);
                devProvider = obj.getProviderForDevice(device);
                % If no device provider was found it means the plugin for
                % the device has been unloaded/is no longer tracked by the
                % device list. As such, skip updating the DevicesProvided
                % property
                if ~isempty(devProvider)
                    devProvider.updateInDevicesProvided(device);
                end
            end
        end

        function selectDevice(obj, deviceIndex)
            % Selects a device from the list of devices in the filtered view
            % by the index provided

            % If no devices are available for selection, then return
            if isempty(obj.FilteredDeviceList)
                return;
            end

            obj.setSelectedDevice(obj.FilteredDeviceList(deviceIndex));
        end

        function removeDevice(obj, deviceIndex)
            % This method will remove a single device from the device list,
            % given the index of the device in the device list

            % Get the device to remove from the filtered device list
            deviceToRemove = obj.FilteredDeviceList(deviceIndex);

            % Next, find the device in the device list and remove it
            currentDevices = obj.getDeviceList();
            deviceIndToRemove = arrayfun(@(x)isequal(x,deviceToRemove), currentDevices);

            obj.removeDevicesFromProviderCache(deviceToRemove);

            % Update the device list
            currentDevices = currentDevices(~deviceIndToRemove);
            obj.setDeviceList(currentDevices);

            % Only cache the manually added and cached devices
            devicesToCache = [currentDevices(arrayfun(@(x) ~isempty(x.Descriptor), currentDevices)); currentDevices(arrayfun(@(x) (x.CacheDevice), currentDevices))];

            % Update the user's preference cache of manually added devices
            matlab.hwmgr.internal.util.PrefDataHandler.writeDevicesToCache(devicesToCache);

            % Next, refresh the filtered device list
            obj.filterDeviceList();
        end

        function updateDevice(obj, deviceToUpdate)

            deviceToUpdate.CacheDevice = true;
            % Next, find the device in the device list
            currentDevices = obj.getDeviceList();
            deviceIndToUpdate = arrayfun(@(x)isequal(x.UUID,deviceToUpdate.UUID), currentDevices);

            obj.updateDevicesInProviderCache(deviceToUpdate);

            % Update the device list
            currentDevices(deviceIndToUpdate) = deviceToUpdate;
            obj.setDeviceList(currentDevices);

            % Update the user's preference cache of manually added devices
            devicesToCache = [currentDevices(arrayfun(@(x) ~isempty(x.Descriptor), currentDevices)); currentDevices(arrayfun(@(x) (x.CacheDevice), currentDevices))];
            matlab.hwmgr.internal.util.PrefDataHandler.writeDevicesToCache(devicesToCache);
            
            % Next we need to update the filtered device list
            obj.filterDeviceList();
        end

        function devParamDescriptors = getDevParamDescriptorsFromProviders(obj)
            % Return all device parameter descriptors that are provided via
            % the device providers. This method will in turn invoke the
            % getDeviceParamDescriptors() method on the providers

            devParamDescriptors = [];

            for i = 1:numel(obj.DeviceProviders)
                newDescriptor = obj.DeviceProviders(i).getDeviceParamDescriptors();

                % Transpose to column array if returned as row from
                % provider
                if isrow(newDescriptor)
                    newDescriptor = newDescriptor';
                end

                % Append to list of available descriptors
                devParamDescriptors = [devParamDescriptors; newDescriptor]; %#ok<AGROW>
            end
        end
        
        function detecteddevices = updateWithCachedDevices(obj, detecteddevices, cacheddevices)
            for a = 1: length(cacheddevices)
                for b = 1: length(detecteddevices)
                    if(cacheddevices(a).UUID == detecteddevices(b).UUID)
                        detecteddevices(b) = cacheddevices(a);
                    end
                end
            end
        end

        function filteredDevices = filterCachedDevicesByDescriptors(obj, devices)
            filteredDevices = [];
            availableDescriptors = obj.getDevParamDescriptorsFromProviders();

            % If no descriptors are available, then return
            if isempty(availableDescriptors)
                return;
            end

            for i=1:numel(devices)
                currentDevice = devices(i);
                isPluginLoaded = any(string(currentDevice.Descriptor) == arrayfun(@(x)string(class(x)), availableDescriptors));
                if isPluginLoaded
                    filteredDevices = [filteredDevices; currentDevice];  %#ok<AGROW>
                end
            end
        end

        function filteredDevices = filterDevicesByApplet(obj, appletStruct, devices)
            % Returns a list of devices from DEVICES that are supported by
            % the specified APPLET

            filteredDevices = [];
            for i = 1:numel(devices)

                % Get the applets for the current device from the Toolstrip
                % module
                obj.logAndSet("AppletsForDeviceRequest", devices(i));

                appletsForDevice = obj.AppletsForDeviceResponse;
                % convert function handles to string for checking member
                appletStr = func2str(appletStruct.Constructor);
                appletsForDeviceStr = arrayfun(@(x) func2str(x.Constructor), appletsForDevice, 'UniformOutput', false);
                % no need to convert char or string, ismember takes care of
                % it automatically
                if ismember(appletStr, appletsForDeviceStr)
                    filteredDevices = [filteredDevices; devices(i)]; %#ok<AGROW>
                end
            end
            obj.FilteredDeviceList = filteredDevices;
        end

        function filterDeviceList(obj)
            % Apply specified filter
            if strcmpi(obj.DeviceListFilter.FilterType, 'None')
                obj.FilteredDeviceList = obj.DevList;
            elseif strcmpi(obj.DeviceListFilter.FilterType, 'Applet')
                obj.filterDevicesByApplet(obj.DeviceListFilter.FilterValue, obj.DevList);
            else
                error('Unknown Device List view filter option: "%s"',obj.DeviceListFilter.FilterType);
            end
        end

        function devices = updateConfigParams(obj, devices)
            if obj.Context.IsHwmgrApp
                return
            end

            for d = 1:length(devices)
                    for j = 1:length(devices(d).DeviceEnumerableConfigData)
                        if devices(d).DeviceEnumerableConfigData(j).AppletClass == obj.Context.AppletClass
                            devices(d).ShowConfigOption = true;
                            if (devices(d).DeviceEnumerableConfigData(j).NeedsConfiguration)
                                devices(d).ShowConfigWarning = true;
                            end
                        end
                    end
            end
        end

        function device = getDeviceByIndex(obj, index)
            device = obj.FilteredDeviceList(index);
        end

        function deviceIndex = getDeviceIndexForDevice(obj, device)
            deviceIndex = obj.getDeviceIndexFromList(obj.FilteredDeviceList, device);
        end

        function [devices, addEnumDevsToProviderCache] = getDevicesFromProviders(obj, doSoftLoad)
            % Return all devices from the providers. This method will call
            % the getDevices() method on the providers which in turn will
            % enumerate the devices. Note that this can take some time

            devices = [];
            addEnumDevsToProviderCache = false;
            
            for i = 1:numel(obj.DeviceProviders)
                % Get the devices from the provider. This is a time
                % consuming operation that occurs while hardware manager is
                % modal. Therefore, we need to check if the user closed
                % hardware manager during the operation
                try
                    if doSoftLoad && ~isempty(obj.DeviceProviders(i).DevicesProvided)
                        newDevices = obj.DeviceProviders(i).DevicesProvided;
                        % Only grab enum devices
                        newDevices = newDevices(arrayfun(@(x)~x.IsNonEnumerable, newDevices));
                    else
                        newDevices = obj.DeviceProviders(i).getDevicesAndInit();
                        addEnumDevsToProviderCache = true;
                    end
                catch ex
                    msgID = 'hwmanagerapp:devicelist:BrokenDeviceProvider';
                    warning(message(msgID, class(obj.DeviceProviders(i)), ex.message));
                    continue;
                end

                if ~isvalid(obj)
                    return;
                end

                % Append to list of available devices
                devices = [devices; newDevices]; %#ok<AGROW>
            end
        end

    end


    methods (Access = {?matlab.hwmgr.internal.MessageHandler, ...
            ?matlab.unittest.TestCase, ...
            ?matlab.hwmgr.internal.HardwareManagerFramework})
        % Access attribute syntax does not support "protected" and class
        % list at the same time. Thus, we are giving access to this class,
        % its subclasses and test class using a list.


        function setSelectedDevice(obj, device)
            obj.SelectedDevice = device;
            
            % If the selected device is not empty (i.e. not being reset,
            % then cache the selected device UUID to remember the user's
            % selection)
            if ~isempty(device)
                obj.LastSelectedDeviceUUID = device.UUID;
            end
        end

        function setDeviceList(obj, devices)
            % Update the list of available devices. Note that this is a
            % parallel, time-consistent list to the list the web
            % application has of available devices
            obj.DevList = devices;
        end


        function setFilteredDeviceList(obj, devices)
            % Update the list of available devices to be used in the device
            % list view

            obj.FilteredDeviceList = devices;
        end

        function refreshDeviceListCache(obj, doSoftLoad)
            % This method will update the device list
            % module's cache of devices by getting a new list of device
            % providers from the loaded plugins and then getting the list
            % of devices from the providers.

            arguments
               obj
               doSoftLoad (1,1) logical = false;
            end
            
            % Load any cached devices
            [cachedDevices, errorID] = matlab.hwmgr.internal.util.PrefDataHandler.loadDevicesFromCache();
            
            % For now, we solve geck 2923958 by deleting the cache file if any error is generated while
            % loading the devices from file. We will alert the user after the refresh is done. 
            if ~isempty(errorID)
                matlab.hwmgr.internal.util.PrefDataHandler.deleteCacheFile();
            end

            % Only load devices for which the device providers are
            % available (i.e plugins are loaded). It is possible that the
            % device provider may no longer be available due to:
            % 1. launching hardware manager with different plugins
            % 2. uninstalling the device provider and plugin
            nonEnumDevices = [];
            if ~isempty(cachedDevices)
                nonEnumDevices = obj.filterCachedDevicesByDescriptors(cachedDevices([cachedDevices.IsNonEnumerable]));
            end

            % Get the list of enumerated devices. This will also update the
            % device provider cache if it is empty
            [enumDevices, addEnumDevsToProviderCache] = obj.getDevicesFromProviders(doSoftLoad);

            if ~isempty(cachedDevices)
                enumDevices = obj.updateWithCachedDevices(enumDevices, cachedDevices(~[cachedDevices.IsNonEnumerable]));
            end

            % Set the last refresh flag
            obj.LastRefreshSoft = doSoftLoad;

            % If the user closed the UI while hardware manager was loading
            % devices, the framework has been deleted. Check for this and
            % return if true
            if ~isvalid(obj)
                return;
            end

            % Handle multiple device instances for the same physical device
            % from different teams
            % First get devices with non-empty UUIDs
            devicesWithUUID = enumDevices(arrayfun(@(x) x.UUID ~= "", enumDevices));
            if ~isempty(devicesWithUUID)
                UUIDs = [devicesWithUUID.UUID];
                % Then get unique UUIDs and duplicate UUIDs
                [~, uniqueIndices] = unique(UUIDs, 'stable');
                duplicateUUIDs = UUIDs(setdiff(1:numel(UUIDs), uniqueIndices));
    
                % Consolidate duplicate devices in enumDevices
                for i = 1:numel(duplicateUUIDs)
                    % For each duplicate UUID, consolidate the devices to the
                    % first one.
                    duplicateIndices = find([enumDevices.UUID] == duplicateUUIDs(i));
                    for j = 2:numel(duplicateIndices)
                        enumDevices(duplicateIndices(1)).DeviceAppletData =  [enumDevices(duplicateIndices(1)).DeviceAppletData, enumDevices(duplicateIndices(j)).DeviceAppletData];
                        enumDevices(duplicateIndices(1)).DeviceLiveTaskData =  [enumDevices(duplicateIndices(1)).DeviceLiveTaskData, enumDevices(duplicateIndices(j)).DeviceLiveTaskData];
                        enumDevices(duplicateIndices(1)).DeviceHardwareSetupData =  [enumDevices(duplicateIndices(1)).DeviceHardwareSetupData, enumDevices(duplicateIndices(j)).DeviceHardwareSetupData];
                        enumDevices(duplicateIndices(1)).DeviceSimulinkModelData =  [enumDevices(duplicateIndices(1)).DeviceSimulinkModelData, enumDevices(duplicateIndices(j)).DeviceSimulinkModelData];
                        enumDevices(duplicateIndices(1)).DeviceExampleData =  [enumDevices(duplicateIndices(1)).DeviceExampleData, enumDevices(duplicateIndices(j)).DeviceExampleData];
                        enumDevices(duplicateIndices(1)).DeviceHelpDocData =  [enumDevices(duplicateIndices(1)).DeviceHelpDocData, enumDevices(duplicateIndices(j)).DeviceHelpDocData];
                        enumDevices(duplicateIndices(1)).DeviceEnumerableConfigData =  [enumDevices(duplicateIndices(1)).DeviceEnumerableConfigData, enumDevices(duplicateIndices(j)).DeviceEnumerableConfigData];
                    end
                    
                    % deduplicate device applet data, live task data, hardware setup and config data
                    appletData = enumDevices(duplicateIndices(1)).DeviceAppletData;
                    [~, uniqueAppIndices] = unique([appletData.IdentifierReference], 'stable');
                    enumDevices(duplicateIndices(1)).DeviceAppletData = appletData(uniqueAppIndices);
    
                    liveTaskData = enumDevices(duplicateIndices(1)).DeviceLiveTaskData;
                    [~, uniqueLiveTaskIndices] = unique([liveTaskData.LiveTaskDisplayName], 'stable');
                    enumDevices(duplicateIndices(1)).DeviceLiveTaskData = liveTaskData(uniqueLiveTaskIndices);

                    configEnumData = enumDevices(duplicateIndices(1)).DeviceEnumerableConfigData;
                    [~, uniqueConfigDataIndices] = unique([configEnumData.AppletClass], 'stable');
                    enumDevices(duplicateIndices(1)).DeviceEnumerableConfigData = configEnumData(uniqueConfigDataIndices);
    
    
                    hardwareSetupData = enumDevices(duplicateIndices(1)).DeviceHardwareSetupData;
                    [~, uniqueHardwareSetupIndices] = unique([hardwareSetupData.IdentifierReference], 'stable');
                    enumDevices(duplicateIndices(1)).DeviceHardwareSetupData = hardwareSetupData(uniqueHardwareSetupIndices);

                    deviceData = enumDevices(duplicateIndices(1)).DeviceExampleData;
                    [~, uniqueDeviceDataIndices] = unique([deviceData.IdentifierReference], 'stable');
                    enumDevices(duplicateIndices(1)).DeviceExampleData = deviceData(uniqueDeviceDataIndices);

                    deviceData = enumDevices(duplicateIndices(1)).DeviceSimulinkModelData;
                    [~, uniqueDeviceDataIndices] = unique([deviceData.IdentifierReference], 'stable');
                    enumDevices(duplicateIndices(1)).DeviceSimulinkModelData = deviceData(uniqueDeviceDataIndices);

                    deviceData = enumDevices(duplicateIndices(1)).DeviceHelpDocData;
                    [~, uniqueDeviceDataIndices] = unique([deviceData.IdentifierReference], 'stable');
                    enumDevices(duplicateIndices(1)).DeviceHelpDocData = deviceData(uniqueDeviceDataIndices);

                    % Add duplicate devices to providers cache before they are
                    % removed. This is needed to trace them back when an app is
                    % launched from the HWMGR app, and we need to select the
                    % device in client app
                    obj.addDevicesToProvidersCache(enumDevices(duplicateIndices(2:end)));
                    
                    % Remove duplicate devices except the first one
                    enumDevices(duplicateIndices(2:end)) = [];
                end
            end

            refreshedDeviceList = [nonEnumDevices; enumDevices];

            % Apply default UUIDs to devices if they have not been supplied
            % by the providers
            refreshedDeviceList = matlab.hwmgr.internal.util.applyUUIDToDevices(refreshedDeviceList);

            % Update the cache of devices in this module
            obj.setDeviceList(refreshedDeviceList);
            obj.setFilteredDeviceList(refreshedDeviceList);

            % If the enum devices were newly enumerated (i.e. we are not
            % using the cached enum devices in a soft load) then we need to
            % add them to the respective device provider cache after all
            % the UUIDs have been assigned.
            %
            % Note that the non enumerable devices were already added to
            % the provider cache after UUID assignment in the
            % "handleDeviceAdded" method so we don't need to do anything
            % here.
            if addEnumDevsToProviderCache
                enumDevicesWithUuid = refreshedDeviceList(arrayfun(@(x)~x.IsNonEnumerable, refreshedDeviceList));
                obj.addDevicesToProvidersCache(enumDevicesWithUuid);
            end

            % Handle any errors occured during a refresh
            if ~isempty(errorID) 
                title = string(message('hwmanagerapp:devicelist:DeviceConfigErrorDialogTitle').getString);
                msg = string(message('hwmanagerapp:devicelist:DeviceConfigErrorDialogMsg').getString);
                obj.logAndSet("LaunchErrorDialog", struct("title", title, "message", msg));
            end
        end

        function applyUpdatedDeviceListChecks(obj)
            % Send device list to all the modules that have a device list
            % view
            filteredDeviceList = obj.getFilteredDeviceList();

            if isempty(filteredDeviceList)
                obj.setSelectedDevice([]);

                %  Tell the Main Controller that the device list is empty
                obj.logAndSet("EmptyDeviceList", "");
            end
        end
    end

    methods (Static, Access = private)
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
