classdef GenericDeviceProvider < matlab.hwmgr.internal.DeviceProviderBase
    %GENERICDEVICEPROVIDER This is the device provider for generic devices.
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties(Hidden) 
        DeviceEnumIdentifier =  matlab.hwmgr.internal.DeviceEnumeratorIdentifier();
    end

    properties(Constant)
        ArduinoMLSpkgBaseCode = "ML_ARDUINO"
        ArduinoSLSpkgBaseCode = "ARDUINO"
    end
    
    methods
        function hwmgrDeviceList = getDevices(obj)
            hwmgrDeviceList = [];
            % Check for Arduino support package installation status
            arduinoMLInstalled = matlab.hwmgr.internal.util.isInstalled( ...
                matlab.hwmgr.internal.providers.GenericDeviceProvider.ArduinoMLSpkgBaseCode);

            if arduinoMLInstalled
                return
            end

            enumerators = {'genericEnum'};
            structDevices = obj.DeviceEnumIdentifier.getHwmgrSupportedDevicesData(enumerators);

            for i =  1:length(structDevices)
                hwmgrDeviceList = [hwmgrDeviceList, obj.createHwmgrDevice(structDevices(i))]; %#ok<AGROW>
            end
        end
    end

    methods(Access = private, Static)
        function hwmgrDevice = createHwmgrDevice(deviceStruct)
            % Create Hardware Manager device for generic device
            % mandatory fields
            hwmgrDevice = matlab.hwmgr.internal.GenericDevice(deviceStruct.deviceName);
            hwmgrDevice.BaseCode = {deviceStruct.supportPkg.basecode};
            hwmgrDevice.SupportPackageName = {deviceStruct.supportPkg.supportPkgName};
            hwmgrDevice.HardwareSupportUrl = char(deviceStruct.hardwareSupportUrl);
            hwmgrDevice.IconID = char(deviceStruct.icon);
            hwmgrDevice.VendorID = char(deviceStruct.vid);
            hwmgrDevice.DeviceID = char(deviceStruct.pid);

            if ismember(matlab.hwmgr.internal.providers.GenericDeviceProvider.ArduinoMLSpkgBaseCode, hwmgrDevice.BaseCode)
                hwmgrDevice.DeviceAppletData = matlab.hwmgr.internal.data.DataFactory.createDeviceAppletData( ...
                    "arduinoioapplet.ArduinoExplorerApplet", matlab.hwmgr.internal.providers.GenericDeviceProvider.ArduinoMLSpkgBaseCode);

                % Create DeviceHardwareSetupData for MATLAB Arduino Hardware Setup
                hwmgrDevice.DeviceHardwareSetupData = matlab.hwmgr.internal.data.DataFactory.createDeviceHardwareSetupData(...
                    message('hwmanagerapp:clientappdata:arduinoexplorer:mlArduinoHardwareSetupTitle').getString, ...
                    matlab.hwmgr.internal.data.LaunchModeEnum.Optional, ...
                    matlab.hwmgr.internal.data.HardwareSetupStatusEnum.DidNotRun, ...
                    "matlab.hwmgr.internal.hwsetup.register.ArduinoWorkflow", ...
                    'SupportingAddOnBaseCodes', ...
                    matlab.hwmgr.internal.providers.GenericDeviceProvider.ArduinoMLSpkgBaseCode, ...
                    'WorkflowArgs', ["tripwire", "setup"]);

                % Create DeviceHardwareSetupData for Simulink Arduino Hardware Setup
                slDeviceHardwareSetupData = matlab.hwmgr.internal.data.DataFactory.createDeviceHardwareSetupData(...
                    getString(message('hwmanagerapp:clientappdata:arduinoexplorer:slArduinoHardwareSetupTitle')), ...
                    matlab.hwmgr.internal.data.LaunchModeEnum.Optional, ...
                    matlab.hwmgr.internal.data.HardwareSetupStatusEnum.DidNotRun, ...
                    "matlab.hwmgr.internal.hwsetup.register.ArduinoSLWorkflow", ...
                    'SupportingAddOnBaseCodes', ...
                    matlab.hwmgr.internal.providers.GenericDeviceProvider.ArduinoSLSpkgBaseCode);

                hwmgrDevice.DeviceHardwareSetupData = [hwmgrDevice.DeviceHardwareSetupData slDeviceHardwareSetupData];

                hwmgrDevice.DeviceCardDisplayInfo = ["Connection", "USB"];
            end
        end
    end
end
