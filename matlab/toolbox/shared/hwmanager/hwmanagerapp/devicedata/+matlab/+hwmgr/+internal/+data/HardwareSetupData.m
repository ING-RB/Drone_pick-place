classdef HardwareSetupData < matlab.hwmgr.internal.data.LaunchableData
    %HARDWARESETUPDATA Hardware Setup data required by Hardware Manager app

    % Copyright 2023-2024 The MathWorks, Inc.

    properties %(SetAccess = private)
        %WorkflowName
        %   Workflow name to launch
        WorkflowName

        %WorkflowArgs
        %   Arguments  to pass to the Workflow launcher
        WorkflowArgs

    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = HardwareSetupData(displayName, description, iconID, learnMoreLink, workflowName, identifier, nameValueArgs)
            arguments
                displayName (1, 1) string
                description (1, 1) string  
                iconID (1, 1) string
                learnMoreLink (1, 1)
                workflowName (1, 1) string
                identifier (1, 1) string = ""
                nameValueArgs.?matlab.hwmgr.internal.data.LaunchableData
                nameValueArgs.WorkflowArgs (1, :) string = string.empty() 
            end

            % Remove the NV pair for WorkflowArgs since it belongs to
            % HardwareSetupData class only
            namedArgsCell  = namedargs2cell(rmfield(nameValueArgs,'WorkflowArgs'));

            % Initialize common properties via the superclass constructor
            obj@matlab.hwmgr.internal.data.LaunchableData(identifier, ...
                                                          matlab.hwmgr.internal.data.FeatureCategory.HardwareSetup, ...
                                                          displayName, ...
                                                          description, ...
                                                          iconID, ...
                                                          learnMoreLink, ...
                                                          message('hwmanagerapp:hwmgrstartpage:SetupHardware').getString(), ...
                                                          namedArgsCell{:});

            % Initialize this class properties
            obj.WorkflowName = workflowName;
            obj.WorkflowArgs = nameValueArgs.WorkflowArgs;
        end
    end
end