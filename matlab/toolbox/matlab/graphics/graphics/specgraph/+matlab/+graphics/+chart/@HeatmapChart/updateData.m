function updateData(hObj)
% Recalculate the data from the table and then update the XData,
% YData, and ColorData with the results.

% Copyright 2016-2023 The MathWorks, Inc.

import matlab.graphics.chart.internal.heatmap.aggregateData

% Check if we are in table mode and the data are dirty.
if hObj.UsingTableForData && hObj.DataDirty
    % Call aggregateData to do the actual aggregation.
    [xData, yData, colorData, counts, rInds] = aggregateData(hObj.SourceTable, ...
        hObj.XVariableName, hObj.YVariableName, ...
        hObj.ColorVariableName, hObj.ColorMethod);
    
    % Record the calculated XData/YData/ColorData for use later.
    hObj.CalculatedXData = xData;
    hObj.CalculatedYData = yData;
    hObj.CalculatedColorData = colorData;
    hObj.CalculatedCounts = counts;
    hObj.CalculatedRowIndices = rInds;
    
    % Update the ColorData
    hObj.ColorData_I = colorData;
    
    % Update the XData
    hObj.XData_I = xData;
    
    % Update the YData
    hObj.YData_I = yData;
    
    % Mark the data clean.
    hObj.DataDirty = false;
    
    % Record that the table data changed.
    hObj.DataChangedEventData.Table = true;
    
    % Calculate aggregated data used by the data tips.
    dtConfig = hObj.getDataTipConfiguration();
    numDTVar = size(dtConfig,1);
    hObj.CalculatedDataTipData = cell(numDTVar,1);
    if ~strcmpi('none',hObj.ColorMethod)
        skippedVars = {hObj.SourceTable.Properties.DimensionNames{1},...
            hObj.XVariableName, hObj.YVariableName};
        for i = 1:numDTVar
            % Compute aggregated data for each datatip variable
            dtVar = dtConfig(i,1);
            dtMethod = dtConfig(i,2);
            
            % Only numeric values are aggregatable. We need to compute
            % aggregated data for numeric color variable when color method is
            % none
            if ~ismember(dtVar, skippedVars)
                [~, ~, aggregatedData] = aggregateData(hObj.SourceTable, ...
                    hObj.XVariableName, hObj.YVariableName, ...
                    dtVar, dtMethod);
                hObj.CalculatedDataTipData{i} = aggregatedData;
            end
        end
    end
end
end
