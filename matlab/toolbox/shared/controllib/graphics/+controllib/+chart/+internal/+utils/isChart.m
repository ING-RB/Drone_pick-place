function isChart = isChart(plotHandle)
    isChart = isa(plotHandle,'controllib.chart.internal.foundation.AbstractPlot');
end