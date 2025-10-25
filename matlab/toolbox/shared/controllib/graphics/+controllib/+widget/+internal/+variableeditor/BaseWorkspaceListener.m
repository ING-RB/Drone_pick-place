classdef BaseWorkspaceListener < internal.matlab.datatoolsservices.WorkspaceListener
    % Base workspace listener for variable editor panel
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties (Access = private)
        VariableEditorPanel
    end
    
    methods
        function this = BaseWorkspaceListener(varEditorPanel)
            arguments
                varEditorPanel controllib.widget.internal.variableeditor.VariableEditorPanel
            end
            this = this@internal.matlab.datatoolsservices.WorkspaceListener();
            this.VariableEditorPanel = varEditorPanel;
        end
        
        function workspaceUpdated(this, varNames, ~)
            if contains(varNames,this.VariableEditorPanel.VariableName)
                valueInBaseWorkspace = evalin('base',this.VariableEditorPanel.VariableName);
                if ~isequal(valueInBaseWorkspace,this.VariableEditorPanel.VariableValue)
                    this.VariableEditorPanel.VariableValue = valueInBaseWorkspace;
                end
            end
        end
    end
end