function h = colormapheight()
% This undocumented function may be removed in a future release.

%COLORMAPHEIGHT determine color map height.
%   h = colormapheight(m) returns a nonnegative scalar integer h used
%   by color map functions to set the height of a color map.

%   Copyright 2024 The MathWorks, Inc.

cf = groot().CurrentFigure;
if isempty(cf)
    h = height(get(groot,'DefaultFigureColormap'));
else
    h = height(cf.Colormap);
end
