classdef FunctionCoverageReportFormatter< matlab.unittest.internal.coverage.CoverageReportMetricFormatter

    % Class is undocumented and may change in a future release.
    
    %  Copyright 2021-2023 The MathWorks, Inc.
    
    properties(Constant)
        OutputStructFieldName = "Function"
    end

    methods 
        function dataStruct = formatSummaryData(~,fileCoverageInfoArray)
            fcnMetrics = fileCoverageInfoArray.getCoverageData('matlab.unittest.internal.coverage.metrics.FunctionMetric');

            executableFunctionCountArray = [fcnMetrics.ExecutableFunctionCount];
            totalExecutableFunctions = sum(executableFunctionCountArray);

            executedFunctionCountArray = [fcnMetrics.ExecutedFunctionCount];
            totalExecutedFunctions = sum(executedFunctionCountArray);
            
            missedFunctionCountArray = executableFunctionCountArray - executedFunctionCountArray;
            totalFunctionsMissed = sum(missedFunctionCountArray);
            
            overallFunctionRate = (totalExecutedFunctions/totalExecutableFunctions)*100;

            dataStruct = struct('Total',totalExecutableFunctions,...
                'Executed',totalExecutedFunctions,...
                'Missed',totalFunctionsMissed,...
                'PercentCoverage',overallFunctionRate,...
                'FilteredCount', 0);  % For v1. This will be updated when users can add filters while creating the report.
        end 

        function dataStruct = formatBreakdownBySourceData(~, fileCoverageInfoArray)
            functionMetrics = fileCoverageInfoArray.getCoverageData('matlab.unittest.internal.coverage.metrics.FunctionMetric');

            executableFunctionCountArray = [functionMetrics.ExecutableFunctionCount];
            executedFunctionCountArray = [functionMetrics.ExecutedFunctionCount];            

            dataStruct = struct('ExecutableArray',executableFunctionCountArray,...
                'ExecutedArray',executedFunctionCountArray,...
                'FilteredCountArray',zeros(1,numel(fileCoverageInfoArray))); % For v1. This will be updated when users can add filters while creating the report.
        end

        function dataStructArray = formatSourceDetailsData(~, fileCoverageInfo)
            import matlab.unittest.internal.coverage.findStatementsOnExecutableLinesMask   
            % returns an array of structs of length equal to the number of
            % instrumented lines in a file. 
            functionMetric = fileCoverageInfo.getCoverageData('matlab.unittest.internal.coverage.metrics.FunctionMetric');
            executableLines = [functionMetric.ExecutableLines];

            functionCoverageMetricsStructArray = cell(1,numel(executableLines));
            filterDataExistsBool = width(functionMetric.RawCoverageData) > 3; % If code dependency data exists
            if filterDataExistsBool
                functionFilterData = functionMetric.RawCoverageData(:,4);
            else
                functionFilterData = repmat({''},height(functionMetric.RawCoverageData),1);
            end

            % Create a mask of statements on executable lines. This is a
            % MxN matrix of boolean values where M is the number of
            % statements and N is the number of  executable lines.
            fcnStatemtentsOnExecLinesMask = cellfun(@(x)findStatementsOnExecutableLinesMask(executableLines,x),functionMetric.SourcePositionData,'UniformOutput',false);
            fcnStatemtentsOnExecLinesMask = vertcat(fcnStatemtentsOnExecLinesMask{:});   
            
            % Create a coverage metrics struct for each instrumented
            % line. This contains the line number, source position
            % of function header(s) on that line, their hit counts and a
            % boolean indicating if the line is a continued line or
            % not.
            for lineNoIdx = 1:numel(executableLines)
                functionCoverageMetricsStruct.LineNumber = executableLines(lineNoIdx);
                functionStatementsOnLine = fcnStatemtentsOnExecLinesMask(:,lineNoIdx);
                functionCoverageMetricsStruct.Hits = functionMetric.HitCount(functionStatementsOnLine);
                [functionCoverageMetricsStruct.StartColumnNumbers,functionCoverageMetricsStruct.EndColumnNumbers] = getStatementStartAndEndNumsForLine(functionMetric.SourcePositionData(functionStatementsOnLine),executableLines(lineNoIdx));
                functionCoverageMetricsStruct.ContinuedLine = getContinuedLineState(functionMetric.SourcePositionData(functionStatementsOnLine),executableLines(lineNoIdx));
                functionCoverageMetricsStruct.Filterable = repmat(filterDataExistsBool, 1, nnz(functionStatementsOnLine)); % All function headers are filterable as per the design, if Filter Data exists.
                functionCoverageMetricsStruct.FilterDataUUID = string(functionFilterData(functionStatementsOnLine));
                functionCoverageMetricsStructArray{lineNoIdx} = functionCoverageMetricsStruct;
            end
            dataStructArray = [functionCoverageMetricsStructArray{:}];            
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
