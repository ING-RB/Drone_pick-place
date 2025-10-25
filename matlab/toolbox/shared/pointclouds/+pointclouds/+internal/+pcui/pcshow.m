function pcshow(X, Y, Z, C, map, ptCloud, params)
% This class is an internal implementation of pcshow. It is used by pcshow
% and apps based on pcshow
% Copyright 2023 The MathWorks, Inc.
                                
currentAxes = params.Parent;
[currentAxes, hFigure] = pointclouds.internal.pcui.setupAxesAndFigure(currentAxes);

% Set the colormap
if ~isempty(map)
    colormap(hFigure, map);
end

% Set the colordata for storing
if isempty(C)
    C = Z;
    colorData = [];
else
    if isempty(ptCloud.Color) && isempty(ptCloud.Intensity)
        colorData = C;
    else
        % This means point cloud object holds the color information
        colorData = []; 
    end
end

markerSize = params.MarkerSize;
scatterObj = scatter3(currentAxes, X, Y, Z, markerSize, C, '.', 'Tag', 'pcviewer');

if ischar(C)
    % This is done to use a numeric value for color data
    colorData = scatterObj.CData;
end

pointclouds.internal.pcui.utils.setAppData(scatterObj, 'PointCloud', ptCloud);
pointclouds.internal.pcui.utils.setAppData(scatterObj, 'ColorData', colorData);

% Lower and upper limit of auto downsampling.
ptCloudThreshold = [1920*1080, 1e8]; 
params.PtCloudThreshold = ptCloudThreshold;

% Equal axis is required for cameratoolbar
axis(currentAxes, 'equal');

% Initialize point cloud viewer controls.
pointclouds.internal.pcui.initializePCSceneControl(hFigure, currentAxes,...
    scatterObj, params);

if nargout > 0
    ax = currentAxes;
    
    % Disable default interactions
    disableDefaultInteractivity(ax);
end

end
