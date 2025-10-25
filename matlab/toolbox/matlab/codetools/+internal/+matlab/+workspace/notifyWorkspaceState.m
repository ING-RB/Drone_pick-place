% This function is for internal use only and will change in a future
% release.  Do not use this function.

% Copyright 2018 The MathWorks, Inc.

function notifyWorkspaceState(state)
    % Notifies the Workspace Browser with the current simulation state
    com.mathworks.mlwidgets.workspace.MatlabWorkspaceListener.setSimulationRunning(state);
end
