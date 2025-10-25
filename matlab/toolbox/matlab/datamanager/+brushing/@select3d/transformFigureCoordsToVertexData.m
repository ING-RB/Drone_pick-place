function vertexData = transformFigureCoordsToVertexData(this, figRegionCoords)
% This internal helper function may change in a future release.

% transformFigureCoordsToVertexData gets the figure coordinates of brushing ROI for drawing ROI
% into the overlay camera in normalized figure units.

% transformFigureCoordsToVertexData returns the vertexData

%  Copyright 2020 The MathWorks, Inc.

vertexData = zeros([3 size(figRegionCoords,2)]);
panelRegionCoords = figRegionCoords;
for k=1:size(figRegionCoords,2)
    
    hPanel = ancestor(this.Axes,'matlab.ui.container.Container','node');
    hasPanel = ~isempty(hPanel) && ~isa(hPanel,'matlab.ui.Figure');
    if hasPanel
        uipanelpos = getpixelposition(hPanel,true);
        panelRegionCoords(:,k) = figRegionCoords(:,k)-uipanelpos(1:2)';
        tmp = hgconvertunits(this.Figure,[panelRegionCoords(:,k)' 0 0],'pixels','normalized',hPanel);
        vertexData(1:2,k) = tmp(1:2);
    else
        tmp = hgconvertunits(this.Figure,[figRegionCoords(:,k)' 0 0],'pixels','normalized',this.Figure);
        vertexData(1:2,k) = tmp(1:2);
    end
end
vertexData(1:2,end+1) = vertexData(1:2,1);
end