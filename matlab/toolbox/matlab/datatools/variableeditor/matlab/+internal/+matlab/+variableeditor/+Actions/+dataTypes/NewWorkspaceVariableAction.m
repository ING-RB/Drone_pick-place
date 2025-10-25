classdef NewWorkspaceVariableAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles creation of new Workspace Variable. A set of
    % conversion types are registered for individual datatypes.

    % Copyright 2020-2025 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'NewWorkspaceVariableAction'
    end
    
    methods
        function this = NewWorkspaceVariableAction(props, manager)            
           props.ID = internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction.ActionName;           
           props.Enabled = true; 
           this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
           this@internal.matlab.variableeditor.VEAction(props, manager);
        end
        
        % Turn off newWorkspaceVariable Action for scalar object types
        function toggleEnabledState(this, isEnabled)
            if isEnabled
                focusedDoc = this.Manager.FocusedDocument;
                isEnabled = ~strcmp(focusedDoc.DataModel.Type, 'Object') && ~isa(focusedDoc.DataModel.Data, 'dataset');
            end
            this.Enabled = isEnabled;
        end
    end
    
    methods(Access='protected')
        % Generates command for creating new workspace variable from the
        % current selection. "actionInfo"'s menuID informs what type 
        % of workspace variable is being created from the current
        % selection.
        function [cmd, executionCmd] = generateCommandForAction(this, focusedDoc, actionInfo)
            import internal.matlab.variableeditor.Actions.ActionUtils;
            focusedView = focusedDoc.ViewModel;
            selection = focusedView.getSelection; 
            sz = focusedView.getTabularDataSize();
            [rowRange, colRange] = this.getNumericSelectionRange(selection, sz);
            selectionRange = [rowRange, ',' colRange];           
            cmd = '';
            executionCmd = '';
            variableName = focusedDoc.Name;

            internal.matlab.datatoolsservices.logDebug("variableeditor::NewWorkspaceVariableAction", "generateCommandForAction variable name:" + variableName);

            % Async callback to detect variable names from correct
            % workspace. 
            if strcmp(actionInfo.menuID, 'StructNewFromSelection')
                fields = focusedView.getSelectedFields();
                if isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureTreeViewModel')
                    fields = internal.matlab.variableeditor.VEUtils.getExecutableRowIdVersion(fields);
                    [cmd, executionCmd] = this.generateCmdForNestedScalarStructs(focusedDoc.Name, fields, focusedDoc.Workspace);
                else
                    [cmd, executionCmd] = this.generateCmdForScalarStructs(focusedDoc.Name, fields, focusedDoc.Workspace);
                end
                return;
            elseif ismember(actionInfo.menuID, {'NewRowVectors', 'NewColumnVectors', 'NewStructureArray', ...
                    'StructSeparateWorkspaceVar','StructNewCellArray','StructNewTable', 'StructNewNumericArray', ...
                    'NewStructureArrayFromObjectArray','NewVariablesFromObjectArray','NewCellArrayFromObjectArray','NewTableFromObjectArray','NewObjectArrayFromObjectArray'...
                    })
                
                callbackCmd = sprintf('internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction.handleCreationFromSelection(''%s'',''%s'',''%s'',''%s'',''%s'');', ....
                    this.Manager.Channel, focusedDoc.DocID, actionInfo.menuID, rowRange, colRange);

                internal.matlab.datatoolsservices.logDebug("variableeditor::NewWorkspaceVariableAction", "generateCommandForAction cmd:" + callbackCmd);
            else
                % For 'NewStringArray', 'NewNumericArray','NewCharacterArray', 
                % generate newvarname based on column Variable rather than table name if the
                % selection is within the same column. for E.g if t = array2table(rand(2))
                % columnsSelected = [1,2], then baseName = t1, but if
                % columnsSelected = [1,1], then baseName = 'Var1'
              
                callbackCmd = sprintf('internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction.handleNewWorkspaceVariableCreation(''%s'', ''%s'', ''%s'', ''%s'', ''%s'');', ....
                    actionInfo.menuID, variableName, selectionRange, this.Manager.Channel, focusedDoc.DocID);                

                internal.matlab.datatoolsservices.logDebug("variableeditor::NewWorkspaceVariableAction", "generateCommandForAction cmd:" + callbackCmd);
            end
            this.executeCommand(callbackCmd);
        end 
        
        % Generate new workspace variable command for scalars structs by
        % looping over selected fields
        function [cmd, openvarCmd] = generateCmdForScalarStructs(~, varName, fields, workspace)
            openvarCmd = '';
            cmd = '';
            existingVarNames = evalin(workspace, 'who');
            for i=1:length(fields)
               currField = fields(i);
               newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(currField,  existingVarNames');
               cmd = [cmd sprintf('%s = %s.(''%s''); ', newVarName, varName, currField)];
               openvarCmd = [openvarCmd sprintf('openvar(''%s''); ', newVarName)];
               existingVarNames(end+1) = {char(newVarName)};
            end
        end

        % Generate new workspace variable command for scalars structs by
        % looping over selected fields
        function [cmd, openvarCmd] = generateCmdForNestedScalarStructs(~, varName, fields, workspace)
            openvarCmd = '';
            cmd = '';
            existingVarNames = evalin(workspace, 'who');
            for i=1:length(fields)
               currField = fields(i);
               newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(currField,  existingVarNames');
               cmd = [cmd sprintf('%s = %s.%s; ', newVarName, varName, currField)];
               openvarCmd = [openvarCmd sprintf('openvar(''%s''); ', newVarName)];
               existingVarNames(end+1) = {char(newVarName)};
            end
        end
        
        function executeCommand(~, callbackCmd)            
            internal.matlab.variableeditor.Actions.ActionUtils.executeCommand(callbackCmd);
        end
    end
    
     methods(Static)
         % This method handles those creations that require access to the current selection
         function handleCreationFromSelection(channel, docID, menuID, rowRange, colRange)
            import internal.matlab.variableeditor.Actions.ActionUtils;
            import internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction;
            factory = internal.matlab.variableeditor.peer.VEFactory.getInstance;            
            mgr = factory.createManager(channel, false);            
            docIndex = mgr.docIdIndex(docID);
            focusedDoc = mgr.Documents(docIndex);
            variableName = focusedDoc.Name;
            selection = focusedDoc.ViewModel.getSelection;
            ws = focusedDoc.Workspace;
            classType = focusedDoc.ViewModel.DataModel.getClassType;
            openvarCode = '';
            code = '';
            isMxNObjectArray = isa(focusedDoc.ViewModel, "internal.matlab.variableeditor.MxNArrayViewModel") && ...
                isobject(focusedDoc.ViewModel.DataModel.Data);
            
            internal.matlab.datatoolsservices.logDebug("variableeditor::NewWorkspaceVariableAction", "handleCreationFromSelection variable name:" + variableName + "  class type: " + classType + "  VM type: " + class(focusedDoc.ViewModel));

            if strcmp(menuID, 'NewRowVectors')
                fnames = evalin(ws, 'who');
                [code, openvarCode] = internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction.handleRowVectorCreation(...
                    selection{1}, colRange, variableName, fnames, channel, docID);
            elseif strcmp(menuID, 'NewColumnVectors')
                fnames = evalin(ws, 'who');
                [code, openvarCode] = internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction.handleColVectorCreation(...
                    selection{2}, rowRange, variableName, fnames, channel, docID);
            elseif strcmp(classType, 'objectarray') % Object Vector
                fnames = evalin(ws, 'who');
                data = focusedDoc.DataModel.Data;
                visibleProperties = focusedDoc.DataModel.getProperties();
                if strcmp(menuID, 'NewStructureArrayFromObjectArray')
                    [code, openvarCode] = NewWorkspaceVariableAction.generateNewStructArrayFromObjectArray(...
                    data, rowRange, colRange, visibleProperties, variableName, fnames);
                elseif strcmp(menuID, 'NewVariablesFromObjectArray')
                    [code, openvarCode] = NewWorkspaceVariableAction.generateNewVariablesFromObjectArray(...
                    data, rowRange, colRange, visibleProperties, variableName, fnames);
                elseif strcmp(menuID, 'NewCellArrayFromObjectArray')
                    [code, openvarCode] = NewWorkspaceVariableAction.generateNewCellArrayFromObjectArray(...
                    data, rowRange, colRange, visibleProperties, variableName, fnames);
                elseif strcmp(menuID, 'NewTableFromObjectArray')
                    [code, openvarCode] = NewWorkspaceVariableAction.generateNewTableFromObjectArray(...
                    data, rowRange, colRange, visibleProperties, variableName, fnames);
                elseif strcmp(menuID, 'NewObjectArrayFromObjectArray')
                    [code, openvarCode] = NewWorkspaceVariableAction.generateNewObjectArrayFromObjectArray(...
                    data, rowRange, colRange, visibleProperties, variableName, fnames);
                end
            elseif isMxNObjectArray % Object Array
                fnames = evalin(ws, 'who');
                data = focusedDoc.DataModel.Data;
                if strcmp(menuID, 'NewCellArrayFromObjectArray')
                    [code, openvarCode] = NewWorkspaceVariableAction.generateNewCellArrayFromMxNObjectArray(...
                        data, rowRange, colRange, variableName, fnames);
                elseif strcmp(menuID, 'NewTableFromObjectArray')
                    [code, openvarCode] = NewWorkspaceVariableAction.generateNewTableFromMxNObjectArray(...
                        data, rowRange, colRange, variableName, fnames);
                elseif strcmp(menuID, 'NewObjectArrayFromObjectArray')
                    [code, openvarCode] = NewWorkspaceVariableAction.generateNewObjectArrayFromMxNObjectArray(...
                        data, rowRange, colRange, variableName, fnames);
                end
            else
                fnames = evalin(ws, 'whos');
                % NOTE: These menuIDs are only mapped for structs with
                % isRowOrColumnVector dataAttribute and are exclusive to
                % StructArray views.
                if strcmp(menuID, 'NewStructureArray')
                    [code, openvarCode] = internal.matlab.array.StructArrayVariableEditorAdapter.variableEditorCreateNewStructCode(...
                        focusedDoc.ViewModel.DataModel.Data, variableName, selection{1}, selection{2}, fnames');
                elseif strcmp(menuID, 'StructSeparateWorkspaceVar')
                     [code, openvarCode] = internal.matlab.array.StructArrayVariableEditorAdapter.variableEditorCreateSeparateVariablesCode(...
                        focusedDoc.ViewModel.DataModel.Data, variableName, selection{1}, selection{2}, fnames');
                elseif strcmp(menuID, 'StructNewCellArray')
                     [code, openvarCode] = internal.matlab.array.StructArrayVariableEditorAdapter.variableEditorCreateNewCellArrayCode(...
                        focusedDoc.ViewModel.DataModel.Data, variableName, selection{1}, selection{2}, fnames');
                elseif strcmp(menuID, 'StructNewTable')
                     [code, openvarCode] = internal.matlab.array.StructArrayVariableEditorAdapter.variableEditorCreateNewTableCode(...
                        focusedDoc.ViewModel.DataModel.Data, variableName, selection{1}, selection{2}, fnames');
                elseif strcmp(menuID, 'StructNewNumericArray')
                     [code, openvarCode] = internal.matlab.array.StructArrayVariableEditorAdapter.variableEditorCreateNewNumericArrayCode(...
                        focusedDoc.ViewModel.DataModel.Data, variableName, selection{1}, selection{2}, fnames');   
                end
            end

            internal.matlab.datatoolsservices.logDebug("variableeditor::NewWorkspaceVariableAction", "handleCreationFromSelection code:" + code + "  openvar code: " + openvarCode);


            codePublishingChannel = focusedDoc.DataModel.CodePublishingDataModelChannel;
            ActionUtils.publishCode(codePublishingChannel, code, openvarCode);
         end
         
        % Generates command for creation of row vectors from current
        % selection. for E.g r = rand(5), rowSelection=[2 4], colSelection=[1 2]
        % cmd: r1 = r(2,1:2); r2 = r(3,1:2); r3 = r(4,1:2);
        function [cmd, openvarCmd] = handleRowVectorCreation(selection, colRange, variableName, existingVarNames, channel, docID)
            openvarCmd = '';            
            cmd = '';
            sSize = size(selection);
            factory = internal.matlab.variableeditor.peer.VEFactory.getInstance;
            mgr = factory.createManager(channel, false);
            docIndex = mgr.docIdIndex(docID);
            focusedDoc = mgr.Documents(docIndex);
            data = focusedDoc.DataModel.Data;
            if isprop(focusedDoc.DataModel, 'DataI')
                data = focusedDoc.DataModel.DataI;
            end
            if ~ismatrix(data)
                slice = focusedDoc.DataModel.Slice;
                sliceDimIndices = find(slice == ":");
            end
            for j=1:sSize(1)                                          
               for k = selection(j,1) : selection(j,2)
                   newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(variableName,  existingVarNames');
                    if ~ismatrix(data)
                        if ~isequal(sliceDimIndices,[1, 2])
                            % When not indexing the first two dimensions you'll
                            % get a mxnx1 and need squeeze to get rid of the x1
                            % dimenion
                            formatStr = "%s = squeeze(%s(" + strjoin(slice,",").replace(":","%s") + ")); ";
                            cmd = [cmd char(sprintf(formatStr, newVarName, variableName, num2str(k), colRange))];
                        else
                            formatStr = "%s = %s(" + strjoin(slice,",").replace(":","%s") + "); ";
                            cmd = [cmd char(sprintf(formatStr, newVarName, variableName, num2str(k), colRange))];
                        end
                    else
                        cmd = [cmd sprintf('%s = %s(%d,%s); ', newVarName, variableName, k, colRange)];
                    end
                   openvarCmd = [openvarCmd sprintf('openvar(''%s''); ', newVarName)];
                   existingVarNames(end+1) = {char(newVarName)};
               end
            end
        end
        
        % Generates command for creation of column vectors from current
        % selection. for E.g r = rand(5), rowSelection=[2 4], colSelection=[1 2]
        % cmd: r1 = r(2:4,1); r2 = r(2:4,2);
        function [cmd, openvarCmd] = handleColVectorCreation(selection, rowRange, variableName, existingVarNames, channel, docID)
            openvarCmd = '';            
            cmd = '';
            sSize = size(selection);
            factory = internal.matlab.variableeditor.peer.VEFactory.getInstance;
            mgr = factory.createManager(channel, false);
            docIndex = mgr.docIdIndex(docID);
            focusedDoc = mgr.Documents(docIndex);
            data = focusedDoc.DataModel.Data;
            if isprop(focusedDoc.DataModel, 'DataI')
                data = focusedDoc.DataModel.DataI;
            end
            if ~ismatrix(data)
                slice = focusedDoc.DataModel.Slice;
                sliceDimIndices = find(slice == ":");
            end
            for j=1:sSize(1)
               for k = selection(j,1) : selection(j,2)
                   newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(variableName,  existingVarNames');    
                    if ~ismatrix(data)
                        if ~isequal(sliceDimIndices,[1, 2])
                            % When not indexing the first two dimensions you'll
                            % get a mxnx1 and need squeeze to get rid of the x1
                            % dimenion
                            formatStr = "%s = squeeze(%s(" + strjoin(slice,",").replace(":","%s") + ")); ";
                            cmd = [cmd char(sprintf(formatStr, newVarName, variableName, rowRange, num2str(k)))];
                        else
                            formatStr = "%s = %s(" + strjoin(slice,",").replace(":","%s") + "); ";
                            cmd = [cmd char(sprintf(formatStr, newVarName, variableName, rowRange, num2str(k)))];
                        end
                    else
                       cmd = [cmd sprintf('%s = %s(%s,%d); ', newVarName, variableName, rowRange, k)];
                    end
                   openvarCmd = [openvarCmd sprintf('openvar(''%s''); ', newVarName)];
                   existingVarNames(end+1) = {char(newVarName)};
               end
            end
        end
       
        % Handles creation of a new variable type. for e.g
        % r = rand(10), rowSelection=[3,5;7,8], colSelection=[2,2;4,4]
        % codegen for new Numeric Array: r1 = r([3:5,7:8],[2,4]);
        function handleNewWorkspaceVariableCreation(menuID, variableName, selectionRange, channel, docID)
            import internal.matlab.variableeditor.Actions.ActionUtils;
            factory = internal.matlab.variableeditor.peer.VEFactory.getInstance;
            mgr = factory.createManager(channel, false);
            docIndex = mgr.docIdIndex(docID);
            focusedDoc = mgr.Documents(docIndex);
            import internal.matlab.variableeditor.Actions.ActionUtils;
            fnames = evalin(focusedDoc.Workspace, 'who');    
            newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(variableName,  fnames');
            variableName = strtrim(variableName);
            if ismember(menuID, {'NewStringArray', 'NewNumericArray', ...
                    'NewDatetimeArray', 'NewDurationArray', 'NewCalendarDurationArray', ...
                    'NewCategoricalArray', 'NewCellArray', 'NewObjectArray'})
                data = focusedDoc.DataModel.Data;
                if isprop(focusedDoc.DataModel, 'DataI')
                    data = focusedDoc.DataModel.DataI;
                end
                if ~ismatrix(data)
                    slice = focusedDoc.DataModel.Slice;
                    if contains(selectionRange, "],[")
                        % Split, plaid selection
                        sr = strrep(strsplit(selectionRange, "],["), {'[',']'}, '');
                    else
                        % Contiguous selection
                        sr = strsplit(selectionRange, ",");
                    end
                    sliceDimIndices = find(slice == ":");

                    if ~isequal(sliceDimIndices,[1, 2])
                        % When not indexing the first two dimensions you'll
                        % get a mxnx1 and need squeeze to get rid of the x1
                        % dimenion
                        formatStr = "%s = squeeze(%s(" + strjoin(slice,",").replace(":","%s") + "));";
                        cmd = char(sprintf(formatStr, newVarName, variableName, getRangeStr(sr{1}), getRangeStr(sr{2})));
                    else
                        formatStr = "%s = %s(" + strjoin(slice,",").replace(":","%s") + ");";
                        cmd = char(sprintf(formatStr, newVarName, variableName, getRangeStr(sr{1}), getRangeStr(sr{2})));
                    end
                else
                    % If this is a scalar and varname contains (, assign to
                    % new variable as is to avoid indexing errors.
                    if contains(variableName, "(") && strcmp(selectionRange, ':,:')
                        cmd = sprintf('%s = %s;', newVarName, variableName);
                    else
                        cmd = sprintf('%s = %s(%s);', newVarName, variableName, selectionRange);
                    end
                end
            elseif ismember(menuID, {'NewConvertCatArray'})
                cmd = sprintf('%s = categorical(%s(%s));', newVarName, variableName, selectionRange);
            elseif ismember(menuID, {'NewConvertCellArray'})                
                cmd = sprintf('%s = cellstr(%s(%s));', newVarName, variableName, selectionRange);
            elseif strcmp(menuID, 'NewCharArray')
                cmd = sprintf('%s = %s;', newVarName, variableName);
            end
            openvarCmd = sprintf('openvar(''%s'');', newVarName);   
            codePublishingChannel = focusedDoc.DataModel.CodePublishingDataModelChannel;
            ActionUtils.publishCode(codePublishingChannel, cmd, openvarCmd);          
        end      

        function [newVarName, colNames, dataRowCmd] = getObjectArraySelection(data, rows, cols, visibleProperties, variableName, existingVarNames) %#ok<INUSD>
            newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(variableName,  existingVarNames');
            if ~strcmp(rows, ':')
                rowIndices = "[" + join(join(string(rows), ":"), ",") + "]";
            else
                rowIndices = ":";
            end
            if ~strcmp(cols, ':')
                colIndices = "[" + join(join(string(cols), ":"), ",") + "]";
            else
                colIndices = "[1:" + length(visibleProperties) + "]";
            end
            expandedCols = eval(colIndices);
            colNames = string(visibleProperties(expandedCols));
            if strcmp(rows, ':')
                dataRowCmd = variableName;
            else
                dataRowCmd = sprintf("%s(%s)", variableName, rowIndices);
            end
        end

        % Generates the code to create a new cell array from the current
        % object array selection
        function [cmd, openvarCmd] = generateNewCellArrayFromObjectArray(data, rows, cols, visibleProperties, variableName, existingVarNames)
            import internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction;
            [newVarName, colNames, dataRowCmd] = NewWorkspaceVariableAction.getObjectArraySelection(data, rows, cols, visibleProperties, variableName, existingVarNames);

            rhs = "[{" + dataRowCmd + "." + colNames.join("}', {" + dataRowCmd + ".") + "}'" + "]";
            cmd = newVarName + " = " + rhs + ";";
            openvarCmd = "openvar('" + newVarName + "'); ";
        end

        % Generates the code to create a new cell array from the current
        % object array selection
        function [cmd, openvarCmd] = generateNewStructArrayFromObjectArray(data, rows, cols, visibleProperties, variableName, existingVarNames)
            import internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction;
            [newVarName, colNames, dataRowCmd] = NewWorkspaceVariableAction.getObjectArraySelection(data, rows, cols, visibleProperties, variableName, existingVarNames);

            rhs = "struct(" + compose("'%s', {" + dataRowCmd + ".%s}'", colNames, colNames).join(", ") + ")";

            cmd = newVarName + " = " + rhs + ";";
            openvarCmd = "openvar('" + newVarName + "'); ";
        end

        % Generates the code to create a new cell array from the current
        % object array selection
        function [cmd, openvarCmd] = generateNewVariablesFromObjectArray(data, rows, cols, visibleProperties, variableName, existingVarNames)
            import internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction;
            [~, colNames, dataRowCmd] = NewWorkspaceVariableAction.getObjectArraySelection(data, rows, cols, visibleProperties, variableName, existingVarNames);

            newVarNames = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(colNames,  existingVarNames');
            cmd = compose("%s = [{" + dataRowCmd + ".%s}']", newVarNames', colNames).join("; ") + ";";

            % Make scalar numerics into numeric arrays instead of cell
            % array
            scalarNumCols = colNames(arrayfun(@(var)all(cellfun(@(v)isscalar(v) && isnumeric(v), {data.(var)})), colNames));
            cmd = replace(cmd, compose("{" + dataRowCmd + ".%s}", scalarNumCols), compose("[" + dataRowCmd + ".%s]", scalarNumCols));

            openvarCmd = compose("openvar('%s'); ", newVarNames).join("");
        end

        % Generates the code to create a new cell array from the current
        % object array selection
        function [cmd, openvarCmd] = generateNewTableFromObjectArray(data, rows, cols, visibleProperties, variableName, existingVarNames)
            import internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction;
            [newVarName, colNames, dataRowCmd] = NewWorkspaceVariableAction.getObjectArraySelection(data, rows, cols, visibleProperties, variableName, existingVarNames);

            rhs = "table(" + compose("{" + dataRowCmd + ".%s}'", colNames).join(", ") + ", 'VariableNames', {'" +  colNames.join("','") + "'})";

            % Make scalar numerics into numeric arrays instead of cell
            % array
            scalarNumCols = colNames(arrayfun(@(var)all(cellfun(@(v)isscalar(v) && isnumeric(v), {data.(var)})), colNames));
            rhs = replace(rhs, compose("{" + dataRowCmd + ".%s}", scalarNumCols), compose("[" + dataRowCmd + ".%s]", scalarNumCols));

            cmd = newVarName + " = " + rhs + ";";
            openvarCmd = "openvar('" + newVarName + "'); ";
        end

        % Generates the code to create a new cell array from the current
        % object array selection
        function [cmd, openvarCmd] = generateNewObjectArrayFromObjectArray(data, rows, cols, visibleProperties, variableName, existingVarNames)
            import internal.matlab.variableeditor.Actions.dataTypes.NewWorkspaceVariableAction;
            [newVarName, ~, dataRowCmd] = NewWorkspaceVariableAction.getObjectArraySelection(data, rows, cols, visibleProperties, variableName, existingVarNames);

            cmd = newVarName + " = " + dataRowCmd + ";";
            openvarCmd = "openvar('" + newVarName + "'); ";
        end

        % Generates the code to create a new cell array from the current
        % object array selection
        function [cmd, openvarCmd] = generateNewTableFromMxNObjectArray(~, rows, cols, variableName, existingVarNames)
            newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(variableName,  existingVarNames');

            rowIndices = getRangeIndicesString(rows);
            colIndices = getRangeIndicesString(cols);

            cmd = newVarName + " = array2table(" + variableName + "(" + rowIndices + ", " + colIndices + "));";
            openvarCmd = "openvar('" + newVarName + "'); ";
        end

        % Generates the code to create a new cell array from the current
        % object array selection
        function [cmd, openvarCmd] = generateNewObjectArrayFromMxNObjectArray(~, rows, cols, variableName, existingVarNames)
            newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(variableName,  existingVarNames');

            rowIndices = getRangeIndicesString(rows);
            colIndices = getRangeIndicesString(cols);

            cmd = newVarName + " = " + variableName + "(" + rowIndices + ", " + colIndices + ");";
            openvarCmd = "openvar('" + newVarName + "'); ";
        end

        % Generates the code to create a new cell array from the current
        % object array selection
        function [cmd, openvarCmd] = generateNewCellArrayFromMxNObjectArray(data, rows, cols, variableName, existingVarNames)
            newVarName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(variableName,  existingVarNames');

            rowIndices = getRangeIndicesString(rows);
            colIndices = getRangeIndicesString(cols);

            if rowIndices == ":"
                numRows = height(data);
            else
                numRows = eval("length(" + rowIndices + ")");
            end

            if colIndices == ":"
                numCols = width(data);
            else
                numCols = eval("length(" + colIndices + ")");
            end

            cmd = newVarName + " = mat2cell(" + variableName + "(" + rowIndices + ", " + colIndices + "), ones(1," + numRows + "), ones(1, " + numCols + "));";
            openvarCmd = "openvar('" + newVarName + "'); ";
        end
     end

    methods(Access={?matlab.mock.TestCase})
        function [cmd, executionCmd] = call_generateCommandForAction(this, focusedDoc, actionInfo)
            [cmd, executionCmd] = this.generateCommandForAction(focusedDoc, actionInfo);
        end
    end
end

% Returns a string representation of a selection range adding square
% brackets and comma separation when needed
function rangeIndices = getRangeIndicesString(range)
    if ~strcmp(range, ':')
        rangeIndices = join(join(string(range), ":"), ",");
        if height(range) > 1
            rangeIndices = "[" + rangeIndices + "]";
        end
    else
        rangeIndices = ":";
    end
end


function s = getRangeStr(s)
    if contains(s, ",")
        s = "[" + s + "]";
    end
end

