classdef ThemeColorUtil
%This function is for internal use only. It may be removed in the future.

%ThemeColorUtil Provides utility for using themed color

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        %Red Semantic variable for red used in RGB axis color
        Red = "--mw-graphics-colorSpace-rgb-red"

        %Green Semantic variable for green used in RGB axis color
        Green = "--mw-graphics-colorSpace-rgb-green"

        %Blue Semantic variable for blue used in RGB axis color
        Blue = "--mw-graphics-colorSpace-rgb-blue"

        %RigidBodyCollisionGreen Semantic variable for green used to represent
        %rigidbody collision bodies
        RigidBodyCollisionGreen = "--mw-graphics-colorOrder-5-primary"

        %JointAxisYellow Semantic variable for yellow used to represent joint
        %axis color
        JointAxisYellow = "--mw-graphics-colorOrder-8-primary"

        %MaxContrast Black in light theme, white in dark theme
        MaxContrast = "--mw-color-primary"
    end

    methods (Static)
        function setThemeProperty(graphicalObject, propertyName, semanticVar)
        %setThemeProperty Set a theme property in graphical object to semantic variable
            matlab.graphics.internal.themes.specifyThemePropertyMappings(graphicalObject, propertyName, semanticVar);
        end

        function semanticVar = getThemeProperty(graphicalObject, propertyName)
        %getThemeProperty Get a theme property in graphical object
            semanticVar = matlab.graphics.internal.themes.getThemePropertyMapping(graphicalObject, propertyName);
        end
    end
end
