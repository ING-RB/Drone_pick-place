classdef AppletLaunchable < matlab.hwmgr.internal.IFeatureLaunchable
    % AppletLaunchable This class is responsible for launching Client Apps.
    %
    % Copyright 2024 The MathWorks, Inc.

    properties (Access = ?matlab.unittest.TestCase)
        AppletClass;
        PluginClass;
        HwmgrDevice;
        DduxEntryPointPrefix = ""; % Prefix for the entry point, used for dialog types
    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = AppletLaunchable(launchableData, selectedDevice, args)
            obj.AppletClass = string(launchableData.AppletClass);
            obj.PluginClass = launchableData.PluginClass;
            obj.DduxEntryPointPrefix = args.DialogType + "::";
            obj.HwmgrDevice =  selectedDevice;
        end
    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.FeatureLauncher, ?matlab.unittest.TestCase})
        function launch(obj)
            % Implements the launch process for the applet.

            % Set the soft load flag to true, since launching a client
            % app using a hard load will cause the Hardware Manager
            % devices to go out of sync with the client app
            doSoftLoad = true;

            matlab.hwmgr.internal.checkAndLaunchAppletForDevice(obj.AppletClass, obj.PluginClass, obj.HwmgrDevice, obj.DduxEntryPointPrefix, doSoftLoad);
        end
    end
end
