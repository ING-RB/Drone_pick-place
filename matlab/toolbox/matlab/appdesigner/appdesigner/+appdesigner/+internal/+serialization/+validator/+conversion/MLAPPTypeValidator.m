classdef MLAPPTypeValidator < appdesigner.internal.serialization.validator.MLAPPValidator
    % MLAPPTypeValidator: App conversion validator for responsive
    % app which should not be allowed to covert to 17b and prior releases.

    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function validateAppData(~, metadata, appData)

            errorMsg = message('MATLAB:appdesigner:appdesigner:CovertAppFailedIncompatibleAppVersion', ...
                appData.DestinationRelease, metadata.MinimumSupportedMATLABRelease);

            if strcmp(appdesigner.internal.serialization.app.AppTypes.ResponsiveApp, metadata.AppType)
                % Since Responsive App is supported from R2019a, App
                % Designer cannot convert it to 17b or prior releases.
                error(errorMsg);
            end
        end
    end
end

