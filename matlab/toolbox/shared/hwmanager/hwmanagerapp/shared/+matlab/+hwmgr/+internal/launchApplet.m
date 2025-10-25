function launchApplet(appletClass, pluginClass)
% MATLAB.HWMGR.INTERNAL.LAUNCHAPPLET - An internal utility function that
%   can be used to launch hardware manager initialized to run an applet
%
%   The APPLETCLASS is a string or character array of the applet class
%   name
%
%   The PLUGINCLASS is a string or character array of the plugin
%   class that is to be loaded for getting device and applet information
%
%   Usage:
%
%   % Launch the DAQ Analog Input Applet using the DAQ Plugin
%   matlab.hwmgr.internal.launchApplet('daqaiapplet.applet.DAQAIApplet',...
%                                      'matlab.hwmgr.plugins.DAQPlugin');

% Copyright 2017-2022 The MathWorks, Inc.

% Start measuring startup time
tStart = tic;

validateattributes(pluginClass, {'char', 'string'}, {'nonempty', 'scalartext'}, 'matlab.hwmgr.internal.launchApplet', 'PLUGINCLASS');

% Get all the framework instances
allInstances = matlab.hwmgr.internal.HardwareManagerFramework.getAllInstances();

% Work backwards from the end of the list, find the instance that is
% running the requested applet
context = matlab.hwmgr.internal.ClientAppContext(appletClass, pluginClass);

for i = numel(allInstances):-1:1
    % If we found an instance of the framework for the requested applet,
    % use that
    if allInstances(i).Context == context
        hwmgr = allInstances(i);
        % Bring to focus
        hwmgr.show();
        return;
    end
end

try
    matlab.hwmgr.internal.launchAppletForDevice(appletClass, pluginClass);
catch ex
    throwAsCaller(ex);
end

% Instrument the entry point and startup time
dataStruct = struct();
totalTimeElapsed = toc(tStart);
dataStruct.startupTime = string(totalTimeElapsed*1e3) + "ms";

if isstruct(appletClass)
    dataStruct.entryPoint = string(appletClass.AppletName) + string(pluginClass);
else
    dataStruct.entryPoint = string(appletClass) + string(pluginClass);
end

usageLogger = matlab.hwmgr.internal.UsageLogger();

try
    usageLogger.logEntryPointAndStartupTime(dataStruct);
catch
    % Do nothing if we were unable to log usage data
end

end
