
function [vertexData, textPosition, regionStr] = transformFigureCoordsToVertexData(this, figRegionCoords, dataDragStart, dataDragEnd , camRegionCoords)
% This internal helper function may change in a future release.

% transformFigureCoordsToVertexData gets the figure coordinates of brushing ROI for drawing ROI
% into the overlay camera in normalized figure units.

% transformFigureCoordsToVertexData returns the vertexData, textPosition
% and regionStr

%  Copyright 2020 The MathWorks, Inc.

vertexData = zeros([3 size(camRegionCoords,2)]);
panelRegionCoords = figRegionCoords;
hPanel = ancestor(this.Axes, 'matlab.ui.container.Container','node');
hasPanelParent = ~isempty(hPanel) && ~ isa(hPanel,'matlab.ui.Figure');
if hasPanelParent
    uipanelpos = getpixelposition(hPanel,true);
end

% Convert to normalized units of the axes parent
for k=1:size(figRegionCoords,2)
    if hasPanelParent
        panelRegionCoords(:,k) = figRegionCoords(:,k)-uipanelpos(1:2)';
        tmp = hgconvertunits(this.Figure,[panelRegionCoords(:,k)' 0 0],'pixels','normalized',hPanel);
        vertexData(1:2,k) = tmp(1:2);
    else
        tmp = hgconvertunits(this.Figure,[figRegionCoords(:,k)' 0 0],'pixels','normalized',this.Figure);
        vertexData(1:2,k) = tmp(1:2);
    end
    
end
vertexData(1:2,end+1) = vertexData(1:2,1);

% Position the text at xMin, yMin of the ROI
textPosition = single([min(vertexData(1:2,:),[],2);0]);

% if the rulers are non numeric, show the corresponding values in the ROI
[xStart,yStart] = matlab.graphics.internal.makeNonNumeric(this.Axes,dataDragStart(1,1),dataDragStart(1,2));
[xEnd,yEnd] = matlab.graphics.internal.makeNonNumeric(this.Axes,dataDragEnd(1,1),dataDragEnd(1,2));

regionStrX = formatRegionData(xStart,xEnd,'X');
regionStrY = formatRegionData(yStart,yEnd,'Y');
regionStr  = {regionStrY;regionStrX};
end


function output = formatRegionData(startPoint,endPoint,coordLabel)
if ~isnumeric(startPoint)
    startPoint = char(startPoint);
    endPoint = char(endPoint);
    output = sprintf(['%s: %s ', getString(message('MATLAB:datamanager:draw:To')), ' %s'],coordLabel,startPoint,endPoint);
else
    output = sprintf(['%s: %0.3g ', getString(message('MATLAB:datamanager:draw:To')), ' %0.3g'],coordLabel,startPoint, endPoint);
end
end
