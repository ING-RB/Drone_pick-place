function icon = getLegendGraphic(obj, fontsize)
%

%   Copyright 2023 The MathWorks, Inc.

    icon = matlab.graphics.primitive.world.Group;

    face = matlab.graphics.primitive.world.TriangleStrip( ...
        Parent = icon, ...
        VertexData = single([0 0 1 1; 0 1 0 1; 0 0 0 0]), ...
        StripData = uint32([1 5]));
    color = obj.FaceColor_I;
    if ~isequal(color, "none")
        color = [color obj.FaceAlpha_I];
    end
    hgfilter('RGBAColorToGeometryPrimitive', face, color);
    linewidth = min(obj.LineWidth_I,fontsize/2);

    edge = matlab.graphics.primitive.world.LineLoop( ...
        Parent = icon, ...
        AlignVertexCenters = 'on', ...
        LineWidth = linewidth, ...
        VertexData = single([0 0 1 1; 0 1 1 0;0 0 0 0]), ...
        StripData = uint32([1 5]));

    hgfilter('RGBAColorToGeometryPrimitive', edge, obj.EdgeColor_I);
    hgfilter('LineStyleToPrimLineStyle', edge, obj.LineStyle_I);
end
