function [currentAxes, hFigure] = setupAxesAndFigure(currentAxes)
% Return axes and figure

% Copyright 2018-2020 The MathWorks, Inc.

% pcshow is blacklisted i.e. use MGG in MOL and not web figures, this
% is because rendering pcshow in web figures is too slow.
res = matlab.ui.internal.webGraphicsStateManager; %#ok<NASGU>

% Plot to the specified axis, or create a new one
currentAxes = newplot(currentAxes);

% Get the current figure handle
hFigure = ancestor(currentAxes,'figure');

% Check the renderer
% JSD_OGL_REMOVAL
% after OpenGL Removal, setting renderer property becomes no-op
if ~feature('webui') && strcmpi(hFigure.Renderer, 'painters')
    error(message('vision:pointcloud:badRenderer'));
end

end