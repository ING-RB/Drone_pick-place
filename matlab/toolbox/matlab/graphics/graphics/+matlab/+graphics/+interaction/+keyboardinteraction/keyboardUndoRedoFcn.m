function keyboardUndoRedoFcn(fig)
%

%   Copyright 2020-2024 The MathWorks, Inc.

% The mode undo/redo keyboard function fetches the old state from the
% figure's appdata, gets the new state, and adds them to the figure's
% undo/redo stack. 

old_state = getappdata(fig, 'AxesStateBeforeKeyPress');

% If the appdata doesn't exist, nothing to do, so return
if(isempty(old_state) || ~ishandle(old_state.Axes))
    return;
end

% Remove the appdata from the figure to clean up
rmappdata(fig, 'AxesStateBeforeKeyPress');

ax = old_state.Axes;
old_xlim = old_state.XLim;
old_ylim = old_state.YLim;
old_zlim = old_state.ZLim;
old_view = old_state.View;

new_xlim = ax.XLim;
new_ylim = ax.YLim;
new_zlim = ax.ZLim;
new_view = ax.View;

% Get the axes proxy to protect against axes deletion
axProxy = plotedit({'getProxyValueFromHandle', ax});

% Add to the figure's undo/ redo stack 
cmd.Name = '';

cmd.Function = @changeAxesState;
cmd.Varargin = {fig, axProxy, new_xlim, new_ylim, new_zlim, new_view};

cmd.InverseFunction = @changeAxesState;
cmd.InverseVarargin = {fig, axProxy, old_xlim, old_ylim, old_zlim, old_view};

uiundo(fig, 'function', cmd);

end

function changeAxesState(fig, axProxy, xlim, ylim, zlim, view)

ax = plotedit({'getHandleFromProxyValue', fig, axProxy});

if(~ishghandle(ax))
    return;
end

ax.XLim = xlim;
ax.YLim = ylim;
ax.ZLim = zlim;
ax.View = view;

end
