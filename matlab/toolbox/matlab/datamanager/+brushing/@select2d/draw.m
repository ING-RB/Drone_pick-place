function figRegionCoords = draw(this,varargin)
% This internal helper function may change in a future release.

% DRAW returns the geometry of the cross section:
%
% DRAW returns the geometry of the cross section in axes data coordinates
% and draws the brushing corresponding brushing rectangle in the scribe
% layer after clipping it to the axes bounds. Current figure mouse position
% is determined from the eventData or the figure 'CurrentPoint' property,
% current axes data mouse position is determined from the axes
% 'CurrentPoint' property.

%  Copyright 2008-2019 The MathWorks, Inc.

% Get ROI vertices in figure coords
[figRegionCoords,camRegionCoords,dataDragStart,dataDragEnd] = this.getROIInFigCoordinates(varargin);

if ~this.isValidROI(figRegionCoords)
    % Return 4 vertices at the same point. This avoids calling TransformLine
    % on a zero length line.
    iter = matlab.graphics.axis.dataspace.XYZPointsIterator;
    iter.XData = dataDragStart(1,1);
    iter.YData = dataDragStart(1,2);
    iter.ZData = dataDragStart(1,3);
    camRegionCoords = TransformPoints(this.Axes.DataSpace,[],iter);
    figRegionCoords = repmat(brushing.select.transformCameraToFigCoord(this.Axes,camRegionCoords),[1 4]);
    return
end

[vertexData, textPosition, regionStr] = this.transformFigureCoordsToVertexData(figRegionCoords, dataDragStart, dataDragEnd,camRegionCoords );

this.draw@brushing.select(vertexData);

 %for 2d figure add text box or update the existing one
if ~isempty(this.Text)
    set(this.Text,'VertexData',textPosition,'String',regionStr,'VerticalAlignment','top');
else
    this.Text = matlab.graphics.primitive.world.Text('parent',this.ScribeLayer,'VertexData',textPosition,'String',regionStr);
    fontObj = this.Text.Font;
    fontObj.Size = 9;
    fontObj.Name = get(groot,'defaultUIcontrolFontName');
    set(this.Text,'Font',fontObj);
end




