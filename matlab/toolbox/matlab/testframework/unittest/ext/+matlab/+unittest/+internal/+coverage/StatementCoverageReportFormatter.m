classdef StatementCoverageReportFormatter< matlab.unittest.internal.coverage.CoverageReportMetricFormatter

    % Class is undocumented and may change in a future release.
    
    %  Copyright 2021-2023 The MathWorks, Inc.
    
    properties(Constant)
        OutputStructFieldName = "Statement"
    end

    methods 
        function dataStruct = formatSummaryData(~,fileCoverageInfoArray)
            statementMetrics = fileCoverageInfoArray.getCoverageData('matlab.unittest.internal.coverage.metrics.StatementMetric');

            executableStatementCountArray = [statementMetrics.ExecutableStatementCount];
            totalExecutableStatements = sum(executableStatementCountArray);

            executedStatementCountArray = [statementMetrics.ExecutedStatementCount];
            totalExecutedStatements = sum(executedStatementCountArray);
            
            missedStatementCountArray = executableStatementCountArray - executedStatementCountArray;
            totalStatementsMissed = sum(missedStatementCountArray);
            
            overallStatementRate = (totalExecutedStatements/totalExecutableStatements)*100;

            dataStruct = struct('Total',totalExecutableStatements,...
                'Executed',totalExecutedStatements,...
                'Missed',totalStatementsMissed,...
                'PercentCoverage',overallStatementRate,...
                'FilteredCount', 0);  % For v1. This will be updated when users can add filters while creating the report.
        end 

        function dataStruct = formatBreakdownBySourceData(~, fileCoverageInfoArray)
            statementMetrics = fileCoverageInfoArray.getCoverageData('matlab.unittest.internal.coverage.metrics.StatementMetric');

            executableStatementCountArray = [statementMetrics.ExecutableStatementCount];
            executedStatementCountArray = [statementMetrics.ExecutedStatementCount];            

            dataStruct = struct('ExecutableArray',executableStatementCountArray,...
                'ExecutedArray',executedStatementCountArray,...
                'FilteredCountArray',zeros(1,numel(fileCoverageInfoArray))); % For v1. This will be updated when users can add filters while creating the report.
        end

        function dataStructArray = formatSourceDetailsData(~, fileCoverageInfo)
            import matlab.unittest.internal.coverage.findStatementsOnExecutableLinesMask   
            % returns an array of structs of length equal to the number of
            % executable lines in a file.
            statementMetric = fileCoverageInfo.getCoverageData('matlab.unittest.internal.coverage.metrics.StatementMetric');
            executableLines = [statementMetric.ExecutableLines];

            if width(statementMetric.RawCoverageData) == 5 % If code dependency data exists
                statementFilterData = statementMetric.RawCoverageData(:,4:5);
            else
                statementFilterData = repmat([{'stmt'}, {''}],height(statementMetric.RawCoverageData),1);
            end

            statementCoverageMetricsStructArray = cell(1,numel(executableLines));
            
            % Create a mask of statements on executable lines. This is a
            % MxN matrix of boolean values where M is the number of
            % statements and N is the number of  executable lines.
            statemtentsOnExecLinesMask = cellfun(@(x)findStatementsOnExecutableLinesMask(executableLines,x),statementMetric.SourcePositionData,'UniformOutput',false);
            statemtentsOnExecLinesMask = vertcat(statemtentsOnExecLinesMask{:});   

            % Create a coverage metrics struct for each executable
            % line. This contains the line number, source position
            % of statements on that line, their hit counts and a
            % boolean indicating if the line is a continued line or
            % not.
            for lineNoIdx = 1:numel(executableLines)
                statementCoverageMetricsStruct.LineNumber = executableLines(lineNoIdx);
                statementsOnLine = statemtentsOnExecLinesMask(:,lineNoIdx);
                statementCoverageMetricsStruct.Hits = statementMetric.HitCount(statementsOnLine);
                [statementCoverageMetricsStruct.StartColumnNumbers,statementCoverageMetricsStruct.EndColumnNumbers] = getStatementStartAndEndNumsForLine(statementMetric.SourcePositionData(statementsOnLine),executableLines(lineNoIdx));
                statementCoverageMetricsStruct.ContinuedLine = getContinuedLineState(statementMetric.SourcePositionData(statementsOnLine),executableLines(lineNoIdx));
                statementCoverageMetricsStruct.Filterable = getFilterableStatusForAStatement(statementFilterData,statementsOnLine);
                statementCoverageMetricsStruct.FilterDataUUID = string(statementFilterData(statementsOnLine,2));
                statementCoverageMetricsStructArray{lineNoIdx} = statementCoverageMetricsStruct;
            end
            dataStructArray = [statementCoverageMetricsStructArray{:}];            
        end
    end

end

function [startColNum,endColNum] = getStatementStartAndEndNumsForLine(statementSourcePositionsCell, lineNo)
sourceRangeMat = vertcat(statementSourcePositionsCell{:});

% only pick source ranges that match the line numbers. Exceptions -
% statements with line continuations
sourceRangeMat = sourceRangeMat(sourceRangeMat(:,1)==lineNo,:);

startColNum = sourceRangeMat(:,2)'-1; % Js follows zero-based indexing
endColNum = sourceRangeMat(:,4)';
end

function bool = getContinuedLineState(statementSourcePositionsCell,lineNo)
% This fcn returns true if a line has no starting points of a statement. If
% a line only has the continued parts of a statement, hit counts for that
% line are not displayed.
bool = ~any(cellfun(@(x)x(1,1)==lineNo,statementSourcePositionsCell));
end

function filterBool = getFilterableStatusForAStatement(filterData,statementMap)
filterableStatementTypeSet = {'try','catch'};  % Outcome based statements like {'if','for','while'} are covered in Decision Coverage
filterBool = ismember(filterData(statementMap,1),filterableStatementTypeSet)';     
end