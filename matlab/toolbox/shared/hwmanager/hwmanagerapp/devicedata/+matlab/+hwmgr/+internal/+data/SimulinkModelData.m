classdef SimulinkModelData < matlab.hwmgr.internal.data.LaunchableData
    %SIMULINKMODELDATA required by Hardware Manager app

    % Copyright 2024 The MathWorks, Inc.

    properties %(SetAccess = private)
        
        %ModelToOpen
        %  Simulink model, library, subsystem, or block to open
        ModelToOpen

        %CommandArgs
        %   Arguments to pass to open_system command
        CommandArgs

    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = SimulinkModelData(displayName, description, iconID, learnMoreLink, modelToOpen, identifier, nameValueArgs)
            arguments
                displayName (1, 1) string
                description (1, 1) string
                iconID (1, 1) string
                learnMoreLink (1, 1)
                modelToOpen (1, 1) string
                identifier (1, 1) string
                nameValueArgs.?matlab.hwmgr.internal.data.LaunchableData
                nameValueArgs.CommandArgs (1, :) string = string.empty()
            end

            % Remove the NV pair for CommandArgs since it belongs to this class only
            namedArgsCell  = namedargs2cell(rmfield(nameValueArgs,'CommandArgs'));

            % Initialize common properties via the superclass constructor
            obj@matlab.hwmgr.internal.data.LaunchableData(identifier, ...
                                                          matlab.hwmgr.internal.data.FeatureCategory.SimulinkModel, ...
                                                          displayName, ...
                                                          description, ...
                                                          iconID, ...
                                                          learnMoreLink, ...
                                                          message('hwmanagerapp:hwmgrstartpage:LaunchSimulinkModel').getString(), ...
                                                          namedArgsCell{:});

            % Initialize this class properties
            obj.ModelToOpen = modelToOpen;
            obj.CommandArgs = nameValueArgs.CommandArgs;
        end
    end
end