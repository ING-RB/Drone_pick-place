classdef CodeCoverageService < matlab.buildtool.internal.services.coverage.CoverageService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        SourceType = matlab.buildtool.internal.tasks.CoverageSourceType.Code
    end

    methods
        function customizeTestRunner(~, liaison, runner)
            import matlab.buildtool.internal.tasks.codeCoverageResultsServices;
            import matlab.buildtool.internal.services.codecoverage.CodeCoverageResultsLiaison;
            import matlab.unittest.plugins.CodeCoveragePlugin;
            import matlab.unittest.internal.coverage.supportedCoverageSourceExtensions;

            if isempty(liaison.CoverageSettings)
                return
            end

            sourceFiles = liaison.SourceFiles.absolutePaths();
            if isempty(sourceFiles)
                error(message("MATLAB:buildtool:TestTask:CoverageSourcesMustBeNonEmpty"));
            end

            % Select valid MATLAB source files for coverage reporting
            covSourceFolderMask = isfolder(sourceFiles);
            validCovSourceFileMask = endsWith(sourceFiles, supportedCoverageSourceExtensions);
            isValidCoverageSource = covSourceFolderMask | validCovSourceFileMask;

            selectedSourceFiles = sourceFiles(isValidCoverageSource);
            if isempty(selectedSourceFiles)
                error(message("MATLAB:buildtool:TestTask:CoverageSourcesMustBeNonEmpty"));
            end

            liaison.CoverageFormats = [liaison.CoverageSettings.ResultFormats];
            runner.addPlugin(CodeCoveragePlugin.forSource(...
                selectedSourceFiles, ...
                MetricLevel=unique([liaison.CoverageSettings.MetricLevel]), ...
                Producing=liaison.CoverageFormats));
        end
    end
end