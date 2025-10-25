function setColorMapData(currentAxes, colorSource)
%setColorMapData set current colormap selection to PCUserData

% Copyright 2018-2019 The MathWorks, Inc.

plotHandles = findall(currentAxes,'Tag', 'pcviewer');
udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');

if colorSource == "auto"
    if ~isempty(plotHandles)
        ptCloud    = pointclouds.internal.pcui.utils.getAppData(plotHandles(1), 'PointCloud');
        colorData  = pointclouds.internal.pcui.utils.getAppData(plotHandles(1), 'ColorData');
        magGrColor = pointclouds.internal.pcui.utils.getAppData(plotHandles(1), 'MagGrColor');
        
        if ~isempty(ptCloud)
            if ~isempty(magGrColor)
                udata.colorMapData = "magentagreen";        
            elseif ~isempty(ptCloud.Color)
                udata.colorMapData = "color";          
            elseif ~isempty(colorData)
                udata.colorMapData = "userspecified";            
            else
                udata.colorMapData = "z";
            end
        else
            udata.colorMapData = [];
        end
    else
        udata.colorMapData = [];
    end
else
    udata.colorMapData = colorSource;
end

pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);

end
