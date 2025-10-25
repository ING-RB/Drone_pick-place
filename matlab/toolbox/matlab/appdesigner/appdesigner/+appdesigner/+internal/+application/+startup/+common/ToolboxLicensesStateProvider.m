classdef ToolboxLicensesStateProvider < appdesigner.internal.application.startup.StartupStateProvider
    % ToolboxLicensesStateProvider

    % Copyright 2023 The MathWorks, Inc.

    methods
        function state = getState(obj, startupArguments)
            state.ToolboxLicenses = struct;

            % Toolbox license check
            state.ToolboxLicenses.hasAerospaceToolbox = appdesigner.internal.license.LicenseChecker.isProductAvailable("aerospace_toolbox");
            state.ToolboxLicenses.hasSlrtToolbox = appdesigner.internal.license.LicenseChecker.isProductAvailable("xpc_target");
            state.ToolboxLicenses.hasSimulinkToolbox = appdesigner.internal.license.LicenseChecker.isProductAvailable("simulink");
			state.ToolboxLicenses.hasAudioSystemToolbox = appdesigner.internal.license.LicenseChecker.isProductAvailable("audio_system_toolbox");
            state.ToolboxLicenses.hasInstrumentControlToolbox = appdesigner.internal.license.LicenseChecker.isProductAvailable("Instr_Control_Toolbox");
            state.ToolboxLicenses.has5GToolbox = appdesigner.internal.license.LicenseChecker.isProductAvailable("matlab_5g_toolbox");
            state.ToolboxLicenses.hasImageAcqToolbox = appdesigner.internal.license.LicenseChecker.isProductAvailable('Image_Acquisition_Toolbox');
            state.ToolboxLicenses.hasDataAcqToolbox = appdesigner.internal.license.LicenseChecker.isProductAvailable('Data_Acq_Toolbox');
        end
    end
end
