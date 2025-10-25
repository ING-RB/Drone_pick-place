classdef MLAPPSimulinkAppValidator < appdesigner.internal.serialization.validator.MLAPPValidator
    % MLAPPSimulinkAppValidator validator for Simulink apps
    % Check if the Simulink apps are supported or not

    % Copyright 2023 The MathWorks, Inc.

    methods
        function validateAppData(~, ~, appData)
            if (isfield(appData, 'simulink'))
                isProductAvailable = appdesigner.internal.license.LicenseChecker.isProductAvailable("simulink");

                if ~isProductAvailable
                    error(message('MATLAB:appdesigner:appdesigner:SimulinkAppLoadFailedDueToMissingLicense'));
                end
            end
        end
    end
end
