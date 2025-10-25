function addKeyListeners(fig)
%

%   Copyright 2020-2021 The MathWorks, Inc.

% This function is called whenever an axes in the figure enters a mode. If
% this is the first axes in the figure to enter a mode, add the relevant
% keypress, keyrelease, and property change listeners to make keyboard
% interactions work. 

% If the property to store the keyboard listeners does not exist, create
% it.
if(~isprop(fig, 'KeyboardInteractionListeners'))
    prop = addprop(fig, 'KeyboardInteractionListeners');
    prop.Hidden = true;
    prop.Transient = true;
end

% If the keyboard listeners already exist, there's nothing to do. So
% return.
if(~isempty(fig.KeyboardInteractionListeners))
    return;
end

import matlab.graphics.interaction.keyboardinteraction.modeKeyPressFcn;
import matlab.graphics.interaction.keyboardinteraction.modeKeyReleaseFcn;
import matlab.graphics.interaction.keyboardinteraction.keyboardUndoRedoFcn;

kp = event.listener(fig, 'KeyPress', @(fig, e) modeKeyPressFcn(fig, e));
kr = event.listener(fig, 'KeyRelease', @(fig, e) modeKeyReleaseFcn(fig));
ca = event.proplistener(fig, findprop(fig, 'CurrentAxes'), 'PostSet', ...
    @(~,~)keyboardUndoRedoFcn(fig));

fig.KeyboardInteractionListeners = [kp, kr, ca];

end
