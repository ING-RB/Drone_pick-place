classdef AxesColorConstants
    %AxesColorConstants Constant color variable for performant usage
    %   These values are hard-coded. Whenever possible, use the theme
    %   property mapping or ThemeColorUtil in lieu of this approach, which
    %   is limited to hard-coded colors that are the same across themes.

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        RED = matlab.graphics.internal.themes.getAttributeValue(matlab.graphics.internal.themes.lightTheme, robotics.utils.internal.ThemeColorUtil.Red)

        GREEN = matlab.graphics.internal.themes.getAttributeValue(matlab.graphics.internal.themes.lightTheme, robotics.utils.internal.ThemeColorUtil.Green)

        BLUE = matlab.graphics.internal.themes.getAttributeValue(matlab.graphics.internal.themes.lightTheme, robotics.utils.internal.ThemeColorUtil.Blue)

        PINK = [0.8196 0.0157 0.5451] % Pink600
    end
end
