classdef MLAPPTypeValidator < appdesigner.internal.serialization.validator.MLAPPValidator
    % MLAPPTypeValidator validator for mlapp AppType
    % Check if the AppType is supported by the current App Designer or
    % not

    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function validateMetaData(~, metadata)
            import appdesigner.internal.serialization.app.AppTypes;

            if ~strcmp(AppTypes.StandardApp, metadata.AppType) && ...
                ~strcmp(AppTypes.ResponsiveApp, metadata.AppType) && ...
                ~strcmp(AppTypes.UserComponentApp, metadata.AppType)
                error(message('MATLAB:appdesigner:appdesigner:IncompatibleAppVersion', metadata.MinimumSupportedMATLABRelease));
            end
        end
    end
end
