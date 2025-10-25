classdef SaveAllVariablesAction < internal.matlab.variableeditor.VEAction
    %SaveAction
    %        Save all workspace variables
    
    % Copyright 2017-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'WorkspaceBrowser.save'
    end
    
    methods
        function this = SaveAllVariablesAction(props, manager)
            props.ID = internal.matlab.workspace.actions.SaveAllVariablesAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.saveAllVariables;
        end
        
        function saveAllVariables(~)
            internal.matlab.datatoolsservices.VariableUtils.saveWorkspace
        end
        
        function UpdateActionState(this)
            % Do not query for the manager from factory, access manager
            % with which the action was created with.
            wsbDocument = this.veManager.Documents;
            % State updates on document close, check for valid doc
            if ~isempty(wsbDocument)
                WSBdata = wsbDocument.DataModel.getData;
                this.Enabled = ~isempty(fieldnames(WSBdata));
            end
        end
    end
end

