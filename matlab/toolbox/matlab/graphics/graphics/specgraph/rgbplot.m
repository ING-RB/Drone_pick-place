function rgbplot(map)
%

%   Copyright 1984-2024 The MathWorks, Inc.

import matlab.graphics.internal.themes.specifyThemePropertyMappings
if width(map) ~= 3 || ~ismatrix(map)
    error(message('MATLAB:rgbplot:InvalidColormapMatrix'));
end
m = 1:height(map);
h = plot(m,map,'LineWidth',1);
specifyThemePropertyMappings(h(1),'Color','--mw-graphics-colorSpace-rgb-red')
specifyThemePropertyMappings(h(2),'Color','--mw-graphics-colorSpace-rgb-green')
specifyThemePropertyMappings(h(3),'Color','--mw-graphics-colorSpace-rgb-blue')