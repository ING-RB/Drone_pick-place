classdef UndoAction < internal.matlab.variableeditor.VEAction
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'UndoAction'
    end
    
    properties
        Manager;
    end
    
    methods
        function this = UndoAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.UndoAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.Undo;
            this.Manager = manager;
            
        end
        
        function Undo(this, undoInfo)
            idx = arrayfun(@(x) isequal(x.DocID, undoInfo.docID), this.Manager.Documents);
            sh = this.Manager.Documents(idx).ViewModel.ActionStateHandler;

            try
                [tws, mgr] = internal.matlab.variableeditor.Actions.UndoAction.getFilteringWorkspace(undoInfo);
                % Update header menu state/ filter table cache only if
                % filtering workspace exists.
                if ~isempty(tws)
                    % This also updates internal state in filteringworkspace, If this errors, filterfigure state will not be reset
                    internal.matlab.variableeditor.peer.HeaderMenuStateHandler.updateHeaderMenuForUndo(mgr, tws, sh);
                    % If the command being executed is of type
                    % boundary, update table in filteringWorkspace
                    if sh.isBoundaryCondition(sh.CommandArray(end))
                        tws.updateTableAndResetCache(sh.OrigData, undoInfo.docID);
                    end
                end
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::undoaction::error", "e1: " + e.message);
            end

            sh.setIsUndoRedoAction(true);
            cleanup = onCleanup(@()sh.setIsUndoRedoAction(false));
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
                if isprop(sh.DataModel,  'DataI')
                    sh.DataModel.DataI = sh.OrigData;
                else
                    sh.DataModel.Data = sh.OrigData;
                end
                sh.updateClientView();
                % Ensure row, column and cell metadata are updated.
                sh.ViewModel.updateCellMetaData();
                sh.ViewModel.updateRowMetaData();
                sh.ViewModel.updateColumnMetaData();
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
            sh.updateClientView();
            % Ensure row, column and cell metadata are updated.
            sh.ViewModel.updateCellMetaData();
            sh.ViewModel.updateRowMetaData();
            sh.ViewModel.updateColumnMetaData();
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
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
            tws = [];
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            if isKey(mgr.Workspaces, 'filterWorkspace')
                tws = mgr.Workspaces('filterWorkspace');
            end
       end
    end
end

