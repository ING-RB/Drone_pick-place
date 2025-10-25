function setAxesPanMotion(hThis,hAx,style)
%

%   Copyright 2013-2019 The MathWorks, Inc.

if matlab.ui.internal.isUIFigure(hThis.FigureHandle)
    enableLegacyExplorationModes(hThis.FigureHandle);
end

% Motion passes through to Constraint3D
cons = matlab.graphics.interaction.internal.constraintConvert2DTo3D(style);
setAxesPanConstraint(hThis,hAx,cons);
