classdef InsertAction < internal.matlab.variableeditor.VEAction 
    % INSERTACTION Inserts a newly created variable above the currently
    % selected field

    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'InsertAction'
    end

    methods
        function this = InsertAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.struct.InsertAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.veManager = manager;
            this.Callback = @this.insertField;
        end

        function UpdateActionState(this)
            viewModel = this.getVariableEditorViewModel();
            if isempty(viewModel)
                this.Enabled = false;
                return
            end

            if isa(viewModel, 'internal.matlab.variableeditor.StructureTreeViewModel')
                fields = viewModel.getSelectedFields();

                % We only allow insertion if the user selected a single field.
                if (isscalar(fields))
                    this.Enabled = ~viewModel.isStructArrayField(fields) ... % Does not belong to a struct array
                                && ~viewModel.containsTableVariable(fields); % Is not a table variable
                else
                    this.Enabled = false;
                end
            end
        end
    end

    methods(Access='protected')
         function insertField(this)
             import internal.matlab.variableeditor.Actions.ActionUtils;
             focusedDoc = this.veManager.FocusedDocument;
             varName = focusedDoc.Name;
             if isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureTreeViewModel')
                cmd = this.getCodeForNestedStructInsert(varName, focusedDoc.ViewModel);
             else
                cmd = this.getCodeForStructInsert(varName, focusedDoc.ViewModel);
             end
             codePublishingChannel = focusedDoc.DataModel.CodePublishingDataModelChannel;
             ActionUtils.publishCode(codePublishingChannel, cmd);

            % g2603546: Dispatch actions so UIVariableEditor can react
            % Publish to any MATLAB listeners on the View
            eventdata = internal.matlab.variableeditor.VariableInteractionEventData;
            eventdata.UserAction = '';
            eventdata.Index = '';
            if ~iscell(cmd)
                cmd = {cmd};
            end
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

         % Insert for the first selected field alone
         % TODO: Disable behavior for multi-row selection
         function cmd = getCodeForNestedStructInsert(this, varName, viewModel)
             selectedFields = viewModel.getSelectedFields();
             parentName = viewModel.DataModel.Name;
             fieldData = viewModel.DataModel.Data;
             leafName = '';
             if selectedFields.length > 0
                 fname = internal.matlab.variableeditor.VEUtils.splitRowId(selectedFields(1));
                 leafName = fname;
                 if fname.length > 1
                    parentName = internal.matlab.variableeditor.VEUtils.joinRowId(fname(1:end-1));
                    parentName = internal.matlab.variableeditor.VEUtils.joinRowId([viewModel.DataModel.Name, parentName]);
                    leafName = fname(end);
                    % get fieldData of parent to gather sibling details
                    fieldData = viewModel.getFieldData(fieldData, parentName);
                 end
             end

             % At this point, we use the parent name for code generation.
             % We must switch to using "." as a delimiter.
             parentName = internal.matlab.variableeditor.VEUtils.getExecutableRowIdVersion(parentName);

             allFields = fieldnames(fieldData);
             newName = internal.matlab.variableeditor.Actions.struct.InsertAction.generateNameforInsert(allFields);
             cmd = sprintf('%s.%s = 0; ', parentName, newName);
             if ~isempty(leafName)
                 selectedFieldIndex = find(strcmp(allFields, leafName));               
                 newFieldNames = {allFields{1:selectedFieldIndex-1} newName allFields{selectedFieldIndex:end}};
                 newFieldNamesStr = sprintf('[%s]',strjoin(""""+ newFieldNames + """", ", "));
                 cmd = [cmd sprintf('%s = orderfields(%s, %s);', parentName, parentName, newFieldNamesStr)];             
             end 
         end

          function cmd = getCodeForStructInsert(this, variableName, viewModel)
             selectedFields = viewModel.getSelectedFields();
             data = viewModel.DataModel.Data;
             fields = fieldnames(data)';
             newName = internal.matlab.variableeditor.Actions.struct.InsertAction.generateNameforInsert(fields);
             cmd = sprintf('%s.%s = 0; ', variableName, newName);
             if ~isempty(selectedFields)
                 selectedField = selectedFields(1);
                 selectedFieldIndex = find(strcmp(fields, selectedField));               
                 newFieldNames = {fields{1:selectedFieldIndex-1} newName fields{selectedFieldIndex:end}};
                 newFieldNamesStr = sprintf('[%s]',strjoin(""""+ newFieldNames + """", ", "));
                 cmd = sprintf('%s%s = orderfields(%s, %s);', ...
                 cmd, variableName, variableName, newFieldNamesStr);             
             end             
         end
    end
    
    methods(Static)
         function new = generateNameforInsert(fields)
             % Get the variable name to use for the copy.  Given a variable
            % name of 'x', it will return 'xCopy'.  If 'xCopy' already
            % exists, it will append _<number> to find a unique variable
            % name.
            counter = 0;            
            new_base = "unnamed";
            new = new_base;
            while any(new == fields)
                counter = counter + 1;
                proposed_number_string = string(counter);
                new = new_base + proposed_number_string;            
            end
         end         
        
    end
end

