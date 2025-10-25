classdef DeleteAction < internal.matlab.variableeditor.VEAction 
    % DELETEACTION removes the currently selected fields from the struct
    % variable.

    % Copyright 2020-2025 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'VariableEditor.struct.delete'
    end
    
    properties (Hidden)
       DialogResponseListener 
    end

    properties (Access='protected')
        DeleteTitleSingleVar = getString(message('MATLAB:codetools:confirmationdialog:DeleteSingleFieldTitle'));
        DeleteTitleMultipleVars = getString(message('MATLAB:codetools:confirmationdialog:DeleteMultipleFieldsTitle'));
        DeleteButtonText = getString(message('MATLAB:codetools:confirmationdialog:Delete'));
    end
    
    methods
        function this = DeleteAction(props, manager)
            if ~isfield(props, 'ID')              
                props.ID = internal.matlab.variableeditor.Actions.struct.DeleteAction.ActionName;
            end            
            if ~isfield(props, 'Enabled')              
                props.Enabled = true;
            end
            this@internal.matlab.variableeditor.VEAction(props, manager);            
            this.Callback = @this.deleteVariable;
        end

        function UpdateActionState(this)
            viewModel = this.getVariableEditorViewModel();
            if isempty(viewModel)
                this.Enabled = false;
                return
            end

            if isa(viewModel, 'internal.matlab.variableeditor.StructureTreeViewModel')
                % g3326648: We don't allow the user to delete timetable row time variables.
                % We allow the user to delete their selection in any other case.
                this.Enabled = ~viewModel.containsRowTimeVariable(viewModel.getSelectedFields());
            else
                this.Enabled = isa(viewModel, 'internal.matlab.variableeditor.StructureViewModel') || ...
                    isa(viewModel, 'internal.matlab.desktop_workspacebrowser.DesktopWSBViewModel');
            end
        end
    end

    methods(Access='protected')
        function deleteVariable(this)
            execImmediately = internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle;
            if execImmediately
                processDeleteAction(this);
            else
                % Defer the delete so that other actions can process first (especially selection)
                builtin('_dtcallback', @() processDeleteAction(this));
            end
        end

        function isValid = isValidDelete(~, selectedFields)
           isValid = ~isempty(selectedFields);
        end

        function handleDialogResponse(this, dlgResponse)
            if strcmp(dlgResponse.src, this.ID)
                if (dlgResponse.response == 1)
                    this.handleDelete();
                elseif (dlgResponse.response == 2)
                    return;
                end
            end
        end

        % From the given fields grouped by parents, we categorize each field as a struct
        % or table field. We must categorize these fields to properly generate deletion
        % code for them.
        function [structFieldsToDelete, tableVariablesToDelete] = ...
            separateStructAndTableFields(~, fieldsWithSameParent, viewModel)

            structFieldsToDelete = [];
            tableVariablesToDelete = [];

            for i=1:length(fieldsWithSameParent)
                f = internal.matlab.variableeditor.VEUtils.splitRowId(fieldsWithSameParent(i));

                % Determine the data type of the parent of the current field.
                % Assume view model data is "s".
                if length(f) > 2      % E.g., "a.b.c". Parent is "a.b".
                    parentId = internal.matlab.variableeditor.VEUtils.joinRowId(f(1:end-1));
                    parentData = viewModel.getFieldData(viewModel.DataModel.Data, parentId);
                elseif length(f) == 2 % E.g., "a.b". Parent is "a", and we retrieve it from the view model.
                    parentData = viewModel.DataModel.Data.(f(1));
                else                  % E.g., "a". Parent is "s", the view model data.
                    parentData = viewModel.DataModel.Data;
                end

                if isstruct(parentData)
                    structFieldsToDelete = [structFieldsToDelete f(end)];
                elseif istabular(parentData)
                    tableVariablesToDelete = [tableVariablesToDelete f(end)];
                end
            end
        end
        
         function handleDelete(this)
            import internal.matlab.variableeditor.Actions.ActionUtils;
            focusedDoc = this.veManager.FocusedDocument;
            docName = focusedDoc.Name;
            selectedFields = focusedDoc.ViewModel.getSelectedFields();

            if isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureTreeViewModel')
                cmd = this.getCodeForNestedStructDelete(selectedFields, docName, focusedDoc.ViewModel);
            else
                cmd = this.getCodeForStructDelete(selectedFields, docName, focusedDoc.ViewModel);
            end

            codePublishingChannel = focusedDoc.DataModel.CodePublishingDataModelChannel;
            ActionUtils.publishCode(codePublishingChannel, cmd);

            % g2603546: Dispatch actions so UIVariableEditor can react
            % Publish to any MATLAB listeners on the View
            eventdata = internal.matlab.variableeditor.NestedVariableInteractionEventData;
            eventdata.UserAction = 'delete';
            eventdata.Index = '';
            if ~iscell(cmd)
                cmd = {cmd};
            end
            eventdata.RowIds = selectedFields;
            eventdata.Code = cmd;
            focusedDoc.ViewModel.notify('UserDataInteraction', eventdata);

            % Broadcast workspaceUpdated because the workspace is a private
            % workspace that doesn't notify of data changed events so we
            % need to manually trigger it.
            % g2885514
            ws = focusedDoc.ViewModel.DataModel.Workspace;
            if (~ischar(ws) && ~isstring(ws) &&...
                ~isa(ws, 'matlab.internal.datatoolsservices.AppWorkspace') && ...
                ~isa(ws, 'internal.matlab.variableeditor.MLWorkspace'))
                focusedDoc.ViewModel.DataModel.workspaceUpdated;
            end
         end
         
         function [dialogText, dialogTitle] = getConfirmationDialogText(this, selectionSize)
            if selectionSize == 1
                dialogText = getString(message('MATLAB:codetools:confirmationdialog:DeleteFieldConfirmation'));
                dialogTitle = this.DeleteTitleSingleVar;
            else
                dialogText = getString(message('MATLAB:codetools:confirmationdialog:DeleteFieldsConfirmation'));
                dialogTitle = this.DeleteTitleMultipleVars;
            end 
         end

        function cmd = getCodeForStructDelete(~, selectedFields, docName, ~)
            fieldsToBeDeleted = strjoin(selectedFields, '", "');
            if (length(selectedFields) > 1) 
                deleteCmd = "%s = rmfield(%s, [""%s""]);";
            else
                deleteCmd = "%s = rmfield(%s, ""%s"");";
            end

            % Clean up the row IDs we will use for code gen.
            docName = internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(docName);
            cmd = sprintf(deleteCmd, docName, docName, fieldsToBeDeleted);
         end

        function cmd = getCodeForTableVariableDelete(~, selectedFields, docName, ~)
            fieldsToBeDeleted = strjoin(selectedFields, '", "');
            if (length(selectedFields) > 1)
                deleteCmd = "%s = removevars(%s, [""%s""]);";
            else
                deleteCmd = "%s = removevars(%s, ""%s"");";
            end

            % Clean up the row IDs we will use for code gen.
            docName = internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(docName);
            cmd = sprintf(deleteCmd, docName, docName, fieldsToBeDeleted);
        end
    end

    methods(Access={?internal.matlab.variableeditor.Actions.struct.DeleteAction, ?matlab.mock.TestCase})
        function cmd = getCodeForNestedStructDelete(this, selectedFields, docName, viewModel)
            arguments
                this
                selectedFields string
                docName string
                viewModel
            end
            cmd = '';
            % Group same parents together so rmfield can be coalesced
            selectedFields = viewModel.getUniqueAncestors(selectedFields);

            % g3504256: If there's an issue with how "selectedFields" is set up, it's likely that the while loop
            % below will not pop elements out of "selectedFields". To patch the issue up, we break out of the loop
            % if the number of iterations exceeds the length of "selectedFields".
            iters = 0;

            while selectedFields.length > 0
                % g3504256
                iters = iters + 1;
                if iters > selectedFields.length + 1
                    break
                end

                currField = selectedFields(1);
                fname = internal.matlab.variableeditor.VEUtils.splitRowId(currField);
                parentName = docName;
                root = '';
                if fname.length > 1
                    root = internal.matlab.variableeditor.VEUtils.joinRowId(fname(1:end-1));
                    parentName = internal.matlab.variableeditor.VEUtils.joinRowId({parentName root});
                end
                allAncestorLevels = arrayfun(@(x)length(internal.matlab.variableeditor.VEUtils.splitRowId(x)), selectedFields);
                % find all other fields that have similar fieldnames
                allOtherFields = selectedFields(ismember(allAncestorLevels, length(fname)));

                startsWithIdx = startsWith(allOtherFields, root);
                fieldsWithSameParent = allOtherFields(startsWithIdx);

                [structFieldsToDelete, tableVariablesToDelete] = ...
                    this.separateStructAndTableFields(fieldsWithSameParent, viewModel);

                % Delete struct fields
                if ~isempty(structFieldsToDelete)
                    cmd = cmd + this.getCodeForStructDelete(structFieldsToDelete, parentName, viewModel);
                end

                % Delete table variables
                if ~isempty(tableVariablesToDelete)
                    % TODO: Explore reusing table column-deletion code generation from
                    % +Actions/+dataTypes/DeleteDataAction.m.
                    %
                    % Note that to reuse that code, we need the parent data,
                    % the range of rows to delete, and the range of columns to delete.
                    % We cannot rely on just passing names around.
                    cmd = cmd + this.getCodeForTableVariableDelete(tableVariablesToDelete, parentName, viewModel);
                end

                selectedFields(startsWithIdx)=[];
            end
        end

        function processDeleteAction(this)
            viewModel = this.getVariableEditorViewModel();
            selectedFields = viewModel.getSelectedFields();
            if this.isValidDelete(selectedFields)
                shouldUseSettings = internal.matlab.variableeditor.ArrayViewModel.shouldUseSettingsForContext(viewModel.userContext);
                s = settings;
                confirmationsetting = s.matlab.confirmationdialogs.WorkspaceBrowserClearConfirmation.ActiveValue;
                % Show confirmation dialog to get user's response
                if shouldUseSettings && (confirmationsetting)
                    DTDlgHandler = internal.matlab.datatoolsservices.DTDialogHandler.getInstance;
                    [msg, title] = this.getConfirmationDialogText(length(selectedFields));
                    deleteButtonText = string(this.DeleteButtonText);
                    cancelButtonText = string(getString(message('MATLAB:uistring:popupdialogs:Cancel')));
                    DTDlgHandler.showConfirmationDialog(msg, title, Source=this.ID, DialogButtons=[deleteButtonText, cancelButtonText], ...
                        SettingPath="matlab.confirmationdialogs", SettingVal="WorkspaceBrowserClearConfirmation", ...
                        CallbackFcn=@this.handleDialogResponse);
                else
                    this.handleDelete();
                end
            end
        end
    end
end
