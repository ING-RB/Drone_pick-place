classdef DeviceSimulinkModelData < matlab.hwmgr.internal.data.DeviceLaunchableData
    %DEVICESIMULINKMODELDATA Simulink Model data specific to a Hardware Manager device

    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess = private)
        %CommandArgs
        %   Arguments to pass to the Simulink Model launcher
        CommandArgs
    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})

        function obj = DeviceSimulinkModelData(identifierReference, nameValueArgs)
           arguments
                identifierReference (1, 1) string
                nameValueArgs.SupportingAddOnBaseCodes (1, :) string = string.empty()
                nameValueArgs.SkipSupportingAddonInstallation = dictionary(string.empty, logical.empty)
                nameValueArgs.CommandArgs (1, :) string = string.empty()
            end

            % Initialize common properties via the superclass constructor
            obj@matlab.hwmgr.internal.data.DeviceLaunchableData(identifierReference, ...
                                                                nameValueArgs.SupportingAddOnBaseCodes, ...
                                                                nameValueArgs.SkipSupportingAddonInstallation);
            obj.CommandArgs = nameValueArgs.CommandArgs;

        end
    end
end