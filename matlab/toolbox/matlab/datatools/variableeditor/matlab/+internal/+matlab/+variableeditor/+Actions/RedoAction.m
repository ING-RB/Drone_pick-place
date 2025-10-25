classdef RedoAction < internal.matlab.variableeditor.VEAction
    %ClearAction
    %        clear all variables in workspacebroswer

    % Copyright 2018-2023 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'RedoAction'
    end

    properties
        Manager;
    end

    methods
        function this = RedoAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.RedoAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.Redo;
            this.Manager = manager;

        end

        function Redo(this, redoInfo)
            idx = arrayfun(@(x) isequal(x.DocID, redoInfo.docID), this.Manager.Documents);
            viewModel = this.Manager.Documents(idx).ViewModel;
            sh = viewModel.ActionStateHandler;

            try
                [tws, mgr] = internal.matlab.variableeditor.Actions.RedoAction.getFilteringWorkspace(redoInfo);
                internal.matlab.variableeditor.peer.HeaderMenuStateHandler.updateHeaderMenuForRedo(mgr, tws, sh);
                % If the command being executed is of type
                % boundary, update table in filteringWorkspace
                if sh.isBoundaryCondition(sh.UndoCommandArray(end))
                    tws.updateTableAndResetCache(sh.OrigData, redoInfo.docID);
                end
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::redoaction::error", "e1: " + e.message);
            end

            sh.setIsUndoRedoAction(true);
            cleanup = onCleanup(@()sh.setIsUndoRedoAction(false));

            sh.CommandArray = [sh.CommandArray, sh.UndoCommandArray(end)];
            index = sh.UndoCommandArray(end).Index;
            command = sh.UndoCommandArray(end).Command;

            % Set the IsFiltered Flag to none for the redo command
            % Model prop will be set by the executeCode method if needed
            sh.handleSortFilterIcon();
            sh.getCodegenCommands(index, command);

            sh.executeCode();
            internal.matlab.variableeditor.Actions.RedoAction.updateFilteredState(redoInfo, sh, index, command);

            sh.updateClientView();

            sh.ViewModel.updateRowMetaData();

            sh.ViewModel.updateColumnMetaData();

            % Do not publish code for MOTW Context since we've already
            % called sh.executeCode. This will otherwise cause double
            % execution.
            % TODO: We need a better way to identify whether this is a
            % temporary code execution view or a permanent one like JSD
            isMOTWContext = contains(viewModel.userContext, 'MOTW');
            if ~isMOTWContext
                sh.publishCode();
            end

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
            tws = [];
            channel = strcat('/VE/filter',redoInfo.docID);
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            if (mgr.Workspaces.Count > 0 && isKey(mgr.Workspaces, 'filterWorkspace')) 
                tws = mgr.Workspaces('filterWorkspace');
            end
       end

       function updateFilteredState(redoInfo, sh, index, commandType)
            if internal.matlab.variableeditor.Actions.RedoAction.isCommandModifiedOriginalTable(commandType)
                % update the original table stored in the filtered
                % workspace
                tws = internal.matlab.variableeditor.Actions.RedoAction.getFilteringWorkspace(redoInfo);
                if ~isempty(tws)
                    % Translate from columnIndex varname to dataIndex varname
                    varName = sh.ViewModel.getHeaderInfoFromIndex(index);
                    tws.updateOriginalTable(sh.DataModel.Data, varName);
                end
            end
       end
    end
end
