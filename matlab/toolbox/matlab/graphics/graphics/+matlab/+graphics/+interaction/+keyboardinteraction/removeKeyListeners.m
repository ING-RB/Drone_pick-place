function removeKeyListeners(fig)
%

%   Copyright 2020 The MathWorks, Inc.

% This function is called whenever an axes in the figure exits a mode. If
% this is the last axes in the figure to exit a mode, the keyboard related
% listeners are removed from the figure

axes_list = findall(fig, 'Type', 'axes');

shouldRemoveListeners = true;

for i = 1:length(axes_list)
    % If any axes is in a mode, don't remove the key listeners
    if(~strcmp(axes_list(i).InteractionContainer.CurrentMode, 'none'))
        shouldRemoveListeners = false;
        break;
    end
end

if(~shouldRemoveListeners)
    return;
end

% Delete the listeners and set the property to empty
delete(fig.KeyboardInteractionListeners);
fig.KeyboardInteractionListeners = [];


end

