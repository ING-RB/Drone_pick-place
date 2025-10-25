classdef SaveVariablesAction < internal.matlab.variableeditor.VEAction
    %SaveAction
    %        Save selected actions in workspacebroswer

    % Copyright 2017-2024 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'Variableeditor.struct.save'
    end

    methods
        function this = SaveVariablesAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.struct.SaveVariablesAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.SaveVariables;
        end

        function cmd = SaveVariables(this, actionInfo)
            arguments
                this
                actionInfo = []
            end
            % get the list of selected fields and create a command to
            % save them all
            if ~isempty(actionInfo) && isfield(actionInfo, 'selectedFields')
                selectedFields = actionInfo.selectedFields;
            else
                document = this.veManager.FocusedDocument;
                if ~isempty(document)
                    selectedFields = document.ViewModel.SelectedFields;
                end
            end

            cmd = '';
            if ~isempty(selectedFields)
                [saveFileName, filterIndex] = internal.matlab.datatoolsservices.VariableUtils.getSaveVarsFileName();
                if ~isempty(saveFileName)
                    cmd = this.getCommandForSave(selectedFields, saveFileName, filterIndex);
                    try
                        evalin("debug", cmd);
                    catch ex
                        if ~internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle
                            errordlg(string(message("MATLAB:datatools:workspaceFunctions:SaveErrorMessage", ex.message)), ...
                                string(message("MATLAB:datatools:workspaceFunctions:SaveErrorTitle")));
                        end
                    end
                end
            end
        end

        function cmd = getCommandForSave(~, selectedFields, saveFileName, filterIndex)
            arguments
                ~
                selectedFields string
                saveFileName string
                filterIndex double
            end

            if filterIndex == 2
                cmd = "matlab.io.saveVariablesToScript('" + saveFileName + "', {'" + strjoin(selectedFields, "', '") + "'});";
            else
                cmd = "save(""" + saveFileName + """, """ + strjoin(selectedFields, '", "') + """);";
            end
        end

        % For Save Variables, disable if the viewmodel is an
        % UnsupportedView in order to update the toolstrip state accurately
        function  UpdateActionState(this)
            focusedDoc = this.veManager.FocusedDocument;
            if ~isempty(focusedDoc)
                isEnabled = true;
                if isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.MLUnsupportedViewModel') || isa(focusedDoc.DataModel.Data, 'dataset')
                    isEnabled = false;
                end
                this.Enabled = isEnabled;
            end
        end
    end
end
