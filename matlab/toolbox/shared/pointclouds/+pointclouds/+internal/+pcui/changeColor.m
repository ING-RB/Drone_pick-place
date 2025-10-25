function changeColor(currentAxes, colorBy)
% This function changes the color value for the points based on the color
% map selection

% Copyright 2018-2023 The MathWorks, Inc.

colorBy = string(lower(colorBy));
plotHandles = findall(currentAxes,'Tag', 'pcviewer');

for i = 1:numel(plotHandles)
    ptCloud = pointclouds.internal.pcui.utils.getAppData(plotHandles(i), 'PointCloud');
        
    if ~isempty(ptCloud)
        isOrganized = ~ismatrix(ptCloud.Location);

        count = ptCloud.Count;
        cData = [];
        
        switch colorBy
            case "x"
                
                cData = ptCloud.Location(1:count)';
                
            case "y"
                
                cData = ptCloud.Location(count+1:count*2)';
                
            case "z"
                
                cData = ptCloud.Location(count*2+1:end)';
                
            case "color"
                % The color data is stored in the color property of the
                % point cloud or in the ColorData property of the plot if
                % the user defines the color.
                colorValue = im2double(ptCloud.Color);
                if isempty(colorValue)
                    cData = pointclouds.internal.pcui.utils.getAppData(plotHandles(i), 'ColorData');
                else
                    cData = zeros(count,3);
                    cData(:,1) = colorValue(1:count);
                    cData(:,2) = colorValue(count+1:count*2);
                    cData(:,3) = colorValue(count*2+1:end);
                end
                
            case "intensity"
                
                cData = ptCloud.Intensity(:);
                
            case "row"
                % check if ptCloud is not empty and is organized
                if isOrganized
                    [nRows, nCols, ~] = size(ptCloud.Location);
                    rowData = (1:nRows)';
                    cData = repmat(rowData, [1,nCols]);
                    cData = cData(:);
                end
                
            case "column"
                % check if ptCloud is not empty and is organized
                if isOrganized
                    [nRows, nCols, ~] = size(ptCloud.Location);
                    colData = (1:nCols);
                    cData = repmat(colData, [nRows, 1]);
                    cData = cData(:);
                end
                
            case "range"
                
                cData = ptCloud.RangeData(1:count)';
                
            case "azimuth"
                
                cData = ptCloud.RangeData(count*2+1:end)';
                
            case "elevation"
                
                cData = ptCloud.RangeData(count+1:count*2)';
                
            case "userspecified"
                
                cData = pointclouds.internal.pcui.utils.getAppData(plotHandles(i), 'ColorData');                
                
            case "magentagreen"
                
                cData = pointclouds.internal.pcui.utils.getAppData(plotHandles(i), 'MagGrColor');
        end
        
        if ~isempty(cData)
            plotHandles(i).CData = cData;
        end

    end
    
end
end