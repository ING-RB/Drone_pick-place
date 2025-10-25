classdef CustomContextMenuAction < internal.matlab.variableeditor.VEAction
    % CustomContextMenuAction
    % Action class that handles execution of user authored context menu
    % actions in the Workspace Browser.

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'CustomContextMenuAction';
    end

    methods
        function this = CustomContextMenuAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.CustomContextMenuAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.ExecuteAction;
        end

        function ExecuteAction(this, actionInfo)
            focusedDoc = this.veManager.FocusedDocument;
            selectedVariable = focusedDoc.ViewModel.SelectedFields;
            title = actionInfo.displayName;
            cmd = actionInfo.matlabFn;
            commandHasScalarReplace = contains(cmd, '$1');
            commandHasListReplace = contains(cmd, '$!');
            if commandHasScalarReplace && commandHasListReplace
                errorDialog(focusedDoc, title, 'MATLAB Action can''t have both Scalar and List Replacements');
                return;
            end
            if commandHasScalarReplace
                if isscalar(selectedVariable)
                    cmd = replace(cmd, '$1', selectedVariable);
                else
                    errorDialog(focusedDoc, title, 'Scalar Replacement MATLAB Action requires single selection.');
                    return;
                end
            elseif commandHasListReplace
                if ~isempty(selectedVariable)
                    list = join('"' + selectedVariable + '"', ',');
                    cmd = replace(cmd, '$!', list);
                else
                    errorDialog(focusedDoc, title, 'List Replacement MATLAB Action requires non-empty selection.');
                    return;
                end
            end
            try
                evalin(focusedDoc.Workspace, char(cmd));
            catch e
                errorDialog(focusedDoc, title, e.message)
            end
        end

        function  UpdateActionState(~)
        end

        function delete(~)
        end
    end
end

function errorDialog(focusedDoc, title, msg)
    errorTitlePrefix = getString(message('MATLAB:codetools:contextmenus:WorkspaceBrowserContextMenuErrorTitle'));
    focusedDoc.ViewModel.dispatchEventToClient(struct( ...
        'type', 'actionError', ...
        'title', append(errorTitlePrefix, ' ', title), ...
        'status', 'error', ...
        'message', msg, ...
        'source', 'server'));
end

