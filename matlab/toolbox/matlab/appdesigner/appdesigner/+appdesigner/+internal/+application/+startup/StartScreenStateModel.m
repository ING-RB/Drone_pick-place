classdef  StartScreenStateModel < handle
    % Represents the state required for start screen, which is
    % EnvironmentStateProvider

    % Copyright 2021-2023 The MathWorks, Inc.

    properties
        % the state required for start screen
        State struct = struct();
    end

    methods
        function initialize(obj, startupArguments)
            % Populates startscreen state

            provider = appdesigner.internal.application.startup.common.EnvironmentStateProvider;
            licenseProvider = appdesigner.internal.application.startup.common.ToolboxLicensesStateProvider;
            % Gets its state
            providersState = provider.getState(startupArguments);
            licenseProvidersState = licenseProvider.getState(startupArguments);

            state = struct;
            % Take this providers state and merge it into the overall
            % state
            providerFieldNames = fieldnames(providersState);
            for jdx = 1:length(providerFieldNames)
                state.(providerFieldNames{jdx}) = providersState.(providerFieldNames{jdx});
            end

            licenseProviderFieldNames = fieldnames(licenseProvidersState);
            for idx = 1:length(licenseProviderFieldNames)
                state.(licenseProviderFieldNames{idx}) = licenseProvidersState.(licenseProviderFieldNames{idx});
            end

            % Store for future access
            obj.State = state;
        end
    end
end
