classdef ClearAllAction < internal.matlab.legacyvariableeditor.VEAction
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'ClearAllAction'
    end
    
    properties
        Manager;
    end
    
    methods
        function this = ClearAllAction(props, manager)
            props.ID = internal.matlab.legacyvariableeditor.Actions.ClearAllAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.legacyvariableeditor.VEAction(props, manager);
            this.Callback = @this.ClearAll;
            this.Manager = manager;
            
        end
        
        function ClearAll(~, clearAllInfo)
            varName = clearAllInfo.actionInfo.varName;
            
            channel = strcat('/VE/filter',clearAllInfo.docID);
            mgr = internal.matlab.legacyvariableeditor.peer.PeerManagerFactory.createManager(channel, false);

            
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

