classdef FunctionMetric < matlab.unittest.internal.coverage.metrics.Metric
    %
    
    %  Copyright 2021 The MathWorks, Inc.

    properties (SetAccess = private)
        RawCoverageData
        ExecutableFunctionCount
        ExecutedFunctionCount
        ExecutableLines
        HitCount
        SourcePositionData
    end

    methods
        function metric = FunctionMetric(coverageData)
            metric.RawCoverageData = coverageData;
        end

        function executableLines = get.ExecutableLines(metric)
            executableLines = metric.getReportableLines;
        end

        function hits = get.HitCount(metric)
            hits = [metric.RawCoverageData{:,2}];            
        end

        function count = get.ExecutableFunctionCount(metric)
            count = height(metric.RawCoverageData);
        end

        function count = get.ExecutedFunctionCount(metric)
            count = nnz(metric.HitCount);
        end

        function sourcePositionArray = get.SourcePositionData(metric)
            sourcePositionArray = metric.RawCoverageData(:,1);
        end
    end
end