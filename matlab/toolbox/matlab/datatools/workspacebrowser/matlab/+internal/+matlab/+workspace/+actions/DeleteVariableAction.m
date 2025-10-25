classdef DeleteVariableAction < internal.matlab.variableeditor.Actions.struct.DeleteAction
    %DeleteAction
    %        Delete selected actions in workspacebroswer
    
    % Copyright 2017-2025 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'WorkspaceBrowser.delete'
    end
    
    methods
        function this = DeleteVariableAction(props, manager)
            props.ID = internal.matlab.workspace.actions.DeleteVariableAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.struct.DeleteAction(props, manager);
            this.DeleteTitleSingleVar = getString(message('MATLAB:codetools:confirmationdialog:DeleteSingleVarTitle'));
            this.DeleteTitleMultipleVars = getString(message('MATLAB:codetools:confirmationdialog:DeleteMultipleVarsTitle'));
        end        
    end
    
    methods(Access= protected)
        % Generates command to delete the variable post user confirmation
        function handleDelete(this)
            focusedDoc = this.veManager.FocusedDocument;
            selectedFields = focusedDoc.ViewModel.SelectedFields;
            clearfield = strjoin(selectedFields, ''',''');
            clearcmd = "builtin('clear','%s');";
            cmd = sprintf(clearcmd ,clearfield);
            this.executeCommand(cmd);
        end
        
        function executeCommand(this, cmd)
            focusedDoc = this.veManager.FocusedDocument;
            internal.matlab.variableeditor.Actions.ActionUtils.executeCommand(cmd, focusedDoc.Workspace);
        end
        
        % Gets confirmation text to be displayed in the confirmation dialog.
        function [dialogText, title] = getConfirmationDialogText(this, selectionSize)
            if selectionSize == 1
                dialogText = getString(message('MATLAB:codetools:confirmationdialog:DeleteVariableConfirmation'));
                title = this.DeleteTitleSingleVar;
            else
                dialogText = getString(message('MATLAB:codetools:confirmationdialog:DeleteVariablesConfirmation'));
                title = this.DeleteTitleMultipleVars;
            end
        end
    end
end

