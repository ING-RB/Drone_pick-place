function setAxes3DPanAndZoomStyle(hThis,hAx,ver3d)
%SETAXES3DPANANDZOOMSTYLE Summary of this function goes here
%   Detailed explanation goes here

%   Copyright 2015-2019 The MathWorks, Inc.

if matlab.ui.internal.isUIFigure(hThis.FigureHandle)
    enableLegacyExplorationModes(hThis.FigureHandle);
end

matlab.graphics.interaction.internal.setAxes3DPanAndZoomStyle(hThis.FigureHandle,hAx,ver3d);

