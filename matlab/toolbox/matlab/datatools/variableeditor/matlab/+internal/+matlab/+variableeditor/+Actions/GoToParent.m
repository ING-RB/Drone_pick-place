classdef GoToParent < internal.matlab.variableeditor.VEAction ...
    % This class is unsupported and might change or be removed without notice in
    % a future version.
    
    % This class defines the action to go up in heirarchy to openvar on the
    % immediate parent document.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'GoToParent'
    end
    
    methods
        function this = GoToParent(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.GoToParent.ActionType;
            props.Enabled = false;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.navigateToParent;
        end
        
        % If parentName exists (which means this was opened from a parent
        % document, we openvar on the parentName of the document)
        function navigateToParent(this)
            focusedDoc = this.veManager.FocusedDocument;
            if ~isempty(focusedDoc)
                parentName = focusedDoc.getProperty('parentName');
                if ~isempty(parentName)
                    workspace = focusedDoc.getWorkspaceForEval();
                    % Eval for openvar in the workspace where the documnent
                    % exists.
                    this.executeCommand(workspace, sprintf('openvar(''%s'');', parentName))
                    
                end
            end           
        end

        function executeCommand(~, workspace, cmd)
            evalin(workspace, cmd);
        end
        
        % If parentName does not exist in the FocusedDocument, Go-Up is
        % disabled.
        function  UpdateActionState(this)
            focusedDoc = this.veManager.FocusedDocument;
            if ~isempty(focusedDoc)
                this.Enabled = ~isempty(focusedDoc.getProperty('parentName'));
            end
        end
    end
end

