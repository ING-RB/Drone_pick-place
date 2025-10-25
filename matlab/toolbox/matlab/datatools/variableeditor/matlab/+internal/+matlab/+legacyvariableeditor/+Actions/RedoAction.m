classdef RedoAction < internal.matlab.legacyvariableeditor.VEAction
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'RedoAction'
    end
    
    properties
        Manager;
    end
    
    methods
        function this = RedoAction(props, manager)
            props.ID = internal.matlab.legacyvariableeditor.Actions.RedoAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.legacyvariableeditor.VEAction(props, manager);
            this.Callback = @this.Redo;
            this.Manager = manager;
            
        end
        
        function Redo(this, redoInfo)
            idx = arrayfun(@(x) isequal(x.DocID, redoInfo.docID), this.Manager.Documents);
            sh = this.Manager.Documents(idx).ViewModel.ActionStateHandler;
            
            if internal.matlab.legacyvariableeditor.peer.PeerUtils.isFilterTablesInLiveEditorOn()
                try
                    [tws, mgr] = internal.matlab.legacyvariableeditor.Actions.RedoAction.getFilteringWorkspace(redoInfo);
                    % If any command in the undoCommandArray is of type
                    % boundary, then clear cache on the filtering
                    % workspace.
                    isBoundary = false;
                    for i=1:length(sh.UndoCommandArray)
                        isBoundary = isBoundary || sh.isBoundaryCondition(sh.UndoCommandArray(i));
                    end
                    if isBoundary                
                        tws.updateTableAndResetCache(sh.DataModel.Data, redoInfo.docID);                
                    end
                    internal.matlab.legacyvariableeditor.peer.HeaderMenuStateHandler.updateHeaderMenuForRedo(mgr, tws, sh);
                catch 
                    % Ignore the exceptions
                end
            end
            
            CurrentRange = redoInfo.range;
            sh.isUndoRedoAction = true;
            
            sh.CommandArray = [sh.CommandArray, sh.UndoCommandArray(end)];
            index = sh.UndoCommandArray(end).Index;
            command = sh.UndoCommandArray(end).Command;
            
            % Set the IsFiltered Flag to none for the redo command
            % Model prop will be set by the executeCode method if needed
            sh.handleSortFilterIcon();
            
            sh.getCodegenCommands(index, command);
            sh.executeCode();
            internal.matlab.legacyvariableeditor.Actions.RedoAction.updateFilteredState(redoInfo, sh, index, command);
            sh.updateClientView(CurrentRange);
            sh.publishCode();
            
            % Removing this command from undo stack since we are going to redo it
            sh.UndoCommandArray(end) = [];
        end                  
        
        function  UpdateActionState(this)
            this.Enabled = true;
        end
    end
    
    methods(Static)        
        % TODO: Undo and redo have common code. Create a base class and
        % pull them out
        % returns if the command is of type that modifies the original
        % table. If so, the versions of the original table stored in
        % workspaces like filtering need to be updated (for now its only Clean)
       function originalTableModified = isCommandModifiedOriginalTable(commandtype)
            originalTableModified = strcmp(commandtype, 'Clean') || strcmp(commandtype, 'ConvertTo');                
       end
                      
       function [tws, mgr] = getFilteringWorkspace(redoInfo)
            channel = strcat('/VE/filter',redoInfo.docID);
            mgr = internal.matlab.legacyvariableeditor.peer.PeerManagerFactory.createManager(channel, false);
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            tws = mgr.Workspaces('filterWorkspace');
       end
       
       function updateFilteredState(redoInfo, sh, index, commandType)
            if internal.matlab.legacyvariableeditor.peer.PeerUtils.isFilterTablesInLiveEditorOn()                
                if internal.matlab.legacyvariableeditor.Actions.RedoAction.isCommandModifiedOriginalTable(commandType)
                    % update the original table stored in the filtered
                    % workspace
                    tws = internal.matlab.legacyvariableeditor.Actions.RedoAction.getFilteringWorkspace(redoInfo);
                    tws.updateOriginalTable(sh.DataModel.Data, sh.DataModel.Data.Properties.VariableNames{index}); 
                end
            end
       end
    end        
end

