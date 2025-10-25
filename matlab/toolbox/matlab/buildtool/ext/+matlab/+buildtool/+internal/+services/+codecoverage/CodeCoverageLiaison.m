classdef CodeCoverageLiaison < matlab.buildtool.internal.services.coverage.CoverageLiaison
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        SourceFiles (1,:) matlab.buildtool.io.FileCollection
    end

    methods
        function liaison = CodeCoverageLiaison(sourceType, sourceFiles, coverageSettings)
            arguments
                sourceType (1,1) matlab.buildtool.internal.tasks.CoverageSourceType
                sourceFiles (1,:) matlab.buildtool.io.FileCollection
                coverageSettings (1,:) matlab.buildtool.internal.tasks.codecoverage.CodeCoverageSettings
            end            
            liaison@matlab.buildtool.internal.services.coverage.CoverageLiaison(sourceType, coverageSettings);
            liaison.SourceFiles = sourceFiles;
        end
    end

end
