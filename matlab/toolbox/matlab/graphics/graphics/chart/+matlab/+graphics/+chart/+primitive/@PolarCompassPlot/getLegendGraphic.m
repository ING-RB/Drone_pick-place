function [legGraphic, chartPrefersToBeReversed] = getLegendGraphic(obj, fontsize)
% getLegendGraphic for PolarCompass

%   Copyright 2024 The MathWorks, Inc.

legGraphic=matlab.graphics.primitive.world.Group;
chartPrefersToBeReversed = false;

% Create line strips for the line part of the icon and the arrow head part
% of the icon. Use separate linestrips because linestyle is only applied to
% the line part.
mainLine = newLineStrip(legGraphic, obj, fontsize);
mainLine.LineStyle = obj.Edge.LineStyle;
arrLine = newLineStrip(legGraphic, obj, fontsize);

% Compute and apply vertex data.
maxXPos = 0.8;
arrowMag = fontsize/50;
arrowLegX = max(0,maxXPos - arrowMag);
arrowYOffset = 0.10;
arrowHeadVerts=[    arrowLegX  maxXPos       arrowLegX  maxXPos;...
    arrowYOffset      0.5  1-arrowYOffset      0.5;...
    0        0               0        0];
mainVerts=[  0 maxXPos;...
    0.5     0.5;...
    0       0];

mainLine.VertexData = single(mainVerts);
mainLine.StripData = uint32([1 3]);

arrLine.VertexData = single(arrowHeadVerts);
arrLine.StripData = uint32([1 5]);
end

function lh = newLineStrip(legGraphic, obj, fontsize)
% Shared helper so that both legend linestrips get the same style
% properties from the object.
maxLW = fontsize/2;
lh = matlab.graphics.primitive.world.LineStrip(...
    'Parent',legGraphic,...
    'ColorData', obj.Edge.ColorData,...
    'ColorBinding','object',...
    'LineJoin','miter',...
    'LineWidth',min(obj.Edge.LineWidth, maxLW));
end