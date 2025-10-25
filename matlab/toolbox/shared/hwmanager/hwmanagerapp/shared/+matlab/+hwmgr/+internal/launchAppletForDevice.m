function launchAppletForDevice(appletClass, pluginClass, deviceToSelect, doSoftLoad)
% launchAppletForDevice - This function is the underlying implementation of
% how to launch a client app directly. This function should not be called
% directly.
% 
% Use matlab.hwmgr.internal.launchApplet(appletClass, pluginClass) or
% matlab.hwmgr.internal.checkAndLaunchAppletForDevice(appletClass,
% pluginClass, deviceToSelect) to launch a client app.

% Copyright 2021-2024 The MathWorks, Inc.
arguments
    % appletClass - the class of the client app being launched
    appletClass
    % pluginClass - the class of the plugin that owns the appletClass
    pluginClass
    % deviceToSelect - The device to select on launching the client app.
    deviceToSelect = [];
    % forceSoftLoad
    doSoftLoad = false;
end

% Input validation and conversion, appletClass input can be class name or a applet struct with two
% fields: AppletName and Constructor
appletStruct = matlab.hwmgr.internal.util.convertToAppletStruct(appletClass);
if numel(appletStruct) ~= 1
    error('The applet class %s provided has more than one possible constructor. Please provide an applet with the specific constructor to use.', appletClass);
end


context = matlab.hwmgr.internal.ClientAppContext(appletClass, pluginClass);

try
    hwmgr = matlab.hwmgr.internal.HardwareManagerFramework(context);
catch ex
    throwAsCaller(ex);
end

% Suspend the close until the window is loaded and initialized
suspendClose(hwmgr, true);
oc = onCleanup(@()suspendClose(hwmgr, false));

% Get the applet name from the applet object.
% Construct the client app object here for two main reasons - 
%
% 1. If the applet object constructor fails then we don't even show the
% window.
%
% 2. Get the name of the client app so we can update the window title with
% it.
%
% NOTE - For now, this is specifically needed by the udpExplorer app (and
% possibly more toolbox apps in the future).
try
    appletObj = eval(appletStruct.AppletName);
catch ex
    throwAsCaller(ex);
end

% Show the UI
hwmgr.show();

appletToRunTitle = appletObj.getDisplayName();

% Set the title of the window to the applet name
hwmgr.setTitle(appletToRunTitle);

% Load the specified plugin
if doSoftLoad 
    hwmgr.softLoadPlugins(pluginClass);
else
    hwmgr.hardLoadPlugins(pluginClass);
end

% Filter devices in the view by applet support
hwmgr.setDeviceListViewFilter('Applet', appletStruct);

% Configure the framework to launch the selected applet on device change
hwmgr.setLaunchAppletOnDeviceChange(true);

% Skip running the plugins again when refreshing Hwmgr, as they were loaded
% just above unless the pluginClass was set to "None" which just clears all
% plugins
if pluginClass == "NONE"
    hwmgr.getMainController().refreshHwmgr(doSoftLoad);
else
    % Skips loading the plugins again
    hwmgr.getMainController().refreshHwmgr(doSoftLoad, false);
end

% Need to find a match and select a device only if a match is found
deviceList = hwmgr.getModuleByName("DeviceList").getFilteredDeviceList();

% Only when the selected device is not empty, then we try to launch the app
% for the selected device
if ~isempty(deviceToSelect) && any(arrayfun(@(x)isequal(x, deviceToSelect.UUID), [deviceList.UUID]))
    mc = hwmgr.getMainController();
    % checks if device needs to be sent to the configure page
    if ~isempty(deviceToSelect.DeviceEnumerableConfigData)
        for j = 1:length(deviceToSelect.DeviceEnumerableConfigData)
            if deviceToSelect.DeviceEnumerableConfigData(j).AppletClass == appletClass && deviceToSelect.DeviceEnumerableConfigData(j).NeedsConfiguration
                    mc.logAndSet("UserConfigureDeviceStartPage", {find(arrayfun(@(x)isequal(x, deviceToSelect.UUID), [deviceList.UUID]),1); appletClass})
                    return
            end
        end
    end
    mc.logAndSet("ShowDeviceListToolstripLayout", true);
    mc.CurrentPage = "RunningAppPage";
    mc.logAndSet("SetCollapseToolstrip", false);
    mc.logAndSet("SelectDeviceByObject", deviceToSelect);
end
end

function suspendClose(hwmgr, flag)
window = hwmgr.DisplayManager.Window;
if isvalid(window)
    window.SuspendClose = flag;
end
end
