classdef LineMetric < matlab.unittest.internal.coverage.metrics.Metric
    %
    
    %  Copyright 2021-2023 The MathWorks, Inc.
    
    properties(SetAccess = private)
        RawCoverageData
        ExecutableLines
        HitCount
        SourcePositionData
        ExecutableLineCount
        ExecutedLineCount
    end

    properties(Access = private)
        SetHitCount = false
    end

    methods
        function metric = LineMetric(coverageData)
            metric.RawCoverageData = coverageData;
        end

        function executableLines = get.ExecutableLines(metric)
            executableLines = metric.getReportableLines;
        end

        function count = get.ExecutableLineCount(metric)
            count = numel(metric.ExecutableLines);
        end

        function count = get.ExecutedLineCount(metric)
            count = nnz(metric.HitCount);
        end


        function hits = get.HitCount(metric)
            if ~metric.SetHitCount
                metric.HitCount = metric.getHitCount;
                metric.SetHitCount = true;
            end
            hits = metric.HitCount;
        end

        function sourcePositionArray = get.SourcePositionData(metric)
            sourcePositionArray = metric.RawCoverageData(:,1);
        end

        function  filteredmetric = filterMetricForMethod(metric, methodCoverageInfo)
            methodRawCoverageData = filterCoverageDataForMethodLines(metric.RawCoverageData,methodCoverageInfo.ExecutableLines);
            filteredmetric = matlab.unittest.internal.coverage.metrics.LineMetric(methodRawCoverageData);
        end
    end

    methods(Access = protected)
        function hits = getHitCount(metric)

            [execLines,nonUniqueExecLines] = metric.getReportableLines;

            numStatements = height(metric.RawCoverageData); % one statement per row of static data
            hitCountsCell = cell(1,numStatements); % initialize

            for stIdx = 1:numStatements
                numExecLinesForStatement = height(metric.RawCoverageData{stIdx,1}); % get number of executable lines for current statement
                hitCountsCell{stIdx} = repmat(metric.RawCoverageData{stIdx,2},1,numExecLinesForStatement); % distribute hit counts across all lines that a statement spans
            end
            nonUniqueHitCounts =  [hitCountsCell{:}];

            % In case there are multiple statements on a line, get the max hit count of
            % the statements to be the hitcount for the line
            uniqueHitCountsPerLineCell = arrayfun(@(x) findMaxHitsPerLine(x,nonUniqueExecLines,nonUniqueHitCounts),execLines,'UniformOutput',false);
            hits = [uniqueHitCountsPerLineCell{:}];
        end
    end
    
end
function maxHitCount = findMaxHitsPerLine(executableLine,nonUniqueExecLines,nonUniqueHitCounts)
    repeatedLineNumMask = nonUniqueExecLines == executableLine;
    maxHitCount = max(nonUniqueHitCounts(repeatedLineNumMask));
end
function methodRawCoverageData = filterCoverageDataForMethodLines(rawCoverageData,executableLines)
    linesMask = cellfun(@(x)ismember(x(1,1), [executableLines(:)]),rawCoverageData(:,1));
    methodRawCoverageData = rawCoverageData(linesMask,:);
end
