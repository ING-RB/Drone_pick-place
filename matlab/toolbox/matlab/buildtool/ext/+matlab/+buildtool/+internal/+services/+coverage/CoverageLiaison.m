classdef CoverageLiaison < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        SourceType (1,1) matlab.buildtool.internal.tasks.CoverageSourceType
        CoverageSettings (1,:)
    end

    properties
        CoverageFormats (1,:) matlab.unittest.plugins.codecoverage.CoverageFormat
    end

    methods
        function liaison = CoverageLiaison(sourceType, coverageSettings)
            arguments
                sourceType (1,1) matlab.buildtool.internal.tasks.CoverageSourceType
                coverageSettings (1,:) matlab.buildtool.internal.tasks.CoverageSettings
            end
            liaison.SourceType = sourceType;
            liaison.CoverageSettings = coverageSettings;
        end
    end

end
