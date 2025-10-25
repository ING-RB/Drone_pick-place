function [figRegionCoords,camRegionCoords,dataDragStart,dataDragEnd] = getROIInFigCoordinates(this, varargin)
% This internal helper function may change in a future release.

% getROIInFigCoordinates returns the ROI vertices in figure coordinates

%  Copyright 2019 The MathWorks, Inc.

ax = this.Axes;

% Update the AxesYLim because the active dataspace may be different than the
% cached one
this.AxesYLim = ax.YAxis(ax.ActiveDataSpaceIndex).NumericLimits;

dataDragEnd = get(ax,'CurrentPoint');
dataDragStart = this.AxesStartPoint;

% Clip the ROI to the axes limits in data space.
xlim = this.AxesXLim;
ylim = this.AxesYLim;
dataDragEnd(:,1) = min(max(dataDragEnd(:,1),xlim(1)),xlim(2));
dataDragEnd(:,2) = min(max(dataDragEnd(:,2),ylim(1)),ylim(2));
dataDragStart(:,1) = min(max(dataDragStart(:,1),xlim(1)),xlim(2));
dataDragStart(:,2) = min(max(dataDragStart(:,2),ylim(1)),ylim(2));

% Get the camera coordinates for the brushing ROI.
dataStart = dataDragStart(1,1:2);
dataEnd = dataDragEnd(1,1:2);
segment1 = localTransform2DDataLineToCameraCoords(ax,[dataStart(1) dataStart(2)],...
    [dataEnd(1) dataStart(2)]);
segment2 = localTransform2DDataLineToCameraCoords(ax,[dataEnd(1) dataStart(2)],...
    [dataEnd(1) dataEnd(2)]);
segment3 = localTransform2DDataLineToCameraCoords(ax,[dataEnd(1) dataEnd(2)],...
    [dataStart(1) dataEnd(2)]);
segment4 = localTransform2DDataLineToCameraCoords(ax,[dataStart(1) dataEnd(2)],...
    [dataStart(1) dataStart(2)]);
% Remove overlapping line segment start and end points
camRegionCoords = [segment1,...
    segment2(:,2:end),...
    segment3(:,2:end),...
    segment4(:,2:end-1)];

% Get figure coordinates of brushing ROI for drawing ROI
% into the overlay camera in normalized figure units.
figRegionCoords = brushing.select.transformCameraToFigCoord(ax,camRegionCoords);
end

function lineCameraVertices = localTransform2DDataLineToCameraCoords(ax,x1,x2)
lineDataCoords  = [x1(1) x2(1);x1(2) x2(2); 0 0];
lineCameraVertices = TransformLine(ax.DataSpace,[],lineDataCoords');
end
