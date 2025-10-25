function h = getCurrentControlsChart(ax)
arguments
    ax = gca
end
if isa(ax,'matlab.ui.Figure')
    ax = ax.CurrentAxes;
end
h = ancestor(ax,'controllib.chart.internal.foundation.AbstractPlot');
end