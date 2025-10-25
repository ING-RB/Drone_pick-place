function colorSource = getColorSourceString(colorBy)

colorByText = @(x)getString(message(['vision:pointcloud:' x]));

switch colorBy
    case colorByText('X')

        colorSource = "x";
    case colorByText('Y')

        colorSource = "y";

    case colorByText('Z')

        colorSource = "z";

    case colorByText('RGBColor')

        colorSource = "color";

    case colorByText('Intensity')

        colorSource = "intensity";

    case colorByText('Row')

        colorSource = "row";

    case colorByText('Column')

        colorSource = "column";

    case colorByText('Range')

        colorSource = "range";

    case colorByText('Azimuth')

        colorSource = "azimuth";

    case colorByText('Elevation')

        colorSource = "elevation";

    case colorByText('UserSpecColor')

        colorSource = "userspecified";

    case colorByText('MagentaGreen')

        colorSource = "magentagreen";
end


end