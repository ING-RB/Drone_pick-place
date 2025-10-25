function doUpdate(sh,updateState)
%

%   Copyright 2018-2024 The MathWorks, Inc.

% Make sure that the data in SourceTable has been passed to properties like
% XData, YData and GroupData
updateData(sh);

% Cycle through and update the bin properties to match size with NumGroups
[sh.XBinWidths,sh.YBinWidths,sh.XBins,sh.YBins] = ...
    matlab.graphics.chart.ScatterHistogramChart.cycleLineProperties...
    (sh.NumGroups,sh.XBinWidths,sh.YBinWidths,sh.XBins,sh.YBins);

% Validate data and bin sizes compared to num groups
validateDataSizes(sh);

% Update the markers and lines so that their length equals NumGroups
[sh.MarkerStyle_I,sh.MarkerSize_I,sh.MarkerAlpha_I,sh.LineStyle_I,sh.LineWidth_I]...
    = matlab.graphics.chart.ScatterHistogramChart.cycleLineProperties...
    (sh.NumGroups,sh.MarkerStyle_I,sh.MarkerSize_I,sh.MarkerAlpha_I,sh.LineStyle_I,sh.LineWidth_I);

% Update colororder
newColorList = sh.Color_I;
if sh.ColorMode == "auto"
    if ~isempty(sh.Parent) && sh.ColorOrderInternalMode == "auto"
        sh.ColorOrderInternal = get(sh.Parent, 'DefaultAxesColorOrder');
    end
    newColorList = sh.ColorOrderInternal;
end

% Update Color (at this point Color is always numeric)
if sh.NumGroups > size(newColorList,1)
    newColorList = repmat(newColorList,sh.NumGroups,1);
end
sh.Color_I = newColorList(1:sh.NumGroups,:);  % Color_I has AbortSet

% UpdateLimits is used within the pan/zoom callback which calls
% the plotting routines. Ensure that the callback is
% effectively deactivated when called from doUpdate
sh.UpdateLimits = false;

% Call the plotting routines based on flags set to true
if sh.UpdateScatter
    sh.plotScatter();
end        
if sh.UpdateX
    sh.plotHistogramX();
end           
if sh.UpdateY
    sh.plotHistogramY();
end
if sh.UpdateLegend
    sh.plotLegend();
end

% Update Markers and Lines
updateMarkersAndLines(sh);

% Place the axes and legend at appropriate locations with a
% call to doLayout
doLayout(sh,updateState);

% Reset Update modes
sh.UpdateX = false;
sh.UpdateY = false;
sh.UpdateScatter = false;
sh.UpdateLegend = false;

% Reset limits flag
sh.UpdateLimits = true;
end

% Validate data sizes
function validateDataSizes(sh)
% This function is meant to be called from the doUpdate. The
% intention is to throw a warning when sizes of data do not
% match but allow users to continue to interact with the chart.

% XData and YData
if sh.AxesFilled && (length(sh.XData_I) ~= length(sh.YData_I))
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidXDataOrYDataSize')));
end

% GroupData and XData
if ~isempty(sh.GroupIndex) && iscolumn(sh.GroupIndex) && ~isequal(size(sh.GroupIndex,1),size(sh.XData_I,1))
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidGroupDataSize')));
end

% GroupData and YData
if ~isempty(sh.GroupIndex) && iscolumn(sh.GroupIndex) && ~isequal(size(sh.GroupIndex,1),size(sh.YData_I,1))
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidGroupDataSize')));
end

% GroupData vs NumBins
if ~isempty(sh.GroupIndex) && ~isempty(sh.XBins) && ~isequal(size([sh.XBins;sh.YBins]),[2,sh.NumGroups])
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidBinSize','NumBins')));
end

% GroupData vs BinWidths
if ~isempty(sh.GroupIndex) && ~isempty(sh.XBinWidths) && ~isequal(size([sh.XBinWidths;sh.YBinWidths]),[2,sh.NumGroups])
    throwAsCaller(MException(message('MATLAB:graphics:scatterhistogram:InvalidBinSize','BinWidths')));
end
end

% Update the markers and lines within axes
function updateMarkersAndLines(sh)
% This method is intended to be called from a doUpdate. Markers
% and Lines are updated based on corresponding flags

% Update scatter plot only if markers exist
if sh.UpdateMarkers && sh.AxesFilled
    mrk = sh.MarkerStyle_I;
    mrkSiz = sh.MarkerSize_I;
    mrkAlpha = sh.MarkerAlpha_I;

    % Get the scatter axes children. 
    axChld = sh.ScatterAxesChildren;
    try 
        % Iterate over the markers and update them
        for idx = 1:sh.NumGroups
            % MarkerStyle
            axChld(idx).Marker = mrk(idx);

            % MarkerSize
            axChld(idx).SizeData = mrkSiz(idx);

            % MarkerAlpha
            axChld(idx).MarkerFaceAlpha = mrkAlpha(idx);
            axChld(idx).MarkerEdgeAlpha = mrkAlpha(idx);

            % MarkerFilled
            if strcmp(sh.MarkerFilled_I,'on')
                axChld(idx).MarkerFaceColor = 'flat';
            else
                axChld(idx).MarkerFaceColor = 'none';
            end
        end
    catch e
       throwAsCaller(e) 
    end
    
    % Plot the legend again to update markers
    plotLegend(sh);
    
    sh.UpdateMarkers = false;
end

% Update histograms only if lines exist
if sh.UpdateLines && sh.AxesFilledX && sh.AxesFilledY
    ls = sh.LineStyle_I;
    lw = sh.LineWidth_I;

    % Get the lines
    axX = sh.XHistAxesChildren;
    axY = sh.YHistAxesChildren;

    % Iterate over the lines and update them
    for idx = 1:sh.NumGroups
        % LineStyle
        axX(idx).LineStyle = ls(idx);
        axY(idx).LineStyle = ls(idx);

        % LineWidth
        axX(idx).LineWidth = lw(idx);
        axY(idx).LineWidth = lw(idx);
    end

    sh.UpdateLines = false;
end
end
