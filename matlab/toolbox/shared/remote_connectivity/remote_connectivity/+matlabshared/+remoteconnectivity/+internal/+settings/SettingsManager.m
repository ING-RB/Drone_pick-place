classdef SettingsManager < matlab.settings.internal.FactorySettingsDefinition
    %SETTINGSMANAGER Define and access MATLAB Settings for Remote Connectivity.

    % Copyright 2023 The MathWorks, Inc.
    
    methods(Static)
        %% FactorySettingsDefinition impl
        function createTree(additional)
            % Add setting to indicate whether or not to show warning before
            % the Action Framework browser popup for HW Connector is shown.
            additional.addSetting("BrowserPopupWarningEnabled",...
                "FactoryValue", true,...
                "ValidationFcn", @matlab.settings.mustBeLogicalScalar,...
                "Hidden", true);
        end

        function up = createUpgraders()
            % No upgrading to do.
            up = [];
        end
    end

    methods(Access = public)
        %% Access settings
        function value = getBrowserPopupWarningEnabled(~)
            s = settings;
            value = s.remoteconnectivity.BrowserPopupWarningEnabled.ActiveValue;
        end

        function setBrowserPopupWarningEnabled(~, value)
            s = settings;
            s.remoteconnectivity.BrowserPopupWarningEnabled.PersonalValue = value;
        end
    end
end

