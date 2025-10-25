function updateColorContextMenu(hFigure)
% This method updates the color map value context menu

% Copyright 2018 The MathWorks, Inc.

currentAxes = hFigure.CurrentAxes;

udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');
if ~isfield(udata, 'ColorContextMenu')
    return;
end
urcolor = udata.ColorContextMenu;

urx = findall(urcolor,'tag','contextPCChangeColorByX');
ury = findall(urcolor,'tag','contextPCChangeColorByY');
urz = findall(urcolor,'tag','contextPCChangeColorByZ');
urrow = findall(urcolor,'tag','contextPCChangeColorByRow');
urcol = findall(urcolor,'tag','contextPCChangeColorByCol');
urrgb = findall(urcolor,'tag','contextPCChangeColorByRGB');
urintensity = findall(urcolor,'tag','contextPCChangeColorByIntensity');
urrange = findall(urcolor,'tag','contextPCChangeColorByRange');
urazimuth = findall(urcolor,'tag','contextPCChangeColorByAzimuth');
urelev = findall(urcolor,'tag','contextPCChangeColorByElevation');
uruserspec = findall(urcolor,'tag','contextPCChangeColorByUserSpecColor');
urmaggr = findall(urcolor,'tag','contextPCChangeColorByMagentaGreen');

plotHandles = findall(currentAxes,'Tag', 'pcviewer');

if ~isempty(plotHandles)
    
    rowColContextMenu = true;
    rgbContextMenu = true;
    intensityContextMenu = true;
    rangeContextMenu = true;
    userSpecContextMenu = true;
    magGrContextMenu = true;
    
    for i = 1:numel(plotHandles)
        ptCloud = pointclouds.internal.pcui.utils.getAppData(plotHandles(i), 'PointCloud');
        if isempty(ptCloud)
            urcolor.Visible = 'off';
            return;
        end
        colorData = pointclouds.internal.pcui.utils.getAppData(plotHandles(i), 'ColorData');
        magGrData = pointclouds.internal.pcui.utils.getAppData(plotHandles(i), 'MagGrColor');
        
        rowColContextMenu    = rowColContextMenu && (~isempty(ptCloud) && ~ismatrix(ptCloud.Location));
        rgbContextMenu       = rgbContextMenu && (~isempty(ptCloud)) && ~isempty(ptCloud.Color);
        intensityContextMenu = intensityContextMenu && (~isempty(ptCloud)) && ~isempty(ptCloud.Intensity);
        rangeContextMenu     = rangeContextMenu && (~isempty(ptCloud))  && ~isempty(ptCloud.RangeData);
        userSpecContextMenu  = userSpecContextMenu && ~isempty(colorData);
        magGrContextMenu     = magGrContextMenu && ~isempty(magGrData);
    end
    
    urcolor.Visible = 'on';
    urx.Visible = 'on';
    ury.Visible = 'on';
    urz.Visible = 'on';
    
    if rgbContextMenu
        urrgb.Visible = 'on';
    else
        urrgb.Visible = 'off';
    end
    
    if intensityContextMenu
        urintensity.Visible = 'on';
    else
        urintensity.Visible = 'off';
    end
    
    if rowColContextMenu
        urrow.Visible = 'on';
        urcol.Visible = 'on';
    else
        urrow.Visible = 'off';
        urcol.Visible = 'off';
    end
    
    if rangeContextMenu
        urrange.Visible = 'on';
        urazimuth.Visible = 'on';
        urelev.Visible = 'on';
    else
        urrange.Visible = 'off';
        urazimuth.Visible = 'off';
        urelev.Visible = 'off';
    end
    
    if userSpecContextMenu
        uruserspec.Visible = 'on';
    else
        uruserspec.Visible = 'off';
    end
    
    if magGrContextMenu
        urmaggr.Visible = 'on';
    else
        urmaggr.Visible = 'off';
    end
        
end
end