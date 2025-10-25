classdef DuplicateVariableAction < internal.matlab.variableeditor.Actions.struct.DuplicateAction
    %DuplicateAction
    %        Duplicate selected variables in workspacebroswer

    % Copyright 2017-2025 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'DuplicateVariableAction'
    end

    methods
        function this = DuplicateVariableAction(props, manager)
            props.ID = internal.matlab.workspace.actions.DuplicateVariableAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.struct.DuplicateAction(props, manager);
        end
    end

    methods(Access = protected)
        % Duplicate Variable and force command execution.
        function duplicateVariable(this, vars)
            if nargin > 1 && isfield(vars.actionInfo, "clipboardData")
                % The clipboardData is a comma separated string of variable
                % names
                selectedFields = strtrim(split(vars.actionInfo.clipboardData, ","));
                wsContent = evalin("debug", "who");

                % Make sure the variables being copied still exist in the
                % workspace
                selectedFields = intersect(selectedFields, wsContent);
                if ~isempty(selectedFields)
                    cmd = this.generateDuplicateCommand(selectedFields, wsContent, "");
                    evalStr =  sprintf("eval(['%s']);",cmd);
                    this.executeCommand(evalStr);
                elseif ~isempty(vars.actionInfo.clipboardData)
                    % Even though the data looked like variable names, none
                    % of the variables exist.  Call uiimport instead.
                    uiimport("-pastespecial");
                end
            else
                this.duplicateVariable@internal.matlab.variableeditor.Actions.struct.DuplicateAction(true);
            end
        end

        function duplicateCommand = getDuplicateCommand(~, newName, selectedField, ~)
            evalStr = "%s = %s;";
            duplicateCommand = sprintf(evalStr, newName, selectedField);
        end
    end
end
