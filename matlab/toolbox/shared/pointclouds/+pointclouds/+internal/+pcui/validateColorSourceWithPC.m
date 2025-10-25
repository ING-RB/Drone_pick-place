function validateColorSourceWithPC(colorSource, ptCloud)

colorSource = string(lower(colorSource));


switch colorSource
    case "intensity"

        if isempty(ptCloud.Intensity)
            error(message("vision:pointcloud:IntensityColorSourceError"));
        end

    case "color"

        if isempty(ptCloud.Color)
            error(message("vision:pointcloud:ColorPropColorSourceError"));
        end

    case "row"

        if ismatrix(ptCloud.Location)
            error(message("vision:pointcloud:RowColColorSourceError", getString(message("vision:pointcloud:Row"))));
        end

    case "column"

        if ismatrix(ptCloud.Location)
            error(message("vision:pointcloud:RowColColorSourceError", getString(message("vision:pointcloud:Column"))));
        end
end

end