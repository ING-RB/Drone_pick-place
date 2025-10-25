classdef HardwareSetupLaunchable < matlab.hwmgr.internal.IFeatureLaunchable
    %HardwareSetupLaunchable This class is responsible for launching Hardware Setup Apps.

    % Copyright 2024 The MathWorks, Inc.

    properties (Access = ?matlab.unittest.TestCase)
        %WorkflowName
        %   Workflow name to launch
        WorkflowName

        %WorkflowArgs
        %   Arguments  to pass to the Workflow launcher
        WorkflowArgs

        HwmgrDevice

    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = HardwareSetupLaunchable(launchableData, hwmgrDevice, ~)

            obj.WorkflowName = launchableData.WorkflowName;
            obj.HwmgrDevice = hwmgrDevice;

            % Set the default workflow arguments from the launchable data
            obj.WorkflowArgs = launchableData.WorkflowArgs;

            % Retrieve device-specific launchable data
            deviceData = matlab.hwmgr.internal.IFeatureLaunchable.getDeviceLaunchableData(launchableData.Identifier, hwmgrDevice);

            % Use the device-sepecific version of workflow arguments if it exists
            if ~isempty(deviceData) && ~isempty(deviceData.WorkflowArgs)
                obj.WorkflowArgs = deviceData.WorkflowArgs;
            end
        end
    end

    methods (Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.FeatureLauncher, ?matlab.unittest.TestCase})
        function launch(obj)
            % Instantiate the workflow object
            workflowConstructor  = str2func(obj.WorkflowName);

            if isempty(obj.WorkflowArgs)
                hardwareSetupWorkFlow = workflowConstructor();
            else
                hardwareSetupWorkFlow = workflowConstructor (obj.WorkflowArgs{:});
            end

            hardwareSetupWorkFlow.launch();

        end
    end
end