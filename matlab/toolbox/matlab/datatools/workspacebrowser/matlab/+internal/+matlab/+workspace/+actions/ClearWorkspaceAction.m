classdef ClearWorkspaceAction < internal.matlab.variableeditor.Actions.struct.DeleteAction
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2017-2025 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'ClearWorkspaceAction'
    end

    properties(Access='private')
        DeleteTitle = getString(message('MATLAB:codetools:confirmationdialog:ClearWorkspaceTitle'));
    end
    
    methods
        function this = ClearWorkspaceAction(props, manager)
            props.ID = internal.matlab.workspace.actions.ClearWorkspaceAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.struct.DeleteAction(props, manager);
            this.DeleteButtonText = getString(message('MATLAB:codetools:confirmationdialog:DeleteAll'));
        end
        
        % Disable the action if there are no variables in the workspace
        function  UpdateActionState(this)
            wsbDocument = this.veManager.Documents;
            if ~isempty(wsbDocument)
                WSBdata = wsbDocument.DataModel.getData;
                this.Enabled = ~isempty(fieldnames(WSBdata));
            end
        end
    end
    
    methods(Access = protected)
        
        function executeInWebWorker(this, cmd)
            wsbDocument = this.veManager.Documents;
            workspace = wsbDocument.Workspace;
            internal.matlab.variableeditor.Actions.ActionUtils.executeCommand(cmd, workspace);
        end

        function isValid = isValidDelete(~, ~)
           isValid = true;
        end

         function [msg, title] = getConfirmationDialogText(this, ~)
            msg = getString(message('MATLAB:codetools:confirmationdialog:ClearWorkspaceConfirmation'));
            title = this.DeleteTitle;
         end

         function handleDelete(this)
            this.executeInWebWorker("clearvars");
        end
    end
end

