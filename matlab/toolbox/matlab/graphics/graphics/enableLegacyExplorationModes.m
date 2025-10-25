function enableLegacyExplorationModes(fig)
%ENABLELEGACYEXPLORATIONMODES enables exploration modes
% 
% enableLegacyExplorationModes(fig) will switch pan, zoom, rotate3d
% and brush to using legacy modes.
%
% Interaction modes in figures created using the UIFIGURE function may
% behave differently than in figures created using the FIGURE function. To
% access the functionality of figures created using the FIGURE function,
% call enableLegacyExplorationModes. If you call
% enableLegacyExplorationModes, then the performance of interactions may
% be impacted.

%   Copyright 2019-2025 The MathWorks, Inc.

if ~isscalar(fig) || ~isa(fig,'matlab.ui.Figure') || ~isvalid(fig)
    error(message('MATLAB:graphics:interaction:ScalarFigureOnly'));
elseif ~matlab.ui.internal.isUIFigure(fig)
    % no-op for desktop figures
    return;
end

% Create dynamic property on figure to store state of legacy modes
if ~isprop(fig,'UseLegacyExplorationModes')
    p = addprop(fig,'UseLegacyExplorationModes');
    p.Hidden = true;
elseif fig.UseLegacyExplorationModes
    return; % Legacy mode already on
end
fig.UseLegacyExplorationModes = true;

axs = findall(fig,'Type','axes');

if findManualToolbars(axs)
    error(message('MATLAB:graphics:interaction:EnableLegacyExplorationModesToolbarFound'));
end

% Disable modes for axes
for i = 1:numel(axs)
    axs(i).InteractionContainer.CurrentMode = 'none';
    if ~matlab.internal.feature('PersistentAxesToolbar')
        tb = axs(i).Toolbar_I;
        if ~isempty(tb)
            tb.resetInteractions();
        end
    end
end


function ret = findManualToolbars(axs)
ret = false;
for i = 1:numel(axs)
    if strcmp(axs(i).ToolbarMode,'manual')
        ret = true;
        return
    end 
end
