classdef SelectAllAction < internal.matlab.legacyvariableeditor.VEAction
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'SelectAllAction'
    end
    
    properties
        Manager;
    end
    
    methods
        function this = SelectAllAction(props, manager)
            props.ID = internal.matlab.legacyvariableeditor.Actions.SelectAllAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.legacyvariableeditor.VEAction(props, manager);
            this.Callback = @this.SelectAll;
            this.Manager = manager;
            
        end
        
        function SelectAll(~, selectAllInfo)
            varName = selectAllInfo.actionInfo.varName;
            
            channel = strcat('/VE/filter',selectAllInfo.docID);
            mgr = internal.matlab.legacyvariableeditor.peer.PeerManagerFactory.createManager(channel, false);

            
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            tws = mgr.Workspaces('filterWorkspace');
            tws.selectAll(varName);
            
        end
        
         function  UpdateActionState(this)
            this.Enabled = true;
        end
    end
end

