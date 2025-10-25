classdef ClientEnumeratorDeviceProvider < matlab.hwmgr.internal.DeviceProviderBase
    %CLIENTENUMERATORDEVICEPROVIDER This is the device provider for devices
    % from downstream client enumerators.

    % This provider loads client enumerators provided from downstream teams
    % for device detection. Each client enumerator leverages some 3rd party
    % driver that is also available from a support package. So there is a
    % mapping from the client enumerator to a support package represented
    % by its base code.
    % Client enumerators are provided in the form of asyncio plugins, hence
    % we have asyncio plugins data captured together with the corresponding
    % support packge in AddOnData.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        %DevicesReady
        %   Flag to track if we have got devices from all downstream client
        %   enumerators
        DevicesReady = false
    end

    properties (Access = {?matlab.unittest.TestCase})
        %DataStore
        %   Handle to the Hardware Manager data store
        DataStore

        %AsyncioPluginMap
        %   A map with keys being base codes and values being corresponding
        %   asyncio plugins info for client enumerators. Values are structs
        %   describe in initDevicePluginMap method.
        AsyncioPluginMap

        %Count
        %   Count to track number of client enumerators that have sent back
        %   a response to "getDevices"
        Count
    end

    methods
        function obj = ClientEnumeratorDeviceProvider()
            obj.DataStore = matlab.hwmgr.internal.DataStoreHelper.getDataStore();
            obj.initDevicePluginMap();
            obj.createAsyncioHostsAndChannels();
        end

        function hwmgrDeviceList = getDevices(obj)
            obj.getDevicesFromClientEnumerators();
            % Waiting for the flag representing we have got responses from
            % all device plugins. This is required becaues our device list
            % does not support async update, yet.
            waitfor(obj, "DevicesReady", true);
            hwmgrDeviceList = obj.convertToHwmgrDevices();
        end

        function delete(obj)
            % Delete all the hosts we created on destruction.
            pluginValues = obj.AsyncioPluginMap.values();
            for i = 1:length(pluginValues)
                if ~isempty(pluginValues{i}.Host) && isvalid(pluginValues{i}.Host)
                    delete(pluginValues{i}.Host);
                end
            end
        end
    end

    methods (Access = private)
        function handleCustomEvent(obj, src, evt)
            % Handle custom events from asyncio
            % "GetDevices" is sent when we receive requested devices
            % "Exception" is sent when exception is thrown from the device
            % plugin.
            if isequal(evt.Type, "GetDevices") || isequal(evt.Type, "Exception")
                if isequal(evt.Type, "GetDevices")
                    baseCode = evt.Data.BaseCode;
                    pluginStruct = obj.AsyncioPluginMap(baseCode);
                    pluginStruct.DriverInstalled = evt.Data.DriverInstalled;
                    pluginStruct.Devices = evt.Data.Devices;
                    obj.AsyncioPluginMap(baseCode) = pluginStruct;
                else
                    warning(message('hwmanagerapp:clientenumerator:DevicePlugin', ...
                        evt.Data.BaseCode, evt.Data.ErrorMessage));
                end
                % Whether we get devices or warnings, we should always join
                % the thread and update the response count
                src.execute("joinThread");
                obj.Count = obj.Count - 1;
                if obj.Count == 0
                    obj.DevicesReady = true;
                end
            end
        end

        function devices = convertToHwmgrDevices(obj)
            % Convert devices returned from client enumerators to Hardware
            % Manager app device objects to be displayed in the app
            devices = [];
            baseCodes = obj.AsyncioPluginMap.keys;

            for i = 1:obj.AsyncioPluginMap.Count
                loadClientEnumerator = obj.shouldLoadClientEnumerator(baseCodes{i});
                if ~loadClientEnumerator
                    continue
                end
                deviceStructs = obj.AsyncioPluginMap(baseCodes{i}).Devices;
                for j = 1:length(deviceStructs)
                    currentDevice = matlab.hwmgr.internal.Device(deviceStructs(j).FriendlyName);
                    currentDevice.CustomData = deviceStructs(j).CustomData;
                    currentDevice.DeviceCardDisplayInfo = deviceStructs(j).DeviceCardDisplayInfo;
                    currentDevice.IconID = deviceStructs(j).IconID;

                    deviceAppletData = matlab.hwmgr.internal.data.DeviceAppletData.empty();
                    for k = 1:length(deviceStructs(j).DeviceAppletData)
                        dataStruct = deviceStructs(j).DeviceAppletData(k);
                        currentDeviceAppletData = matlab.hwmgr.internal.data.DataFactory.createDeviceAppletData(dataStruct.AppletClass, dataStruct.SupportingAddOnBaseCodes);
                        deviceAppletData = [deviceAppletData, currentDeviceAppletData];
                    end

                    deviceLiveTaskData = matlab.hwmgr.internal.data.DeviceLiveTaskData.empty();
                    for k = 1:length(deviceStructs(j).DeviceLiveTaskData)
                        dataStruct = deviceStructs(j).DeviceLiveTaskData(k);
                        currentDeviceLiveTaskData = matlab.hwmgr.internal.data.DataFactory.createDeviceLiveTaskData(dataStruct.LiveTaskDisplayName, dataStruct.SupportingAddOnBaseCodes);
                        deviceLiveTaskData = [deviceLiveTaskData, currentDeviceLiveTaskData];
                    end

                    deviceHardwareSetupData = matlab.hwmgr.internal.data.DeviceHardwareSetupData.empty();
                    
                    if (isfield(deviceStructs(j), 'DeviceHardwareSetupData') && ~isempty(deviceStructs(j).DeviceHardwareSetupData))
                        for k = 1:length(deviceStructs(j).DeviceHardwareSetupData)
                            dataStruct = deviceStructs(j).DeviceHardwareSetupData(k);
                            currentDeviceHardwareSetupData = matlab.hwmgr.internal.data.DataFactory.createDeviceHardwareSetupData(dataStruct.DisplayName, dataStruct.LaunchMode, ...
                                dataStruct.HardwareSetupStatus, dataStruct.WorkflowName, dataStruct.SupportingAddOnBaseCodes, dataStruct.WorkflowArgs);
                            deviceHardwareSetupData = [deviceHardwareSetupData, currentDeviceHardwareSetupData];
                        end
                    end

                    currentDevice.DeviceAppletData = deviceAppletData;
                    currentDevice.DeviceLiveTaskData = deviceLiveTaskData;
                    currentDevice.DeviceHardwareSetupData = deviceHardwareSetupData;
                    currentDevice.UUID = deviceStructs(j).UUID;
                    devices = [devices, currentDevice];
                end
            end
        end

        function initDevicePluginMap(obj)
            % Create a map with keys being spkg base code, and values being
            % structs with fields used below. The map aggregates data of
            % all addons with client enumerator supports and use them to
            % create asyncio host and channels to get devices from each
            % client enumerator/device plugin. The results from each client
            % enumerator are also stored in the map.
            addOnData = obj.DataStore.getAddOnsWithValidAsyncioPlugin();
            map = containers.Map();
            for i = 1:length(addOnData)
                addOnSwitch = addOnData(i).BaseCode;
                if ~isempty(addOnData(i).ClientEnumeratorAddOnSwitch)
                    addOnSwitch = addOnData(i).ClientEnumeratorAddOnSwitch;
                end
                map(addOnData(i).BaseCode) = struct( ...
                    "DevicePlugin", addOnData(i).AsyncioDevicePlugin, ...
                    "ConverterPlugin", addOnData(i).AsyncioConverterPlugin, ...
                    "AddOnSwitch", addOnSwitch, ...
                    "DriverInstalled", false, ...
                    "Host", [], ...
                    "Channel", [], ...
                    "Devices", []);
            end
            obj.AsyncioPluginMap = map;
        end

        function getDevicesFromClientEnumerators(obj)
            obj.Count = obj.AsyncioPluginMap.Count;
            obj.DevicesReady = false;

            baseCodes = obj.AsyncioPluginMap.keys;

            for i = 1:obj.AsyncioPluginMap.Count
                loadClientEnumerator = obj.shouldLoadClientEnumerator(baseCodes{i});
                pluginStruct = obj.AsyncioPluginMap(baseCodes{i});
                if ~loadClientEnumerator
                    obj.Count = obj.Count - 1;
                    % Release the asyncio process
                    if ~isempty(pluginStruct.Host)
                        delete(pluginStruct.Host);
                    end

                    continue
                end

                if obj.usingInProcessAsyncio(baseCodes{i}) || isempty(pluginStruct.Host) || ~isvalid(pluginStruct.Host)
                    % Create host and channel if not exist
                    obj.createAsyncioHostsAndChannels(baseCodes{i});
                end
                % Request devices from client enumerators
                pluginStruct = obj.AsyncioPluginMap(baseCodes{i});
                if ~isempty(pluginStruct.Channel)
                    pluginStruct.Channel.execute("getDevices");
                else
                    % If Channel is not present, reduce the count.
                    obj.Count = obj.Count - 1;
                end 
            end

            % No client enumerator applicable to get devices
            if obj.Count == 0
                obj.DevicesReady = true;
            end
        end

         function createAsyncioHostsAndChannels(obj, baseCode)
            arguments
                obj (1, 1) matlab.hwmgr.internal.providers.ClientEnumeratorDeviceProvider
                baseCode (1, 1) string = ""
            end

            if isempty(obj.AsyncioPluginMap)
                return
            end

            % Create host and channel for one plugin
            if ~isequal(baseCode, "")
                pluginStruct = obj.AsyncioPluginMap(baseCode);
                [pluginStruct.Host, pluginStruct.Channel, success] = obj.createHostAndChannel(baseCode, pluginStruct.DevicePlugin, pluginStruct.ConverterPlugin);
                % Only assign to plugin map if channel creation was success.
                if (success)
                    obj.AsyncioPluginMap(baseCode) = pluginStruct;
                end

                return
            end

            % Create hosts and channels for all plugins with no spkg or
            % toolbox installed
            baseCodes = obj.AsyncioPluginMap.keys;
            for i = 1:obj.AsyncioPluginMap.Count
                loadClientEnumerator = obj.shouldLoadClientEnumerator(baseCodes{i});
                if ~loadClientEnumerator
                    continue
                end
                pluginStruct = obj.AsyncioPluginMap(baseCodes{i});
                [pluginStruct.Host, pluginStruct.Channel, success] = obj.createHostAndChannel(baseCodes{i}, pluginStruct.DevicePlugin, pluginStruct.ConverterPlugin);
                % Only assign to plugin map if channel creation was success.
                if (success)
                    obj.AsyncioPluginMap(baseCodes{i}) = pluginStruct;
                end
            end
        end

        function [host, channel, success] = createHostAndChannel(obj, baseCode, devicePlugin, converterPlugin)
                % Use default converter if the provided one is empty            
            if isempty(converterPlugin)
                    if ispc
                        converterPlugin = fullfile(matlabroot, "toolbox", "shared", "hwmanager", "hwmanagerapp", "clientenumerator", "bin", computer("arch"), "hwmgr_converter");
                    else
                        converterPlugin = fullfile(matlabroot, "toolbox", "shared", "hwmanager", "hwmanagerapp", "clientenumerator", "bin", computer("arch"), "libmwhwmgr_converter");
                end
            end
            try
                % Catch errors from asyncio channel This is a temporary solution.
                % TODO:: g2838504
                % Currently, the try-catch use-case is to catch errors when
                % device drivers are not installed for hardware (g2832993).

                % g2986369 workaround. Corresonding geck for this change is g2899060.
                % If host is MAC and product is webcam,
                % use in-process Asyncio.
                % Remove code assoicated with this function once g2986369 is resolved
                if (obj.usingInProcessAsyncio(baseCode))
                    host = struct.empty;
                    channel = matlabshared.asyncio.internal.Channel(devicePlugin, converterPlugin);
                else
                    host = matlabshared.asyncio.internal.Host;
                    channel = host.createChannel(devicePlugin, converterPlugin);
                end
                addlistener(channel, "Custom", @obj.handleCustomEvent);
                % Assign a flag to return successful channel creation
                success = true;
            catch
                % Assign empty struct for channel.
                channel = struct.empty;
                % Assign false if channel creation errors out.
                success = false;
            end

        end

        function loadClientEnumerator = shouldLoadClientEnumerator(obj, baseCode)
            % Decide if we should load the client enumerator with given
            % base code. This is done by checking if the add-on serving as
            % the client enumerator switch is installed. If that add-on is
            % installed, then disable the corresponding client enumerator.

            addOnSwitch = obj.AsyncioPluginMap(baseCode).AddOnSwitch;
            loadClientEnumerator = ~matlab.hwmgr.internal.util.isInstalled(addOnSwitch);
        end
    end

	methods (Static, Access = private)
        function bool = usingInProcessAsyncio(baseCode)
            % g2986369 workaround. Corresonding geck for this change is g2899060.
            % If host is MAC and product is webcam,
            % use in-process Asyncio.
            % Remove code assoicated with this function once g2986369 is resolved
            bool = ismac && (baseCode == "USBWEBCAM" || baseCode == "OSVIDEO");
        end
    end
end
