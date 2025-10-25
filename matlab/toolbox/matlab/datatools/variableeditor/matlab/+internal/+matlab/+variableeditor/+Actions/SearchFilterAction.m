classdef SearchFilterAction < internal.matlab.variableeditor.VEAction
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'SearchFilterAction'
    end
    
    properties
        Manager;
    end
    
    methods
        function this = SearchFilterAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.SearchFilterAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.SearchFilter;
            this.Manager = manager;
        end
        
        function SearchFilter(~, filtInfo)
            varName = filtInfo.actionInfo.varName;
            searchTextObj = filtInfo.actionInfo.searchText;
            searchText = searchTextObj.currentContent;
            
            channel = strcat('/VE/filter',filtInfo.docID);
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
            
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            tws = mgr.Workspaces('filterWorkspace');           
            
            if isempty(searchText)
                tws.clearSearch(varName);
            else
                tws.searchVariable(varName, searchText);
            end           
            
            internal.matlab.variableeditor.peer.HeaderMenuStateHandler.updateHeaderMenu(mgr, varName);            
        end
        
         function  UpdateActionState(this)
            this.Enabled = true;
        end
    end
end

