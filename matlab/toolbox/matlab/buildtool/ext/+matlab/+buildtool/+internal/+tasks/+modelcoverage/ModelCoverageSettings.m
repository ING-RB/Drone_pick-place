classdef ModelCoverageSettings < matlab.buildtool.internal.tasks.CoverageSettings
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        Metrics (1,:) string
        IncludeReferencedModels (1,1) logical = true
    end

    properties (Dependent, SetAccess=private)
        CoverageMetrics sltest.plugins.coverage.CoverageMetrics {mustBeScalarOrEmpty}
    end

    properties (Dependent, SetAccess=private)
        ResultFormats
    end

    properties (Constant)
        DefaultFileExtension = matlab.buildtool.internal.services.modelcoverage.HTMLCoverageReportService.Extension
    end
    
    methods
        function s = ModelCoverageSettings(results, options)
            arguments
                results (1,:) {mustBeFileOrCoverageFormat(results, "Model")} = matlab.buildtool.io.File.empty() %#ok<FVVCON>
                options.Metrics (1,:) string = string.empty(1,0)
                options.IncludeReferencedModels (1,1) logical = true
            end
            s@matlab.buildtool.internal.tasks.CoverageSettings(results);
            s.Metrics = options.Metrics;
            s.IncludeReferencedModels = options.IncludeReferencedModels;
        end

        function covMetricsObj = get.CoverageMetrics(s)
            if isempty(s.Metrics)
                % Creating an instance first can help with license validation
                covMetricsObj = sltest.plugins.coverage.CoverageMetrics();
                covMetricsObj = covMetricsObj.empty();
            else
                metricsList = interleaveNameValuePairs(s.Metrics);
                covMetricsObj = sltest.plugins.coverage.CoverageMetrics(metricsList{:});
            end
        end

        function formats = get.ResultFormats(s)
            arguments (Output)
                formats (1,:)
            end

            import matlab.buildtool.internal.tasks.modelCoverageResultsServices;
            import matlab.buildtool.internal.services.modelcoverage.ModelCoverageResultsLiaison;

            results = s.Results;  
            if isa(results, "matlab.unittest.plugins.codecoverage.CoverageFormat")
                formats = results;
                return;
            end

            services = modelCoverageResultsServices();
            resultFiles = s.ResultFiles;
            formats = matlab.unittest.plugins.codecoverage.CoverageFormat.empty();
            for file = resultFiles
                liaison = ModelCoverageResultsLiaison(file.absolutePaths());
                fulfill(services, liaison);
                supportingService = services.findServiceThatSupports(liaison.ResultPath, liaison.ResultFormat);
                if ~isempty(supportingService)
                    formats = [formats; supportingService.provideCoverageFormat(liaison)]; %#ok<AGROW>
                end
            end
        end
    end
end

function parameters = interleaveNameValuePairs(names)
names = cellstr(names);
parameters = cell(1, 2*numel(names));
parameters(1:2:end) = names;
parameters(2:2:end) = {true};
end

function mustBeFileOrCoverageFormat(varargin)
matlab.buildtool.internal.tasks.mustBeFileOrCoverageFormat(varargin{:});
end