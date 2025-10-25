classdef CodeCoverageSettings < matlab.buildtool.internal.tasks.CoverageSettings
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        MetricLevel (1,1) string {mustBeMember(MetricLevel, ["statement" "condition" "decision" "mcdc"])} = "statement"
    end

    properties (Dependent, SetAccess=private)
        ResultFormats
    end

    properties (Constant)
        DefaultFileExtension = matlab.buildtool.internal.services.codecoverage.CoverageResultService.Extension
    end

    methods
        function s = CodeCoverageSettings(results, options)
            arguments
                results (1,:) {mustBeFileOrCoverageFormat(results, "Code")} = matlab.buildtool.io.File.empty()
                options.MetricLevel (1,1) string {mustBeMember(options.MetricLevel, ["statement" "condition" "decision" "mcdc"])} = "statement"
            end
            s@matlab.buildtool.internal.tasks.CoverageSettings(results);
            s.MetricLevel = options.MetricLevel;
        end

        function formats = get.ResultFormats(s)
            arguments (Output)
                formats (1,:)
            end
            
            import matlab.buildtool.internal.tasks.codeCoverageResultsServices;
            import matlab.buildtool.internal.services.codecoverage.CodeCoverageResultsLiaison;

            results = s.Results;            
            if isa(results, "matlab.unittest.plugins.codecoverage.CoverageFormat")
                formats = results;
                return;
            end

            services = codeCoverageResultsServices();
            resultFiles = s.ResultFiles;
            formats = matlab.unittest.plugins.codecoverage.CoverageFormat.empty();
            for file = resultFiles
                liaison = CodeCoverageResultsLiaison(file.absolutePaths());
                fulfill(services, liaison);
                supportingService = services.findServiceThatSupports(liaison.ResultPath, liaison.ResultFormat);
                if ~isempty(supportingService)
                    formats = [formats; supportingService.provideCoverageFormat(liaison)]; %#ok<AGROW>
                end
            end
        end
    end
end

function mustBeFileOrCoverageFormat(varargin)
matlab.buildtool.internal.tasks.mustBeFileOrCoverageFormat(varargin{:});
end