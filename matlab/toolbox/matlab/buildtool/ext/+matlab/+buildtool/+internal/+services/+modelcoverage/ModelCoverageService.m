classdef ModelCoverageService < matlab.buildtool.internal.services.coverage.CoverageService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        SourceType = matlab.buildtool.internal.tasks.CoverageSourceType.Model
    end

    methods
        function customizeTestRunner(~, liaison, runner)
            if isempty(liaison.CoverageSettings)
                return
            end

            for coverageSetting = liaison.CoverageSettings
                coverageResultFormats = coverageSetting.ResultFormats;
                for i = 1:numel(coverageResultFormats)
                    addModelCoveragePlugin(runner, ...
                        coverageResultFormats(i), ...
                        IncludeReferencedModels=coverageSetting.IncludeReferencedModels, ...
                        CoverageMetrics=coverageSetting.CoverageMetrics);
                end
            end
            liaison.CoverageFormats = [liaison.CoverageSettings.ResultFormats];
        end
    end
end

function addModelCoveragePlugin(runner, coverageFormat, options)

arguments
    runner (1,1) matlab.unittest.TestRunner
    coverageFormat (1,1) matlab.unittest.plugins.codecoverage.CoverageFormat
    options.IncludeReferencedModels (1,1) logical = true
    options.CoverageMetrics sltest.plugins.coverage.CoverageMetrics {mustBeScalarOrEmpty}
end

import matlab.buildtool.internal.tasks.constructModelCoveragePlugin

args.Producing = coverageFormat;
args.RecordModelReferenceCoverage = options.IncludeReferencedModels;
if ~isempty(options.CoverageMetrics)
    args.Collecting = options.CoverageMetrics;
end
args = namedargs2cell(args);
plugin = constructModelCoveragePlugin(args{:});
runner.addPlugin(plugin);
end