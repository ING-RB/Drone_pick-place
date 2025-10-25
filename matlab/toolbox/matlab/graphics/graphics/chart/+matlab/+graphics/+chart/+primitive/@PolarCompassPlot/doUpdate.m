function doUpdate(obj, updateState)
%

% Copyright 2024 The MathWorks, Inc

thetadata = double(obj.ThetaData);
rdata = double(obj.RData);
if numel(thetadata) ~= numel(rdata)
    error('MATLAB:compassplot:SizeMismatch',message('MATLAB:graphics:piechart:SizeMismatch','ThetaData','RData').string)
end

rlimits = updateState.DataSpace.YLim;
obj.BaseValue_I = rlimits(1);

% Remove data for compass lines that would be zero length. This includes
% RData that is right at the start of the limits, as well as non-finite
% R/ThetaData.
isZeroLength = (rdata - obj.BaseValue_I) == 0;
isZeroLength = isZeroLength | ~isfinite(rdata) | ~isfinite(thetadata);
thetadata = thetadata(~isZeroLength);
rdata = rdata(~isZeroLength);

% Standardize RData to be Positive
rmag = rdata - obj.BaseValue_I;
isNeg = rmag < 0;
rdata = abs(rmag) + obj.BaseValue_I;
thetadata(isNeg) = thetadata(isNeg) + pi;

% Standardize ThetaData to be between 0 and 2pi
thetadata = mod(thetadata,2*pi);

% Make vertex pairs for the radial lines.
tline = [thetadata; thetadata];
rline = [repmat(obj.BaseValue_I, size(rdata)); rdata];
numverts = numel(rdata)*2; % two vertices for each radial line
iter = matlab.graphics.axis.dataspace.XYZPointsIterator;
iter.XData = tline;
iter.YData = rline;
vertexData = updateState.DataSpace.TransformPoints(updateState.TransformUnderDataSpace, iter);
obj.Edge.VertexData = vertexData;
obj.Edge.StripData = uint32(1:2:(numverts+1));

% Add vertices for the arrow lines
arrowAngle = deg2rad(30); % angle inside one half of the arrowhead, from center to leg
if obj.ScaleArrowHeads_I
    scaleFactor = 1/12; % fraction of the radius of the PolarAxes
    vertexDataArrow = dataSpaceScaledArrowVertices(updateState, thetadata, rdata, rlimits, scaleFactor, arrowAngle);
else
    % arrowSizePix defines the size of each leg of the arrow head in
    % device pixels.
    arrowSizePix = max(obj.MarkerSize_I, obj.LineWidth_I)*updateState.DevicePixelsPerPoint;
    vertexDataArrow = fixedPixelArrowVertices(updateState, vertexData, arrowSizePix, arrowAngle);
end

obj.ArrowEdge.VertexData = vertexDataArrow;
numverts = numel(rdata)*3; % 3 vertices for each arrow head
stripdataArrow = 1:3:(numverts+1);
obj.ArrowEdge.StripData = uint32(stripdataArrow);
obj.ArrowEdge.LineJoin = "miter";

% Assign SeriesIndex if mode is auto and SeriesIndex is 0
obj.assignSeriesIndex();

% Update Color and LineStyle using ColorOrderUser methods
obj.applyColor(updateState, "Color");
obj.applyLineStyle(updateState, "LineStyle");

% Selection handles
if obj.Visible && obj.Selected && obj.SelectionHighlight
    if isempty(obj.SelectionHandle)
        obj.SelectionHandle = matlab.graphics.interactor.ListOfPointsHighlight('Internal',true);
        obj.SelectionHandle.Description = 'PolarCompassPlot SelectionHandle';
        obj.addNode( obj.SelectionHandle );
    end

    obj.SelectionHandle.VertexData = vertexData(:,2:2:end);
    obj.SelectionHandle.Visible = 'on';
else
    if ~isempty(obj.SelectionHandle)
        obj.SelectionHandle.VertexData = [];
        obj.SelectionHandle.Visible = 'off';
    end
end

end

function vertexDataArrow = fixedPixelArrowVertices(updateState, vertexData, arrowSizePix, arrowAngle)
% Compute arrow head vertices given a fixed pixel size defined by arrowSizePix.

% Compute info about vector line locations in pixel-space.
lineLocations = matlab.graphics.internal.transformWorldToViewer(updateState.Camera, ...
    updateState.TransformAboveDataSpace, updateState.DataSpace, ...
    updateState.TransformUnderDataSpace, vertexData);
endPoints = lineLocations(:,2:2:end);
deltas = endPoints - lineLocations(:,1:2:end-1);
lineAngle = atan2(deltas(2,:),deltas(1,:));

% Compute arrow head vertices for each arrow-head leg separately.
leg1DeltaX = arrowSizePix * cos(lineAngle - arrowAngle);
leg1DeltaY = arrowSizePix * sin(lineAngle - arrowAngle);
leg1 = endPoints - [leg1DeltaX; leg1DeltaY];

leg2DeltaX = arrowSizePix * cos(lineAngle + arrowAngle);
leg2DeltaY = arrowSizePix * sin(lineAngle + arrowAngle);
leg2 = endPoints - [leg2DeltaX; leg2DeltaY];

% Create vertex triplets for the arrow heads.
vertexDataArrow = nan(2,width(endPoints)*3);
vertexDataArrow(:,1:3:end) = leg1;
vertexDataArrow(:,2:3:end) = endPoints;
vertexDataArrow(:,3:3:end) = leg2;

% Convert vertices back to world coordinates.
vertexDataArrow = single(matlab.graphics.internal.transformViewerToWorld(updateState.Camera, ...
    updateState.TransformAboveDataSpace, updateState.DataSpace, ...
    updateState.TransformUnderDataSpace, vertexDataArrow));
end

function vertexDataArrow = dataSpaceScaledArrowVertices(updateState, thetadata, rdata, rlimits, scaleFactor, arrowAngle)
% Compute arrow head vertices to be a proportion of the PolarAxes radius
% defined by scaleFactor.

rdataMagnitude = rdata-rlimits(1);

% Define constants to for arrow head size.
arrowMagnitude = diff(rlimits)*scaleFactor; % arrowhead's central magnitude along radius

% Compute arrow head vertices.
arrowLegLength = arrowMagnitude / cos(arrowAngle);
arrowLegStartRadius = sqrt(arrowLegLength.^2 + rdataMagnitude.^2 - 2*rdataMagnitude.*arrowMagnitude);
arrowLegThetaOffset = acos((rdataMagnitude - arrowMagnitude)./arrowLegStartRadius);
arrowLegStartRadius = arrowLegStartRadius+rlimits(1);

% Create vertex triplets for the arrow heads.
arrowT = nan(1,numel(thetadata)*3);
arrowT(1:3:end) = thetadata-arrowLegThetaOffset;
arrowT(2:3:end) = thetadata;
arrowT(3:3:end) = thetadata+arrowLegThetaOffset;

arrowR = nan(1,numel(thetadata)*3);
arrowR(1:3:end) = arrowLegStartRadius;
arrowR(2:3:end) = rdata;
arrowR(3:3:end) = arrowLegStartRadius;

% Convert vertices to world coordinates.
iterArrow = matlab.graphics.axis.dataspace.XYZPointsIterator;
iterArrow.XData = arrowT;
iterArrow.YData = arrowR;
vertexDataArrow = updateState.DataSpace.TransformPoints(updateState.TransformUnderDataSpace, iterArrow);
end