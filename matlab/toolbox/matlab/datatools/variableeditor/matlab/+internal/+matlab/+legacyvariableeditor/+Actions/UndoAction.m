classdef UndoAction < internal.matlab.legacyvariableeditor.VEAction
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'UndoAction'
    end
    
    properties
        Manager;
    end
    
    methods
        function this = UndoAction(props, manager)
            props.ID = internal.matlab.legacyvariableeditor.Actions.UndoAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.legacyvariableeditor.VEAction(props, manager);
            this.Callback = @this.Undo;
            this.Manager = manager;
            
        end
        
        function Undo(this, undoInfo)
            idx = arrayfun(@(x) isequal(x.DocID, undoInfo.docID), this.Manager.Documents);
            sh = this.Manager.Documents(idx).ViewModel.ActionStateHandler;            
            
            if internal.matlab.legacyvariableeditor.peer.PeerUtils.isFilterTablesInLiveEditorOn()
                try                    
                    [tws, mgr] = internal.matlab.legacyvariableeditor.Actions.UndoAction.getFilteringWorkspace(undoInfo);
                    % If any of these commands being executed is of type
                    % boundary, update table in filteringWorkspace.
                    isBoundary = false;
                    for i=1:length(sh.CommandArray)
                        isBoundary = isBoundary || sh.isBoundaryCondition(sh.CommandArray(i));
                    end
                    if isBoundary                
                        tws.updateTableAndResetCache(sh.OrigData, undoInfo.docID);                
                    end
                    internal.matlab.legacyvariableeditor.peer.HeaderMenuStateHandler.updateHeaderMenuForUndo(mgr, tws, sh);
                catch 
                    % Ignore the exceptions
                end
            end
            
            CurrentRange = undoInfo.range;
            sh.isUndoRedoAction = true;
            % Discarding the last entry in codeArray since it is an undo operation.
            sh.CodeArray = [];
            % Appending the undo command to thet an undo stack for redo.
            sh.UndoCommandArray = [sh.UndoCommandArray, sh.CommandArray(end)];
            
            % Set the IsFiltered Flag to none for the undo command
            sh.handleSortFilterIcon();       
            
            % Discarding last command before undo.
            sh.CommandArray(end) = [];
            if isempty(sh.CommandArray)
                % If commmandrray is empty, exit early since data is no
                % longer modified
                sh.DataModel.Data = sh.OrigData;                
                sh.updateClientView(CurrentRange);
                sh.CodeArray = {';'};
                sh.publishCode();
                return;
            end
            
            % Re-running all the commands on the original data to get
            % back the same state.
            % This can be improved by saving only the row indices of the
            % orignial data.
            index = sh.CommandArray(end).Index;
            command = sh.CommandArray(end).Command;
            sh.getCodegenCommands(index, command);
            sh.executeCode();            
            sh.updateClientView(CurrentRange);
            
            sh.publishCode();                                
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
        % workspaces like filtering need to be updated
       function originalTableModified = isCommandModifiedOriginalTable(commandtype)
            originalTableModified = strcmp(commandtype, 'Clean');                
       end
                      
       function [tws, mgr] = getFilteringWorkspace(undoInfo)
            channel = strcat('/VE/filter',undoInfo.docID);
            mgr = internal.matlab.legacyvariableeditor.peer.PeerManagerFactory.createManager(channel, false);
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            tws = mgr.Workspaces('filterWorkspace');
       end
       
       % This is no longer used, but keep this for now.
       function updateFilteredState(undoInfo, sh, index, commandType, lastCommand)
            if internal.matlab.legacyvariableeditor.peer.PeerUtils.isFilterTablesInLiveEditorOn()                
                tws = internal.matlab.legacyvariableeditor.Actions.UndoAction.getFilteringWorkspace(undoInfo);
                if internal.matlab.legacyvariableeditor.Actions.UndoAction.isCommandModifiedOriginalTable(commandType)
                    % update the original table stored in the filtered
                    % workspace                    
                    tws.updateOriginalTable(sh.DataModel.Data, sh.DataModel.Data.Properties.VariableNames{index});                 
                elseif sh.isBoundaryCondition(lastCommand)
                    %tws.updateTableAndResetCache(sh.DataModel.Data);
                end
            end
        end
    end
end

