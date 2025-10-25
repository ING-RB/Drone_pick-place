function figRegionCoords = draw(this,varargin)
% This internal helper function may change in a future release.

% DRAW draws a region of interest (ROI) based on a brushing drag gesture.
%
% DRAW returns the geometry of the cross section as a 2x2 matrix where
% each row represents the pair of coordinates in figure normalized units.
% Note that unlike 2d data brushing, 3d data brushing uses the figure
% coordinates rather than the axes coordinates to take advantage of the hg
% projection functionality. Note that the ROI will be clipped to the axes
% bounds.

%  Copyright 2008-2019 The MathWorks, Inc.

figRegionCoords = this.getROIInFigCoordinates(varargin);
if isempty(figRegionCoords) || ~this.isValidROI(figRegionCoords)
    return
end
vertexData =  this.transformFigureCoordsToVertexData(figRegionCoords);
this.draw@brushing.select(vertexData);
end
