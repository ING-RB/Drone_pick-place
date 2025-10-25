classdef MethodCoverageInfo

    % Class is undocumented and may change in a future release.
    
    %  Copyright 2021-2023 The MathWorks, Inc.

    properties(SetAccess = private)                
        Name
        Signature
        ExecutableLines
        Metrics
    end

    methods
        function coverageMethodInfoArray = MethodCoverageInfo(methodInformation, metrics)
            if nargin<1
                return
            end
            coverageMethodInfoArray = repmat(coverageMethodInfoArray,size(methodInformation));
            [coverageMethodInfoArray.Name] = deal(methodInformation.Name);
            [coverageMethodInfoArray.ExecutableLines] = deal(methodInformation.ExecutableLines);            
            [coverageMethodInfoArray.Signature] = deal(methodInformation.Signature);
            [coverageMethodInfoArray.Metrics] = deal(metrics);
        end

        function metric = getCoverageData(methodCoverageInfo,metricClass)
            % get metric for the file using the metric class and then filter metric to scope to method level
            import matlab.unittest.internal.coverage.metrics.Metric
            allMetrics = [methodCoverageInfo.Metrics];
            addedMetrics  = allMetrics(arrayfun(@(x) class(x) == string(metricClass),allMetrics));
            rawMetric = [Metric.empty(1,0) addedMetrics];
            metric = rawMetric.filterMetricForMethod(methodCoverageInfo);            
        end
    end
end
