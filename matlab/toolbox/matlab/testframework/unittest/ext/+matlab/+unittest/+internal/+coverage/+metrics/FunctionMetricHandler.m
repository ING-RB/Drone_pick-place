classdef FunctionMetricHandler < matlab.unittest.internal.coverage.metrics.MetricHandler
    %
    
    %  Copyright 2021-2023 The MathWorks, Inc.
    properties (Constant)
        MetricNameUsedByCollector = "function"
        MetricName = "function"
    end

    methods
        function metric = getMetricInstance(~,covData)
            metric  = matlab.unittest.internal.coverage.metrics.FunctionMetric(covData);
        end

        function formatter = getFormatter(~)
            formatter = matlab.unittest.internal.coverage.FunctionCoverageReportFormatter;
        end

        function combinedStaticData = combineStaticAndRuntimeData(~,staticDataForMetric, runtimeData)
            runtimeDataForMetric = runtimeData([staticDataForMetric{:,2}]+1); % indices in static data are zero-based
            combinedStaticData = [staticDataForMetric(:,1), num2cell(runtimeDataForMetric),staticDataForMetric(:,2:end)];
        end

        function combinedStaticData = uniquifyStaticData(~, staticDataForMetric, runtimeData)
            import matlab.unittest.internal.coverage.metrics.uniquifyStaticData
            combinedStaticData = uniquifyStaticData(staticDataForMetric,runtimeData);
        end
    end
end
