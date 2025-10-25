classdef RefreshWorkspaceAction < internal.matlab.variableeditor.VEAction
    % RefreshWorkspaceAction
    % Refreshes the current state of the WorkspaceBrowser
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'RefreshWorkspaceAction'
    end
    
    methods
        function this = RefreshWorkspaceAction(props, manager)
            props.ID = internal.matlab.workspace.actions.RefreshWorkspaceAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @()internal.matlab.desktop_workspacebrowser.DesktopWSBManager.refresh(true);
        end
        
        function UpdateActionState(~)
        end
    end
end

