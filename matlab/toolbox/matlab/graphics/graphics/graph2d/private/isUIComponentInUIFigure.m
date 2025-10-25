function ret = isUIComponentInUIFigure(hObj)
% This undocumented function may be removed in a future release.
%
% Returns true if the object is a uicomponent in a web figure

%   Copyright 2020-2024 The MathWorks, Inc.

hFig = ancestor(hObj,'figure');
ret = matlab.ui.internal.isUIFigure(hFig) && hObj ~= hFig && ...
        isa(hObj,'matlab.ui.control.WebComponent');



