function doLayout(sh,updateState)
% Ensure that the axes and legend size and visibility is appropriately set

%   Copyright 2018-2025 The MathWorks, Inc.


% Get the layout values to apply to font size and outer/inner spacing
layoutValues = matlab.graphics.internal.getSuggestedLayoutValues(sh, updateState);

if(strcmp(sh.FontSizeMode, 'auto'))
    sh.FontSize_I = layoutValues.FontSize;
end

% Define in points the gap between scatter axes and histogram (inGap) and
% the Gap around the periphery of the chart (outGap)

minWeight = min(layoutValues.ResponsiveWeight);
% outer gap ranges from 10 to 4 points
outGap = 10 * minWeight + (1.0 - minWeight) * 4;
% inner gap ranges from 5 to 2 points
inGap = 5 * minWeight + (1.0 - minWeight) * 2;


% Update labels
updateLabels(sh);

% Update the title
if ~isempty(sh.Title_I)
    updateTitle(sh);
end

% Update the position of the axes
updateAxesPosition(sh,updateState,inGap,outGap);

% Check if chart is within a subplot
if isInnerPositionManagedBySubplot(sh)
    setLooseInsetSubplot(sh,updateState,inGap,outGap);
end

hAx = sh.Axes;
outerPos = sh.OuterPosition_I;
units = sh.Units;
vp = hAx.Camera.Viewport;
outerPosPixels = matlab.graphics.internal.convertUnits(vp, 'pixels', units, outerPos);

positionConstraint = string(sh.ActivePositionProperty);

% Set the event data
sh.setState(outerPosPixels, ...
    "doUpdate",...
    positionConstraint);

% Update location and size of legend
updateLegend(sh,updateState,outGap);
end

% Update the position of the axes
function updateAxesPosition(sh,updateState,inGap,outGap)
% Get handles to axes
ax = sh.Axes;
axX = sh.AxesHistX;
axY = sh.AxesHistY;

% Convert Units to pixels
units = sh.Units;
sh.Units = 'points';

% Get the TightInsets of all axes
sti = matlab.graphics.chart.ScatterHistogramChart.getTightInset(ax,updateState);
xti = matlab.graphics.chart.ScatterHistogramChart.getTightInset(axX,updateState);
yti = matlab.graphics.chart.ScatterHistogramChart.getTightInset(axY,updateState);

% This function takes as input a the updateState and sets the
% positions of all 3 axes and the legend based on inner and
% outer position bounds
outP = sh.OuterPosition_I;

% Get the axes proportion
spp = sh.ScatterPlotProportion;

if strcmpi(sh.PositionConstraint,'outerposition')
    % Calculate the amount of area available for plotting by
    % taking the OuterPosition of the chart and subtracting
    % various TightInsets as well as leaving space between axes
    % and around the perimeter
    plotX = max([outP(3)-sti(1)-sti(3)-yti(1)-yti(3)-2*outGap-inGap,0]);
    plotY = max([outP(4)-sti(2)-sti(4)-xti(2)-xti(4)-2*outGap-inGap,0]);

    % Compute the area required available for histograms based on
    % the ScatterPlotProportion. From plotX and plotY choose the minimum
    % value and set this for both histograms. This ensures that the
    % histogram sizes are the same in points
    hist = min((1-spp)*[plotX,plotY]);

    switch lower(sh.ScatterPlotLocation)
        case 'southwest'
            % Update the LooseInset
            ax.LooseInset_I = [sti(1),sti(2),...
                hist+inGap,hist+xti(4)+inGap] + outGap;
            
            % Update Locations
            [~,pb] = getScatterAxesPositions(ax,updateState);
            axX.Position_I = [pb(1),pb(2)+pb(4)+inGap,pb(3),hist];
            axY.Position_I = [pb(1)+pb(3)+inGap,pb(2),hist,pb(4)];
        case 'southeast'
            % Update the LooseInset
            ax.LooseInset_I = [yti(1)+hist+yti(3)+sti(1)+inGap,sti(2)+inGap,...
                0,hist+xti(4)+inGap] + outGap;

            % Update Locations
            [dpb,pb] = getScatterAxesPositions(ax,updateState);
            axX.Position_I = [pb(1),pb(2)+pb(4)+inGap,pb(3),hist];
            axY.Position_I = [dpb(1)-inGap-yti(3)-hist,pb(2),hist,pb(4)];
        case 'northeast'
            % Update the LooseInset
            ax.LooseInset_I = [yti(1)+hist+yti(3)+sti(1)+inGap,xti(2)+hist+xti(4)+sti(2)+inGap,...
                0,sti(4)] + outGap;

            % Update Locations
            [dpb,pb] = getScatterAxesPositions(ax,updateState);
            axX.Position_I = [pb(1),dpb(2)-inGap-xti(4)-hist,pb(3),hist];
            axY.Position_I = [dpb(1)-inGap-yti(3)-hist,pb(2),hist,pb(4)];
        case 'northwest'
            % Update the LooseInset
            ax.LooseInset_I = [sti(1),xti(2)+hist+xti(4)+sti(2)+inGap,...
                hist+inGap,sti(4)] + outGap;

            % Update Locations
            [dpb,pb] = getScatterAxesPositions(ax,updateState);
            axX.Position_I = [pb(1),dpb(2)-inGap-xti(4)-hist,pb(3),hist];
            axY.Position_I = [dpb(1)+dpb(3)+inGap,pb(2),hist,pb(4)];
    end
    
    % When updating the LooseInset, check if left+right TI > width and same
    % for vertical dimension. If it is greater, set the corresponding
    % histogram width and height to be 0. The axes are already invisible,
    % so this is better than switching off visibility for all axes
    % children+labels etc.
    if sti(1)+sti(3) > outP(3)
        axY.Position_I(3:4) = 0;
    end
    if sti(2)+sti(4) > outP(4)
        axX.Position_I(3:4) = 0;
    end
else
    % Obtain the InnerPosition of th scatter axes
    iP = ax.Position_I;

    % Update the histograms so that they line up with the scatter axes
    axX.Position_I([1,3]) = iP([1,3]);
    axY.Position_I([2,4]) = iP([2,4]);
    
    % Find the area available for histograms based on the scatter axes. Cap
    % the axes aspect ratio so that it remains finite. Just as in
    % OuterPosition, pick the minimum of the histogram heights
    spp = max([spp,iP(3:4)./outP(3:4)]);
    ar = (1-spp)./spp;
    hist = max([ar*min([iP(3),iP(4)]),0]); % Ensure hist is not negative

    % Update the widths and heights of the histograms
    axX.Position_I(4) = hist;
    axY.Position_I(3) = hist;

    switch lower(sh.ScatterPlotLocation)
        case 'southwest'
            axX.Position_I(2) = iP(2) + iP(4) + inGap;
            axY.Position_I(1) = iP(1) + iP(3) + inGap;
        case 'southeast'
            axX.Position_I(2) = iP(2) + iP(4) + inGap;
            axY.Position_I(1) = iP(1)-sti(1)-inGap-yti(3)-hist;
        case 'northeast'
            axX.Position_I(2) = iP(2)-sti(2)-inGap-xti(4)-hist;
            axY.Position_I(1) = iP(1)-sti(1)-inGap-yti(3)-hist;
        case 'northwest'
            axX.Position_I(2) = iP(2)-sti(2)-inGap-xti(4)-hist;
            axY.Position_I(1) = iP(1) + iP(3) + inGap;
    end
end

% Convert back to original units
sh.Units = units;
end

% Update location and size of legend
function updateLegend(sh,updateState,outGap)
% This method is called from within a doUpdate, has access to
% the updateState and updates the size and location of the
% legend based on the locations/positions of the three axes

% Update the size of legend by getting preferred size based on
% FontSize           
prefSize = getPreferredSize(sh.LegendHandle,updateState);

% Change the chart's units to points because prefSize is always
% returned in points
units = sh.Units;
sh.Units = 'points';

% Find the maximum allowed size of legend based on other axes'
% layout information
posX = matlab.graphics.chart.ScatterHistogramChart.getPositionInPoints...
    (sh.AxesHistX,updateState,'PlotBox');
posY = matlab.graphics.chart.ScatterHistogramChart.getPositionInPoints...
    (sh.AxesHistY,updateState,'PlotBox');
maxSize = [posY(3),posX(4)];

% Check if preferred size is within maximum size allowed
sz = prefSize > maxSize;

% Update the Legend's visibility depending on size and number
% of categories, only if the mode is auto
if strcmp(sh.LegendVisibleMode,'auto')
    % Switch legend visibility to off if size is greater than max
    % size allowed or number of categories is fewer than 2
    if any(sz) || length(sh.LegendHandle.Categories) < 2
        sh.LegendVisible = 'off';
    else
        sh.LegendVisible = 'on';
    end
    sh.LegendVisibleMode = 'auto';
end

% Ensure that the actual Legend's visibility matches that of the chart property
if ~isempty(sh.LegendHandle.Categories)
    sh.LegendHandle.Visible = sh.LegendVisible;
end

% Get the chart's OuterPosition
oP = sh.OuterPosition_I;

% Find the appropriate location for the legend
loc = lower(sh.ScatterPlotLocation);
if strcmpi(sh.PositionConstraint,'outerposition')
    switch loc
        case 'southwest'
            legPos = [oP(1)+oP(3)-prefSize(1)-outGap,oP(2)+oP(4)-prefSize(2)-outGap];
        case 'southeast'
            legPos = [oP(1)+outGap,oP(2)+oP(4)-prefSize(2)-outGap];
        case 'northeast'
            legPos = [oP(1)+outGap,oP(2)+outGap];
        case 'northwest'
            legPos = [oP(1)+oP(3)-prefSize(1)-outGap,oP(2)+outGap];
    end
else
    % If active position is innerposition, make sure that the legend moves
    % according to the histogram axes
    % Get histogram positions
    xiP = sh.AxesHistX.Position_I;
    yiP = sh.AxesHistY.Position_I;
    
    switch loc
        case 'southwest'
            legPos = [yiP(1)+yiP(3)-prefSize(1),xiP(2)+xiP(4)-prefSize(2)];
        case 'southeast'
            legPos = [yiP(1),xiP(2)+xiP(4)-prefSize(2)];
        case 'northeast'
            legPos = [yiP(1),xiP(2)];
        case 'northwest'
            legPos = [yiP(1)+yiP(3)-prefSize(1),xiP(2)];
    end
end

% Update the size and location
sh.LegendHandle.PositionInPoints = [legPos,prefSize];

% Change units back to the chart's original units
sh.Units = units;

sh.UpdateLegend = false;
end

% Update x and y labels
function updateLabels(sh)
% This method sets the x and y labels for the chart. The labels
% are not always created for the scatterplot, but are intended
% to be placed along whichever axes lie along the left and
% bottom edges of the chart

% Get new labels and best to set previous ones to ''
xnam = sh.XLabel_I;
ynam = sh.YLabel_I;
sh.Axes.XAxis.Label.String_I = '';
sh.Axes.YAxis.Label.String_I = '';
sh.AxesHistX.XAxis.Label.String_I = '';
sh.AxesHistX.YAxis.Label.String_I = '';
sh.AxesHistY.XAxis.Label.String_I = '';
sh.AxesHistY.YAxis.Label.String_I = '';

% Which axes has its labels set depends on the relative
% location of the axes. The axes along the bottom and left
% edges of the chart will show labels
switch lower(sh.ScatterPlotLocation)
    case 'southwest'
        xlbl = sh.Axes.XAxis.Label;
        ylbl = sh.Axes.YAxis.Label;
    case 'southeast'
        xlbl = sh.Axes.XAxis.Label;
        ylbl = sh.AxesHistY.YAxis.Label;
    case 'northeast'
        xlbl = sh.AxesHistX.XAxis.Label;
        ylbl = sh.AxesHistY.YAxis.Label;
    case 'northwest'
        xlbl = sh.AxesHistX.XAxis.Label;
        ylbl = sh.Axes.YAxis.Label;
end

% Update the labels using String_I to avoid triggering post-set listeners.
xlbl.String_I = xnam;
ylbl.String_I = ynam;

% Make sure the StringMode is manual so that automaticl labels don't
% replace the labels coming from the chart.
xlbl.StringMode = 'manual';
ylbl.StringMode = 'manual';

% Update the post-set listeners to detect interactive editing of labels.
sh.ListenerXLabelEdit = updateListener(sh.ListenerXLabelEdit, xlbl, ...
    @(~,~) set(sh, 'XLabel', xlbl.String_I));
sh.ListenerYLabelEdit = updateListener(sh.ListenerYLabelEdit, ylbl, ...
    @(~,~) set(sh, 'YLabel', ylbl.String_I));

end

% Update the Title's location if one exists
function updateTitle(sh)
% The strategy is to set the title for either the scatter axes
% or the histX axes (whichever is on top) and then move it
% horizontally such that it is placed in the center of the
% chart

% Get the axes location
loc = lower(sh.ScatterPlotLocation);

% We set either the scatterplot axes title or the x histogram
% axes title depending on which is on top
if contains(loc,'north')
    ax = sh.Axes;
    axEmpty = sh.AxesHistX;
else
    ax = sh.AxesHistX;
    axEmpty = sh.Axes;
end

% Set title
if ~isempty(ax.Title_IS)
    ax.Title_IS.String_I = sh.Title_I;
    ax.Title_IS.StringMode = 'manual';
    sh.ListenerTitleEdit = updateListener(sh.ListenerTitleEdit, ...
        ax.Title_IS, @(~,~) set(sh, 'Title', ax.Title_IS.String_I));
end

% Set the other axes' title-string to empty
if ~isempty(axEmpty.Title_IS)
    axEmpty.Title_IS.String = '';
end

% Calculate the amount that the title needs to be shifted in
% order to place it at the center of the chart
spp = sh.InnerPosition_I(3)./sh.OuterPosition_I(3);
if contains(loc,'east')
    spp = -spp;
end
posNorm = (sh.InnerPosition_I(1)+0.5*sh.InnerPosition_I(3))*(1+spp);
lim = sh.XLimits_I;

if ~isempty(lim) && ~isempty(ax.Title_IS)
    posData = lim(1) + posNorm*diff(lim);
    ax.Title_IS.Position_I(1) = posData;
end

if ~isempty(ax.Title_IS)
    ax.Title_IS.Visible = 'on';
end
end

% Helper function for getting scatter axes layout
function [dpb,pb] = getScatterAxesPositions(ax,updateState)
layout = ax.GetLayoutInformation();
dpb = updateState.convertUnits('canvas',ax.Units_I,'pixels',layout.DecoratedPlotBox);
pb = updateState.convertUnits('canvas',ax.Units_I,'pixels',layout.PlotBox);
end

% Helper function to set LooseInsets from subplot
function setLooseInsetSubplot(sh,updateState,inGap,outGap)
% Convert chart units to points
units = sh.Units;
sh.Units = 'points';

% Get the layout information for both histogram axes to calculate width and
% height
[sDPB,sPB] = getScatterAxesPositions(sh.AxesHistX,updateState);
[xDPB,~] = getScatterAxesPositions(sh.AxesHistX,updateState);
[yDPB,~] = getScatterAxesPositions(sh.AxesHistY,updateState);
sti = sPB(1:2)-sDPB(1:2);

switch lower(sh.ScatterPlotLocation)
    case 'southwest'
        li = [outGap+sti(1),outGap+sti(2),...
            yDPB(3)+inGap+outGap,xDPB(4)+inGap+outGap];
    case 'southeast'
        li = [outGap+yDPB(3)+inGap+sti(1),outGap+sti(2),...
            outGap,inGap+xDPB(4)+outGap];
    case 'northeast'
        li = [outGap+yDPB(3)+inGap+sti(1),outGap+xDPB(4)+inGap+sti(2),...
            outGap,outGap];
    case 'northwest'
        li = [outGap+sti(1),outGap+xDPB(4)+inGap+sti(2),...
            inGap+yDPB(3)+outGap,outGap]; 
end

% Set the ChartDecoreationInset property which reserves space for the
% histograms
sh.ChartDecorationInset_I = updateState.convertUnits('canvas',units,'points',li);

% Restore the units
sh.Units = units;
end

function listener = updateListener(listener, lbl, fcn)

if isempty(listener) || listener.Object{1} ~= lbl
    p = findprop(lbl, 'String');
    listener = event.proplistener(lbl, p, 'PostSet', fcn);
end

end
