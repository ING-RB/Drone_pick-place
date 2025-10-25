classdef DuplicateAction < internal.matlab.variableeditor.VEAction 
    % DUPLICATEACTION Duplicates the currently selected fields in the struct
    % variable.
    
    % Copyright 2020-2025 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'DuplicateAction'
    end

    methods
        function this = DuplicateAction(props, manager)
            if ~isfield(props, 'ID')              
                props.ID = internal.matlab.variableeditor.Actions.struct.DuplicateAction.ActionName;
            end            
            if ~isfield(props, 'Enabled')              
                props.Enabled = true;
            end            
            this@internal.matlab.variableeditor.VEAction(props, manager);            
            this.Callback = @this.duplicateVariable;
        end       
        
        function UpdateActionState(this)
            viewModel = this.getVariableEditorViewModel();
            if isempty(viewModel)
                this.Enabled = false;
                return
            end

            if isa(viewModel, 'internal.matlab.variableeditor.StructureTreeViewModel')
                % We disable this action for table variables, since it makes little sense
                % for users to duplicate columns.
                this.Enabled = ~viewModel.containsTableVariable(viewModel.getSelectedFields());
            end
        end
    end
    
    methods(Access='protected')
        function duplicateVariable(this, forceExecute)
            import internal.matlab.variableeditor.Actions.ActionUtils;
            if nargin < 2 || isempty(forceExecute)
                forceExecute = false;
            end            
            focusedDoc = this.veManager.FocusedDocument;
            selectedFields = focusedDoc.ViewModel.getSelectedFields();
            if ~isempty(selectedFields)
                varName = focusedDoc.Name;
                if isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureTreeViewModel')
                    selectedFields = internal.matlab.variableeditor.VEUtils.getExecutableRowIdVersion(selectedFields);
                    cmd = this.generateNestedVarDuplicateCommand(selectedFields, varName, focusedDoc.ViewModel);
                else
                    fields = fieldnames(focusedDoc.DataModel.Data);
                    cmd = this.generateDuplicateCommand(selectedFields, fields, varName); 
                end
                
                evalStr =  sprintf("eval(['%s']);",cmd);
                if forceExecute
                    this.executeCommand(evalStr);
                end
                codePublishingChannel = focusedDoc.DataModel.CodePublishingDataModelChannel;
                ActionUtils.publishCode(codePublishingChannel, strrep(cmd, '''''',''''));

                % g2603546: Dispatch actions so UIVariableEditor can react
                % Publish to any MATLAB listeners on the View
                eventdata = internal.matlab.variableeditor.VariableInteractionEventData;
                eventdata.UserAction = '';
                eventdata.Index = '';
                if ~iscell(cmd)
                    cmd = {cmd};
                end
                eventdata.Code = cmd;
                focusedDoc = this.veManager.FocusedDocument;
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
        end

        % With a set of given selected fields, this function generates the command to duplicate them all.
        % "selectedFields" is expected to _not_ include the document name.
        function cmd = generateNestedVarDuplicateCommand(this, selectedFields, docName, viewModel)
            arguments
                this
                selectedFields (1,:) string {mustBeNonempty}
                docName (1,1) string
                viewModel
            end

            origFieldData = viewModel.DataModel.Data;
            cmd = '';

            % Go through each selected field. To successfully duplicate, we need access to each selected field's
            % siblings so we generate a unique name.
            for i=1:length(selectedFields)
                fname = internal.matlab.variableeditor.VEUtils.splitRowId(selectedFields(i));
                fieldData = origFieldData; % We must start back at the original field data for each iteration

                if fname.length > 1 % "Level 2" and greater fields (i.e., nested fields)
                    % We must extract sibling information for this nested field, which requires some trickery.
                    leafName = fname(end);
                    fieldData = viewModel.getFieldData(fieldData, fname(1:end-1));

                    % Merge the document name and the entire field (sans the final part)...
                    parentName = internal.matlab.variableeditor.VEUtils.joinRowId([docName, fname(1:end-1)]);
                    parentName = internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(parentName);

                    % ...generate a unique name to dupe as, then generate the new command part.
                    newUniqueName = internal.matlab.datatoolsservices.VariableUtils.getVarNameForCopy(leafName, fieldnames(fieldData));
                    newCommandPart = char(this.getDuplicateCommand(newUniqueName, leafName, parentName));
                else % "Level 1" fields (i.e., top-level fields)
                    newUniqueName = internal.matlab.datatoolsservices.VariableUtils.getVarNameForCopy(fname, fieldnames(fieldData));
                    newCommandPart = char(this.getDuplicateCommand(newUniqueName, fname, docName));
                end

                cmd = [cmd newCommandPart];
            end
        end
        
        function cmd = generateDuplicateCommand(this, selectedFields, fields, varName)
            arguments
                this
                selectedFields string
                fields string
                varName string
            end
            for i=1:length(selectedFields)
                % Get the unique variable name to use for the copy
                newUniqueName = internal.matlab.datatoolsservices.VariableUtils.getVarNameForCopy(selectedFields(i), fields);          

                % Add in the variable name being created to the list of
                % fields
                fields = {fields{:} char(newUniqueName)}; %#ok<CCAT>
                
                % Create the command for the duplicatation
                singlecmd = this.getDuplicateCommand(newUniqueName, selectedFields(i), varName);
                if i==1
                    cmd = singlecmd;
                else
                    cmd = strcat(cmd, singlecmd);
                end
            end            
        end
        
        function duplicateCommand = getDuplicateCommand(~, newName, selectedField, docName)            
            codegen = "%s.%s = %s.%s; ";
            duplicateCommand = sprintf(codegen, docName, newName, docName, selectedField);
        end
        
        function executeCommand(this, cmd)
            focusedDoc = this.veManager.FocusedDocument;
            internal.matlab.variableeditor.Actions.ActionUtils.executeCommand(cmd, focusedDoc.Workspace);
        end
    end   
end

