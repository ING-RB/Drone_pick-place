classdef ExampleLaunchable < matlab.hwmgr.internal.IFeatureLaunchable
    %ExampleLaunchable This class is responsible for launching examples.

    % Copyright 2024 The MathWorks, Inc.

    properties (Access = ?matlab.unittest.TestCase)
        ExampleName   % The example to be launched
        CommandArgs
        HwmgrDevice
    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = ExampleLaunchable(launchableData, hwmgrDevice, varargin)
            obj.ExampleName = launchableData.ExampleName;
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
            openExample(obj.ExampleName, obj.CommandArgs{:});
        end
    end
end