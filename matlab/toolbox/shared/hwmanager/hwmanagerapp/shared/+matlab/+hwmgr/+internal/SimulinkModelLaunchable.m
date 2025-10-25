
classdef SimulinkModelLaunchable < matlab.hwmgr.internal.IFeatureLaunchable
    %SimulinkModelLaunchable This class is responsible for launching Simulink Models.

    % Copyright 2024 The MathWorks, Inc.

    properties (Access = ?matlab.unittest.TestCase)
        HwmgrDevice
        ModelToOpen   % Simulink Model to open
        CommandArgs  % arguments to pass to open_system
    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = SimulinkModelLaunchable(launchableData, hwmgrDevice, varargin)

            obj.ModelToOpen = launchableData.ModelToOpen;
            obj.HwmgrDevice = hwmgrDevice;

            % Set the default CommandArgs from the launchable data
            obj.CommandArgs = launchableData.CommandArgs;

            % Retrieve device-specific launchable data
            deviceData = matlab.hwmgr.internal.IFeatureLaunchable.getDeviceLaunchableData(launchableData.Identifier, hwmgrDevice);

            % Use the device-sepecific version of CommandArgs if it exists
            if ~isempty(deviceData) && ~isempty(deviceData.CommandArgs)
                obj.CommandArgs = deviceData.CommandArgs;
            end
        end
    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.FeatureLauncher, ?matlab.unittest.TestCase})
        function launch(obj)
            open_system(obj.ModelToOpen, obj.CommandArgs{:});
        end
    end
end