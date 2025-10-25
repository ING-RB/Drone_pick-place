classdef HwmgrAppDduxBridge < handle
    % HwmgrAppDduxBridge is a utility class that has methods to send the
    % custom Hardware Manager App DDUX telemetry events to log app usage data.

    % Copyright 2021 Mathworks Inc.

    properties (Constant)
        Product = "ML"
        AppComponent = "ML_HWMGR"
        AddHardwareDlgKey = "ML_HWMGR_ADDHARDWARE"
        DeviceDetailDlgKey = "ML_HWMGR_DEVICEDIALOG"
    end

    methods (Static)
        function logAddonInstallAddHardwareDlg(jsDduxData)
            data = struct;
            
            data.hardwaretype = string(jsDduxData.Keyword);
            data.hardwarevendor = string(jsDduxData.Manufacturer);
            data.addoninstallstart = string(jsDduxData.Basecode);
            data.hardwaresearched = "";
            data.addoninstallsuccessful = jsDduxData.AddonInstallSuccess;
            
            ServiceLauncher = matlab.hwmgr.internal.ServiceLauncher();
            installerType = ServiceLauncher.getInstallerTypeForBaseCode(jsDduxData.Basecode);
            data.launchedaddonexplorer = installerType ~= "SSI";
            
            matlab.hwmgr.internal.HwmgrAppDduxBridge.logAddHardwareDialog(data);
        end

        function logAddonInstallDeviceDetailDlg(jsDduxData, selectedDevice)
            data = struct;
            
            data.dvfriendlyname = string(selectedDevice.FriendlyName);
            data.dvvendorid = string(selectedDevice.VendorID);
            data.dvisnonenumerable = selectedDevice.IsNonEnumerable;
            data.dvprovider = string(selectedDevice.ProviderClass);
            data.dvaddoninstallstart = string(jsDduxData.Basecode);            
            data.dvaddoninstallsuccessful = jsDduxData.AddonInstallSuccess;

            ServiceLauncher = matlab.hwmgr.internal.ServiceLauncher();
            installerType = ServiceLauncher.getInstallerTypeForBaseCode(jsDduxData.Basecode);
            data.dvlaunchedaddonexplorer = installerType ~= "SSI";

            matlab.hwmgr.internal.HwmgrAppDduxBridge.logDeviceDetailDialog(data);
        end

        function logHardwareSearchAddHardwareDlg(searchData)
            data = struct;
            
            data.hardwaretype = "";
            data.hardwarevendor = "";
            data.addoninstallstart = "";
            data.hardwaresearched = string(searchData.SearchText);
            data.addoninstallsuccessful = false;
            data.launchedaddonexplorer = searchData.Trigger == "openAddOn";

            matlab.hwmgr.internal.HwmgrAppDduxBridge.logAddHardwareDialog(data);
        end
    end

    methods (Static, Hidden)

        function logAddHardwareDialog(data)
            dataId = matlab.ddux.internal.DataIdentification(matlab.hwmgr.internal.HwmgrAppDduxBridge.Product, ...
                matlab.hwmgr.internal.HwmgrAppDduxBridge.AppComponent, ...
                matlab.hwmgr.internal.HwmgrAppDduxBridge.AddHardwareDlgKey);

            matlab.ddux.internal.logData(dataId, ...
                "hardwaretype", data.hardwaretype, ...
                "hardwarevendor", data.hardwarevendor, ...
                "addoninstallstart", data.addoninstallstart, ...
                "hardwaresearched", data.hardwaresearched, ...
                "addoninstallsuccessful", data.addoninstallsuccessful, ...
                "launchedaddonexplorer", data.launchedaddonexplorer);
        end

        function logDeviceDetailDialog(data)
            dataId = matlab.ddux.internal.DataIdentification(matlab.hwmgr.internal.HwmgrAppDduxBridge.Product, ...
                matlab.hwmgr.internal.HwmgrAppDduxBridge.AppComponent, ...
                matlab.hwmgr.internal.HwmgrAppDduxBridge.DeviceDetailDlgKey);

            matlab.ddux.internal.logData(dataId, ...
                "dvfriendlyname", data.dvfriendlyname, ...
                "dvvendorid", data.dvvendorid, ...
                "dvisnonenumerable", data.dvisnonenumerable, ...
                "dvprovider", data.dvprovider, ...
                "dvaddoninstallstart", data.dvaddoninstallstart, ...
                "dvaddoninstallsuccessful", data.dvaddoninstallsuccessful, ...
                "dvlaunchedaddonexplorer", data.dvlaunchedaddonexplorer);

        end

    end

end