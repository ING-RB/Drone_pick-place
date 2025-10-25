function [hwmgr, wasShowing] = launchHardwareManager(varargin)
% An internal utility function to launch the hardware manager application.
% 
% Output arguments:
% 
%   hwmgr - handle to the Hardware Manager framework object
%   wasShowing - a boolean flag to indicate whether the window was already
%                showing and hence was just brought into focus
% Usage:
%   % Launch hardware manager, and load all plugins and devices
%
%   matlab.hwmgr.internal.launchHardwareManager();
%
%   % Launch hardware manager and load the demo plugin only and its devices
%
%   matlab.hwmgr.internal.launchHardwareManager('matlab.hwmgr.plugins.DemoPlugin');

% Copyright 2018-2021 The MathWorks, Inc.

% Check if one Hardware Manager is already open
hwmgr = [];
allInstances = matlab.hwmgr.internal.HardwareManagerFramework.getAllInstances();

for i = 1:length(allInstances)
    if isa(allInstances(i).Context, 'matlab.hwmgr.internal.HwmgrAppContext')
        hwmgr = allInstances(i);
        break;
    end
end

if isempty(hwmgr)
    p = inputParser;
    p.addOptional('PluginName', 'ALL', @(x)ischar(x) || iscellstr(x)); %
    [varargin{:}] = convertStringsToChars(varargin{:});
    p.parse(varargin{:});

    context = matlab.hwmgr.internal.HwmgrAppContext(p.Results.PluginName);

    % Get the hardware manager framework
    hwmgr = matlab.hwmgr.internal.HardwareManagerFramework(context);
end

if nargout == 1
    varargout{1} = hwmgr;
end

wasShowing = hwmgr.isShowing();

% Display the UI
suspendClose(hwmgr, true);
oc = onCleanup(@()suspendClose(hwmgr, false));
hwmgr.show();

if wasShowing
    return;
end

pluginsToLoad = p.Results.PluginName;
pluginsToLoad = cellstr(pluginsToLoad);

% If specific plugin names were given, set the plugin loader's operation
% mode to only use these plugins on refresh
if numel(pluginsToLoad) == 1 && pluginsToLoad ~= "ALL"
    pluginLoader = hwmgr.getModuleByName('PluginLoader');
    pluginLoader.SearchForNewPlugins = false;
end

% Load the plugins
hwmgr.softLoadPlugins(pluginsToLoad);

% Refresh the device list
doSoftLoad = true;
hwmgr.getMainController().refreshHwmgr(doSoftLoad);
hwmgr.getMainController().removeHwmgrBusy();
end

function suspendClose(hwmgr, flag)
window = hwmgr.DisplayManager.Window;
window.SuspendClose = flag;
end
