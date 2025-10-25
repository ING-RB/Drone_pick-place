function graphic = getIconForSurfacePlots(hObj, varargin)
%

%   Copyright 2015-2024 The MathWorks, Inc.

graphic=matlab.graphics.primitive.world.Group;

% the area
if ~strcmp(hObj.FaceColor, 'none')
    iconFace = matlab.graphics.primitive.world.Quadrilateral;
    iconFace.Parent = graphic;
    iconFace.VertexData = single([0 1 1 0; 0 0 1 1; 0 0 0 0]);
    % iconFace.StripData = uint32([1 5]);

    if isequal(hObj.FaceColor,'flat') || isequal(hObj.FaceColor,'interp')
        if strcmp(hObj.Faces.ColorBinding, 'none')
            iconFace.Visible='off';
        else
            iconFace.ColorBinding='interpolated';
            iconFace.ColorData=single([0 0 1 1]);
            iconFace.ColorType='colormapped';
            iconFace.Texture=hObj.Faces.Texture;
        end
    else
        hgfilter('RGBAColorToGeometryPrimitive', iconFace, hObj.FaceColor);
    end
end

% the edge
if ~strcmp(hObj.LineStyle,'none')
    iconEdge = matlab.graphics.primitive.world.LineStrip;
    iconEdge.Parent = graphic;
    iconEdge.VertexData = single([0 1 .5 .5;.5 .5 0 1;0 0 0 0]);
    iconEdge.StripData = uint32([1 3 5]);

    if isequal(hObj.EdgeColor,'flat') || isequal(hObj.EdgeColor,'interp')
        if strcmp(hObj.Edge.ColorBinding, 'none')
            iconEdge.Visible='off';
        else
            iconEdge.ColorBinding='interpolated';
            iconEdge.ColorData=single([0.5 0.5 0 1]);
            iconEdge.ColorType='colormapped';
            iconEdge.Texture=hObj.Edge.Texture;
        end
    else
        hgfilter('RGBAColorToGeometryPrimitive', iconEdge, hObj.EdgeColor);
    end

    % edge LineStyle
    hgfilter('LineStyleToPrimLineStyle', iconEdge, hObj.LineStyle);
    
    % line width
    iconEdge.LineWidth = hObj.LineWidth;
end

% the marker
if ~strcmp(hObj.Marker,'none')
    iconMarker = copyobj(hObj.MarkerHandle, graphic);
    iconMarker.Internal = false; % just for our test files
    iconMarker.VertexData = single([.5;.5;0]);
    if size(iconMarker.EdgeColorData,2) > 1
        iconMarker.EdgeColorData = iconMarker.EdgeColorData(:,1);
    end
    if size(iconMarker.FaceColorData,2) > 1
        iconMarker.FaceColorData = iconMarker.FaceColorData(:,1);
    end
end
