function customAxesInteraction(hAx)
%CUSTOMAXINTERACTION sets custom axes toolbar and defualt interactions
%
% CUSTOMAXINTERACTION(hAx) sets a custom axes toolbar for hAx supporting
% 'zoomin','zoomout','restoreview' and 'pan' toolbar buttons. It also culls
% default inreactivity to zoom in and zoom out. Additionally, it disables
% axes toolbar and default interactivity in all other axes' in the current
% figure.

% Copyright 2019 The MathWorks, Inc.

if ~isvalid(hAx)
    return
end

% Set custom axes toolbar with 'zoomin','zoomout','restoreview' and 'pan'
axtoolbar(hAx,{'zoomin','zoomout','restoreview','pan'});
hAx.Toolbar.Visible = 'on';

% Set default intercations to only zoom and rotate(3D)
enableDefaultInteractivity(hAx);
hAx.Interactions = zoomInteraction;

% Get the handle to parent figure
hFig = ancestor(hAx, 'figure');

% Get handles to sibling axes' of hAx
axesHandles = findall(hFig, 'Type', 'axes');
axesHandles = axesHandles(axesHandles ~= hAx);

% Disable axes toolbar and default interactions on sibling axes'
set(axesHandles, 'Toolbar', []);
set(axesHandles, 'Interactions', []);
for idx = 1:length(axesHandles)
    disableDefaultInteractivity(axesHandles(idx));
end

% In Java based figures, toolbar button modes are figure-wide and not per
% axes. Explicitly disable zoom and pan from all the axes.
% NOTE: We only disable zoom and pan as the main axes hAx only has zoom
% and pan buttons, rest of the were remooved above 
if ~matlab.graphics.interaction.internal.isWebAxes(hAx)
    z = zoom(hFig);
    z.setAllowAxesZoom(axesHandles,false);

    p = pan(hFig);
    p.setAllowAxesPan(axesHandles,false);
end

end
