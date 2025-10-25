classdef DeviceHardwareSetupData < matlab.hwmgr.internal.data.DeviceLaunchableData
    %DEVICEHARDWARESETUPDATA Hardware Setup data specific to a Hardware Manager device

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        %DISPLAYNAME
        %   Dsplay name used as an identification for Hardware Setup
        DisplayName

        %LaunchMode
        %   Set by downstream team prior to using the hardware for the first time 
        LaunchMode matlab.hwmgr.internal.data.LaunchModeEnum

        %HardwareSetupStatus
        %   Set by downstream team during (or after) Hardware Setup
        %   workflow
        HardwareSetupStatus matlab.hwmgr.internal.data.HardwareSetupStatusEnum
        
        %WorkflowName
        %   Workflow name to launch, e.g., for Arduino Hardware setup, WorkflowName is 
        %   matlab.hwmgr.internal.hwsetup.register.ArduinoWorkflow
        WorkflowName

        %WorkflowArgs
        %   Arguments  to pass to the Workflow launcher
        WorkflowArgs
    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})

        function obj = DeviceHardwareSetupData(displayName, launchMode, hardwareSetupStatus, workflowName, identifierReference, nameValueArgs)
           arguments
                displayName (1, 1) string
                launchMode (1, 1) string
                hardwareSetupStatus (1, 1) string
                workflowName (1, 1) string 
                identifierReference (1, 1) string = ""
                nameValueArgs.SupportingAddOnBaseCodes (1, :) string = string.empty()
                nameValueArgs.SkipSupportingAddonInstallation = dictionary(string.empty, logical.empty)
                nameValueArgs.WorkflowArgs (1, :) string = string.empty() 
            end
            
            % Initialize common properties via the superclass constructor
             obj@matlab.hwmgr.internal.data.DeviceLaunchableData(identifierReference, ...
                                                                nameValueArgs.SupportingAddOnBaseCodes, ...
                                                                nameValueArgs.SkipSupportingAddonInstallation);
            obj.DisplayName = displayName;
            obj.LaunchMode = launchMode;
            obj.HardwareSetupStatus = hardwareSetupStatus;
            obj.WorkflowName = workflowName;
            obj.WorkflowArgs = nameValueArgs.WorkflowArgs; 
           
        end
    end
end