function colorName = getColorProperty(obj, prop)
% getColorProperty  Return the theme property mapping 
%
% Given a graphics object(obj), and property name(prop), getColorProperty
% returns the themeable color value.
%
%   colorName = getColorProperty(lineObject,"Color")
%   colorName = getColorProperty(patchObject,"FaceColor")
%
% getColorProperty accepts an array of objects and returns the color name
% for each object.

% Copyright 2023 The MathWorks, Inc.

arguments
    obj (:,:)
    prop (1,1) string
end

colorName = repmat("",size(obj));
for k = 1:length(obj(:))
    colorName(k) = matlab.graphics.internal.themes.getThemePropertyMapping(obj(k), prop);
end
end