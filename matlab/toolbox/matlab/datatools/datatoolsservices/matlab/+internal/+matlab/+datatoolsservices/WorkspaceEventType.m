classdef WorkspaceEventType < uint32
    % This class is unsupported and might change or be removed without notice in
    % a future version.
    
    % A class defining MATLAB Workspace event types sent by the
    % WorkspaceListener class.
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    enumeration
        % Event generated when variables are modified in the workspace
        VARIABLE_CHANGED (1)
        
        % Event generated when variables are deleted from the workspace
        VARIABLE_DELETED (2)
        
        % Event generated when the workspace is cleared
        WORKSPACE_CLEARED (3)
        
        % Event generated when a breakpoint is hit, causing the workspace to
        % change
        WORKSPACE_CHANGED (4)
        
        % Event generated when the user changes workspace when debugging, by
        % using dbup/dbdown.
        CHANGE_CURR_WORKSPACE (5)

        % This is not a MVM event like the others, but is sent from the CPP
        % layer when variables are added when a MVM VARIABLE_CHANGED event is
        % handled.
        VARIABLE_ADDED (6)

        % Event generated when the user changes the numeric format
        NUMERIC_FORMAT_CHANGED (7)
        
        % Undefined event type
        UNDEFINED (8)
    end
end
