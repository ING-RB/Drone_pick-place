classdef StatementMetric < matlab.unittest.internal.coverage.metrics.Metric
    %
    
    %  Copyright 2021 The MathWorks, Inc.

    properties (SetAccess = private)
        RawCoverageData
        ExecutableStatementCount
        ExecutedStatementCount
        ExecutableLines
        HitCount
        SourcePositionData
    end
    

    methods
        function metric = StatementMetric(coverageData)
            metric.RawCoverageData = coverageData;
        end

        function executableLines = get.ExecutableLines(metric)
            executableLines = metric.getReportableLines;
        end

        function hits = get.HitCount(metric)
            hits = [metric.RawCoverageData{:,2}];            
        end

        function count = get.ExecutableStatementCount(metric)
            count = height(metric.RawCoverageData);
        end

        function count = get.ExecutedStatementCount(metric)
            count = nnz(metric.HitCount);
        end

        function sourcePositionArray = get.SourcePositionData(metric)
            sourcePositionArray = metric.RawCoverageData(:,1);
        end
    end
end

