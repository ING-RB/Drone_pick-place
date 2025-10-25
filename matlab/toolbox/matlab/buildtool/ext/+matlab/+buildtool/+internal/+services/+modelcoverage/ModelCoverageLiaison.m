classdef ModelCoverageLiaison < matlab.buildtool.internal.services.coverage.CoverageLiaison
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    methods
        function liaison = ModelCoverageLiaison(sourceType, coverageSettings)
            arguments
                sourceType (1,1) matlab.buildtool.internal.tasks.CoverageSourceType
                coverageSettings (1,:) matlab.buildtool.internal.tasks.modelcoverage.ModelCoverageSettings
            end
            liaison@matlab.buildtool.internal.services.coverage.CoverageLiaison(sourceType, coverageSettings);
        end
    end

end
