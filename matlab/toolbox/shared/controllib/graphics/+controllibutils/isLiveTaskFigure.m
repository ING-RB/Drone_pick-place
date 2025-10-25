function out = isLiveTaskFigure(h)
% isLiveTaskFigure 
%
% value = controllibutils.isLiveTaskFigure(h)
% 
% returns true if h is uifigure part of a Live Editor Task

%   Copyright 2019-2020 The MathWorks, Inc.

out = false;
isUIFigure = matlab.ui.internal.isUIFigure(h);
if isUIFigure
    out = strcmp(h.Tag,'LiveEditorTaskFigure');
end
