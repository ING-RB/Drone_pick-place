function setColorProperty(objectsToSet, propertiesToSet, colorValue)
% setColorProperty  Set the color-based property of a graphics object(s) to
% an RGB value or a themeable semantic color variable
%
% Given a graphics object and color-based property names, setColorProperty
% assigns the specified color to the property of the object.
%
%   setColorProperty(lineObject,"Color","--mw-graphics-colorOrder-1-primary")
%   setColorProperty(patchObject,["FaceColor","EdgeColor"],"--mw-graphics-colorOrder-2-primary")
%   setColorProperty(patchObject,["FaceColor","EdgeColor"],[1 0 0])
%   setColorProperty(patchObject,["FaceColor","EdgeColor"],"r")
%
% setColorProperty also accepts an array of graphic objects and sets the
% Color on all specified properties of each object

% Copyright 2023 The MathWorks, Inc.

arguments
    objectsToSet
    propertiesToSet (1,:) string
    colorValue
end

% Check if colorValue represents semantic colors supporting theming.
setSemanticColor = (isstring(colorValue) || ischar(colorValue)) && startsWith(colorValue,"--mw");

% Validate color if not semantic color starting with "--mw"
if ~setSemanticColor
    try
        if isnumeric(colorValue) && isequal(size(colorValue),[1 4])
            colorValueAlpha = colorValue(4);
            colorValue = colorValue(1:3);
        else
            colorValueAlpha = [];
        end
        colorValue = validatecolor(colorValue);
        if ~isempty(colorValueAlpha)
            colorValue = [colorValue,colorValueAlpha];
        end
    catch ME
        % Switch to Semantic Color if validatecolor errors out and
        % colorValue is string
        if (isstring(colorValue) || ischar(colorValue))
            setSemanticColor = true;
        else
            throw(ME)
        end
    end
end

for objIdx = 1:numel(objectsToSet)
    obj = objectsToSet(objIdx);
    for propIdx = 1:numel(propertiesToSet)
        prop = propertiesToSet(propIdx);
        if ~setSemanticColor || strcmp(colorValue,'none')
            % Set color property to RGB value. Toggles mode to manual. Does
            % not support theming.
            set(obj,prop,colorValue);
        else
            % Use internal function to set semantic color variable to
            % property. This keeps mode as auto and supports theming.
            matlab.graphics.internal.themes.specifyThemePropertyMappings(obj,prop,colorValue);
        end
    end
end
end