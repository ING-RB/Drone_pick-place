classdef MLAPPReleaseValidator < appdesigner.internal.serialization.validator.MLAPPValidator
    % MLAPPAppTypeValidator Validator for minimum supported MATLAB release
    % of the MLAPP file

    % Copyright 2018-2020 The MathWorks, Inc.

    methods
        function validateMetaData(~, metadata)
            import appdesigner.internal.serialization.app.AppVersion;

            errorMsg = message('MATLAB:appdesigner:appdesigner:IncompatibleAppVersion', metadata.MinimumSupportedMATLABRelease);

            % check if this app is a supported app to open based on its
            % MinimumSupportedMATLABRelease
            import appdesigner.internal.serialization.util.ReleaseUtil;
            if (~ReleaseUtil.isSupportedRelease(metadata.MinimumSupportedMATLABRelease))
                error(errorMsg);
            end

            % check if the MLAPP version is '1' or '2'
            if (~strcmp(metadata.MLAPPVersion, AppVersion.MLAPPVersionOne) && ...
                ~strcmp(metadata.MLAPPVersion, AppVersion.MLAPPVersionTwo))
                error(errorMsg);
            end
        end
    end
end

