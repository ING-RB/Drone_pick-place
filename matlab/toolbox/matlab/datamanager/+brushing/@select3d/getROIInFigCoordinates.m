function [figRegionCoords,figDragEnd,figDragStart, maxX, minX, maxY, minY]   = getROIInFigCoordinates(this, varargin)
% This internal helper function may change in a future release.

% getROIInFigCoordinates returns the ROI vertices in figure coordinates

%  Copyright 2019-2023 The MathWorks, Inc.

fig = this.Figure;
ax = this.Axes;

% It is possible for windowFocusLostFcn to clear the brushing.select3d
% object when the renderer is changed to openGL by the brushdown function
% during a brushing gesture (g654964). This will cause the Axes and Figure
% properties to be cleared. Quick return to prevent that causing an error.
if isempty(ax) || isempty(fig)
    [figRegionCoords,figDragEnd,figDragStart, maxX, minX, maxY, minY] = deal([]);
    return
end

% Get ROI vertices in figure coords
figDragEnd = get(fig,'CurrentPoint');
figDragStart = this.ScribeStartPoint;

%Since all coputations are done in pixels , make sure that the units are
%consistent
figDragEnd = hgconvertunits(fig,[figDragEnd 0 0],fig.Units,'pixels',fig);
figDragStart = hgconvertunits(fig,[figDragStart 0 0],fig.Units,'pixels',fig);

figRegionCoords = [figDragStart(1) figDragStart(2);...
    figDragEnd(1) figDragStart(2);...
    figDragEnd(1) figDragEnd(2);...
    figDragStart(1) figDragEnd(2)
    ]';
end