function modeKeyPressFcn(fig, evd)
%

%   Copyright 2020 - 2022 The MathWorks, Inc.

% This keypress function passes the keyboard events from the figure to the
% current axes. If the current axes is in a mode, the callback pertaining
% to that mode is triggered. If the current axes is not in a mode, or if
% the mode did not consume the key event, then it no ops. 

ax = fig.CurrentAxes;

% If the current axes is not a cartesian axes, don't do anything
if(~isa(ax, 'matlab.graphics.axis.Axes'))
    return;
end

% Capture the axes state before the interaction for undo/redo
old_state = captureAxesOldState(ax);

mode = ax.InteractionContainer.CurrentMode;

import matlab.graphics.interaction.keyboardinteraction.panKeyPressFcn;
import matlab.graphics.interaction.keyboardinteraction.zoomKeyPressFcn;
import matlab.graphics.interaction.keyboardinteraction.rotateKeyPressFcn;
import matlab.graphics.interaction.keyboardinteraction.datatipKeyPressFcn;
import matlab.graphics.interaction.keyboardinteraction.brushKeyPressFcn;

switch mode
    case 'pan'
        keyconsumed = panKeyPressFcn(ax, evd);
    case 'rotate'
        keyconsumed = rotateKeyPressFcn(ax, evd);
    case {'zoom', 'zoomout'}
        keyconsumed = zoomKeyPressFcn(ax, evd);
    case 'datacursor'
        keyconsumed = datatipKeyPressFcn(ax, evd);
    case 'brush'
        keyconsumed = brushKeyPressFcn(ax, evd);
    otherwise
        keyconsumed = false;
end

if keyconsumed && ismember(mode,{'pan', 'zoom', 'zoomout', 'rotate'})
    
    storeOldState(fig, old_state);
end

end

function state = captureAxesOldState(ax)

state.Axes = ax;
state.XLim = ax.XLim;
state.YLim = ax.YLim;
state.ZLim = ax.ZLim;
state.View = ax.View;

end

function storeOldState(fig, state)

% Store the old state in the figure as an appdata only for the first
% keypress.

old_state = getappdata(fig, 'AxesStateBeforeKeyPress');

if(~isempty(old_state))
    return;
end

setappdata(fig, 'AxesStateBeforeKeyPress', state);

end
