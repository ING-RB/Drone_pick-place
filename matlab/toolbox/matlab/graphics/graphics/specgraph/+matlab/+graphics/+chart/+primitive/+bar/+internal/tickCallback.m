function tickCallback(ax, xData, horizontal, updateOrthoTicks)
% Given a change to the horizontal or data properties, update the axes ticks
% appropriately.

%   Copyright 2014-2024 The MathWorks, Inc.

if isempty(ax) || strcmp(ax.NextPlot, 'add')
    return;
end

maindim = 'X';
orthodim = 'Y';
if strcmp(horizontal,'on')
    maindim = 'Y';
    orthodim = 'X';
end

rulerprop = "Active" + maindim + "Ruler";
xData = ruler2num(xData, ax.(rulerprop));

matlab.graphics.chart.primitive.bar.internal.updateTicks(ax, maindim, orthodim, xData, updateOrthoTicks);
end
