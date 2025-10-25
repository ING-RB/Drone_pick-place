function assertFeatureFlagEnabled(FeatureFlagName, args)
%

%   Copyright 2024 The MathWorks, Inc.

    arguments
        FeatureFlagName               (1, 1) string {mustBeNonmissing}
        args.FeatureFlagDescription   (1, 1) string = missing;
    end

    if ismissing(args.FeatureFlagDescription)
        args.FeatureFlagDescription = FeatureFlagName;
    end

    if matlab.internal.feature(FeatureFlagName) == 0
        error(message("MATLAB:io:common:validation:FeatureNotEnabled", args.FeatureFlagDescription));
    end
end
