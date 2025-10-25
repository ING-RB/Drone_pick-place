function uniqueCoverageData = uniquifyStaticData(coverageData, runtimeData)
% Internal function used by StatementMetric and FunctionMetric classes.

% This function is aimed at uniquifying the coverage data for Pfile, where
% all statements on a line get the same source position data.
% This function returns a static data with unique source positions and the
% corresponding indices of the max hit count for any statement on a given
% line.

% Copyright 2021-2022 The MathWorks, Inc.

if isempty(coverageData)
    uniqueCoverageData = coverageData;
    return
end
% In case of a statement split into multiple lines, just use the source
% position for the first line of the statement to avoid reporting duplicate
% data.
sourcePositionDataPerStatementCell = arrayfun(@(idx)coverageData{idx,1}(1,:),1:height(coverageData),'UniformOutput',false);
sourcePositionDataPerStatement = vertcat(sourcePositionDataPerStatementCell{:});
[uniqueSourcePositionData,~,matchIdx] = unique(sourcePositionDataPerStatement,'rows');

% create a Nx2 matrix with runtimeData index and runtimeData values as
% columns for each statement. Use this to find the index corresponding to
% the max hit count for all statements with same source position data.
runtimeDataMat = [[coverageData{:,2}]', runtimeData([coverageData{:,2}]+1)];

runtimeDataIdx = zeros(max(matchIdx),1);
for rowIdx = 1:max(matchIdx)
    hitsArray = -1*ones(height(coverageData),1);  % use -1 since 0 is a valid hit count.
    hitsArray(rowIdx == matchIdx) = runtimeDataMat(rowIdx == matchIdx,2);
    [~,runtimeDataIdx(rowIdx)] = max(hitsArray); 
end
uniqueCoverageData = [num2cell(uniqueSourcePositionData,2) num2cell(runtimeDataMat(runtimeDataIdx,1))];
