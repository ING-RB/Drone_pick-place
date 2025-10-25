classdef ClearAllAction < internal.matlab.variableeditor.VEAction
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'ClearAllAction'
    end

    methods
        function this = ClearAllAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.ClearAllAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.ClearAll;
        end
        
        function ClearAll(~, clearAllInfo)
            varName = clearAllInfo.actionInfo.varName;
            
            channel = strcat('/VE/filter',clearAllInfo.docID);
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);

            
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            tws = mgr.Workspaces('filterWorkspace');
            tws.deselectAll(varName);
            
        end
        
         function  UpdateActionState(this)
            this.Enabled = true;
        end
    end
end

