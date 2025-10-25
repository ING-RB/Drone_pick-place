function checkAndLaunchAppletForDevice(appletClass, pluginClass, device, entryPointPrefix, doSoftLoad)
% checkAndLaunchAppletForDevice(APPLETCLASS, PLUGINCLASS, DEVICE) - this
% utility function will ask the client app APPLETCLASS if it allows
% multiple instances. If allowed, it will launch a new instance of the
% client app for the given parameters. If not allowed, any existing client
% app will be brought to focus or a new instance will be launched if one
% isn't running already.

% Copyright 2021-2023 The MathWorks, Inc.

arguments
    appletClass
    pluginClass
    device = [];
    entryPointPrefix = "";
    doSoftLoad = false;
end

% Start measuring startup time
tStart = tic;

% Create temporary instance of the client app to ask if multiple instances
% are allowed
tempAppletInstance = feval(appletClass);
isMultiInstanceAllowed = tempAppletInstance.AllowMultipleInstances;

% Get all the framework instances
allInstances = matlab.hwmgr.internal.HardwareManagerFramework.getAllInstances();

context = matlab.hwmgr.internal.ClientAppContext(appletClass, pluginClass);

sameDevice = false;  % New instance device is equal to running instance device
isAppletRunning = false;
requestedAppletDeviceIndex = 1;

% Work backwards from the end of the list, find the instance that is
% running the requested applet
for i = numel(allInstances):-1:1
    if allInstances(i).Context == context

        isAppletRunning = true;

        hwmgr = allInstances(i);
        
        devList = hwmgr.getModuleByName('DeviceList');
        
        requestedAppletDeviceIndex = devList.getDeviceIndexFromList(devList.getFilteredDeviceList, device);
        runningAppletDeviceIndex = devList.getDeviceIndexFromList(devList.getFilteredDeviceList, devList.SelectedDevice);

        % if the requested Applet device already exists, we are done
        % searching
        if requestedAppletDeviceIndex == runningAppletDeviceIndex
            sameDevice = true;
            break;
        end
    end
end

%% Scenarios for handling a new instance where a running instance exists
%%  note: launchAppletForDevice and hwmgr.show() are mutually exclusive
    %|===================inputs=====================|=============actions===================== 
    %| case | isMultiInstanceAllowed | sameDevice   | launchAppletForDevice   | changeDevice |
    %|------+------------------------+--------------+-------------------------+--------------|
    %|  1   |             T          |       T      |          F              |       F      |
    %|______|________________________|______________|_________________________|______________|
    %|  2   |             T          |       F      |          T              |      N/A     |
    %|______|________________________|______________|_________________________|______________|
    %|  3   |             F          |       T      |          F              |       F      |
    %|______|________________________|______________|_________________________|______________|
    %|  4   |             F          |       F      |          F              |       T      |
    %|______|________________________|______________|_________________________|______________|
    %=========================================================================================

if isAppletRunning
    if isMultiInstanceAllowed && ~sameDevice
        % case 2
        matlab.hwmgr.internal.launchAppletForDevice(appletClass, pluginClass, device, doSoftLoad);
    else 
         % case 1,3,4 (set focus to the existing device applet)
        hwmgr.show();

        if ~sameDevice
            %case 4
            runningAppDevListPage = hwmgr.getModuleByName('RunningAppDeviceListPage');
            runningAppDevListPage.clientSelectDevice(struct('Uuid', requestedAppletDeviceIndex-1));
        end
    end
else
    matlab.hwmgr.internal.launchAppletForDevice(appletClass, pluginClass, device, doSoftLoad);
end

logUsage();

% ---------------------Nested Helper function------------------------------
    function logUsage()
        % Instrument the entry point and startup time
        dataStruct = struct();
        totalTimeElapsed = toc(tStart);
        dataStruct.startupTime = string(totalTimeElapsed*1e3) + "ms";

        if isstruct(appletClass)
            dataStruct.entryPoint = entryPointPrefix + string(appletClass.AppletName) + string(pluginClass);
        else
            dataStruct.entryPoint = entryPointPrefix + string(appletClass) + string(pluginClass);
        end


        usageLogger = matlab.hwmgr.internal.UsageLogger();

        try
            usageLogger.logEntryPointAndStartupTime(dataStruct);
        catch
            % Do nothing if we were unable to log usage data
        end
    end
end