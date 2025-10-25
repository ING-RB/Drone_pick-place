function colormapString = getColormapString(colormapArray)
%GETCOLORMAPSTRING Obtain the built-in colormap corresponding to the
%inputted array
%   There are several built-in predefined colormaps in MATLAB (e.g. parula,
%   copper, winter, autumn, etc.).  This function takes an array and
%   outputs the associated built-in predefined colormap.

% Copyright 2021 The MathWorks, Inc.

import internal.matlab.editorconverters.ColormapEditor

% Set default value
colormapString = 'parula';

predefinedColormaps = ColormapEditor.PREDEFINED_COLORMAPS;

% For each predefined colormap, compare with the inputted colormapArray
% and, if there is a match, assign the predefined colormap to
% colormapString.
for i = 1:length(predefinedColormaps)
    if isequal(colormapArray, feval(predefinedColormaps{i}))
        colormapString = predefinedColormaps{i};
        break;
    end
end
end

