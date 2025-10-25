function [ax,isHoldOn] = getEntryAxesForChart(hParent)
% getEntryAxesForChart(ax)
%   default value of ax is gca
%
%   If ax is chart or part of chart 
%       - Return chart if hold is enabled
%       - Delete chart and create and return axes if hold is not enabled
%   Otherwise if gca is not an axes
%       - Delete and create and return an axes with same name
%   Otherwise return gca (axes) and clear if hold is not enabled

% Copyright 2024 The MathWorks, Inc.

arguments
    hParent {validateIfGraphicsObject(hParent)} = gca
end

if isempty(hParent)
    hParent = gca;
end

hParent = handle(hParent);
isHoldOn = false;
hChart = controllib.chart.internal.utils.getCurrentControlsChart(hParent);

if ~isempty(hChart)
    % ax is or is part of a controllib.chart
    if ~isHoldEnabled(hChart)
        hParent = hChart.Parent;
        ax = getChartAxes(hChart);
        ax = ax(1);
        ax.Parent = hParent;
        % Copy over outerposition, or layout options based on if chart is
        % in a tiledlayout or not
        if ~isa(hParent,'matlab.graphics.layout.TiledChartLayout')
            ax.OuterPosition = hChart.OuterPosition;
            ax.LooseInset = get(0,"DefaultAxesLooseInset");
        else
            ax.Layout = hChart.Layout;
        end
        delete(hChart);
    else
        ax = hChart;
        isHoldOn = true;
    end
elseif isa(hParent,'matlab.ui.Figure') 
    clf(hParent);
    ax = axes(hParent);
elseif isa(hParent,'matlab.ui.container.Panel') || ...
        isa(hParent,'matlab.ui.container.Tab') || isa(hParent,'matlab.ui.container.GridLayout')
    ax = axes(hParent);
elseif isa(hParent,'matlab.graphics.layout.TiledChartLayout')
    ax = nexttile(hParent);
elseif ~isa(hParent,'matlab.graphics.axis.Axes')
    % ax is not an axes (but a graphics object such as chart)
    axParent = hParent.Parent;
    delete(hParent);
    ax = axes(axParent);
else
    if ~isempty(gcr(hParent))
        resetLooseInset = false;
        isHoldOn = strcmp(hParent.NextPlot,'add');
        if ~isHoldOn
            % Need to reset loose inset because outer position of axes after
            % cla is incorrect
            resetLooseInset = true;
            % hParent is an axes contained in a resppack plot
            cla(hParent,'reset');
        end
    else
        % ax is an axes
        resetLooseInset = false;
        isHoldOn = strcmp(hParent.NextPlot,'add');
        if ~isHoldOn
            cla(hParent,'reset');
        end
    end
    ax = hParent;
    if resetLooseInset
        ax.LooseInset = get(groot,"DefaultAxesLooseInset");
    end
end
end

function validateIfGraphicsObject(ax)
if ~isgraphics(ax)
    error('Input must be a graphics object.');
end
end