classdef CustomContextMenuAction < internal.matlab.variableeditor.VEAction
    % CustomContextMenuAction
    % Action class that handles execution of user authored context menu
    % actions in the Variable Editor.

    % Copyright 2021 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'CustomContextMenuAction';
    end
    
    properties
        Manager;
    end
    
    methods
        function this = CustomContextMenuAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.CustomContextMenuAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.ExecuteAction;
            this.Manager = manager;
        end
        
        function ExecuteAction(~,~)
        end
        
        function  UpdateActionState(~)
        end
        
        function delete(~)
        end
    end
end