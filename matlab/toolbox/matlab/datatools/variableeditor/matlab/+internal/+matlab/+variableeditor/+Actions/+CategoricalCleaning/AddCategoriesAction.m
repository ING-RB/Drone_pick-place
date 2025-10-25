classdef AddCategoriesAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.variableeditor.Actions.CategoricalCleaning.CleanCategoriesActionBase
    % EditCategoriesAction
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'AddCategoriesAction';
        BaseNewCategoryName = getString(message('MATLAB:codetools:categoricalcleaning:NewCategoryName'));
    end
    
    methods
        function this = AddCategoriesAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.CategoricalCleaning.AddCategoriesAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.Callback = @this.AddCategories;
            this.Manager = manager;
        end
        
        function AddCategories(this, editInfo)
            doc = this.getOutputDocument(this.Manager, editInfo.docID);

            workspace = doc.Workspace;
            colName = doc.DataModel.Name;

            categoriesToAdd = this.getNewCategoryName(doc);
            rowCount = size(doc.DataModel.Data, 1);
            if isfield(editInfo, 'count')
                count = editInfo.count;
            else
                count = 0;
            end
            % generate the publish code before the actual update for
            % indexing purpose
            if isfield(editInfo, 'codeGen')
                codeGen = editInfo.codeGen;
            else
                codeGen = true;
            end
            
            if codeGen
                this.generateAddCode(categoriesToAdd, doc);
            end
            
            doc.DataModel.Data(rowCount+1,:) = ...
                {this.getOrderForNewCategory(doc), categoriesToAdd, count};
            
            % update the categories string data in the workspace. Call
            % setVariableValue to ensure workspace is updated, so changes 
            % show up when searched also
            workspace.setVariableValue(colName, doc.DataModel.Data);
            this.updateCategoriesInfo(doc);
            
            % set the selection to reflect the merged category
            vm = doc.ViewModel;
            vm.setSelection([rowCount+1 rowCount+1], []); 
            
            % update the copy of the table data in the workspace
            if codeGen
                this.updateTableOutputDataInWorkspace(categoriesToAdd, doc);  
            end
        end
        
        % returns the order value for the new category added
        function newOrder = getOrderForNewCategory(~, doc)
            newOrder = 1;
            if ~isempty(doc.DataModel.Data.Order)
                % we need to do a max in case the order column is sorted
                newOrder = max(doc.DataModel.Data.Order)+1;
            end
        end
        
        % update the copy of the table data in the workspace
        function updateTableOutputDataInWorkspace(this, categoriesToAdd, doc)
            data = this.getTableOutputData(doc);
            
            % Get the table Variable Name from the workspace since we need
            % to update the output table
            colName = doc.Workspace.VariableName;
            
            % if it is an ordinal 
            if isordinal(data.(colName))
                % add to the end of the categories list
                categoriesList = categories(data.(colName));
                data.(colName) = addcats(data.(colName), categoriesToAdd, 'After', categoriesList{end});
            else
                data.(colName) = addcats(data.(colName), categoriesToAdd);
            end
            
            % update the workspace   
            this.setTableOutputData(data, doc);  
        end
        
        % generate add code
        function [publishCode, executeCode] = generateAddCode(this, categoriesToAdd, doc)
            workspace = doc.Workspace;
            
            % if the last command in the command array is not a clean of
            % the same type then it is a boundary condition (new line of 
            % code is generated)
            isBoundaryCondition = this.checkBoundaryCondition(workspace.getAddedCategoriesList(), ...
                'Add', doc);
            if isBoundaryCondition
                % reset any cached lists of added categories in the
                % workspace 
                workspace.resetCategoriesLists();
            end
            
            %  update the workspace cache of the removed categories list
            workspace.updateAddedCategoriesList(categoriesToAdd);
            allAddedCategories = workspace.getAddedCategoriesList();
            
            % construct code to be published and the code executed on
            % undo/redo
            [publishCode, executeCode] = this.constructPublishExecuteCode(allAddedCategories, doc);
            
            workspace.updateGeneratedCode(struct('publishCode', {publishCode}, ...
                'executeCode', {executeCode}, 'commandInfo', 'Add'), isBoundaryCondition);                        
        end
        
        % constructs the code to be published and the code to be executed
        % on undo/redo
        function [publishCode, executeCode] = constructPublishExecuteCode(this, allAddedCategories, doc)
            workspace = doc.Workspace;
            % Get the actual table variable name since this is what we need
            % for codeGen (publish and execute)
            colName = workspace.VariableName;

            outputName = doc.Workspace.getOutputName();
            data = workspace.getOriginalOutputData();
            
            if ~isvarname(colName)
                [~,~,colName_codegen] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentString(colName, outputName, NaN);
                colName_codegen = ['(' colName_codegen ')'];
            else
                colName_codegen = colName;
            end
            publishCode = [outputName '.' colName_codegen ' = addcats(' outputName '.' colName_codegen ',' '['];
            executeCode = sprintf('tempDM.%s = addcats(tempDM.%s, [', colName_codegen, colName_codegen); 
            
            [publishCode, executeCode] = this.appendCategoriesToCodeGenerated(publishCode, ...
                executeCode, allAddedCategories);
            
            if isordinal(data.(colName))
                categoriesList = categories(data.(colName));
                publishCode = {[publishCode{1}(1:end-2) ',"After","' categoriesList{end} '");']};
                executeCode = {[executeCode{1}(1:end-2) ',"After","' categoriesList{end} '");']};
            end                        
        end
        
        function newCategoryName = getNewCategoryName(~, doc)
            baseNewCategoryName = internal.matlab.variableeditor.Actions.CategoricalCleaning.AddCategoriesAction.BaseNewCategoryName;
            newCategoryName = baseNewCategoryName;
            counter = 0;
            % check if the name already exists in the strings
            while any(strcmp(doc.DataModel.Data.Categories, ['<' newCategoryName '>']))
                counter = counter + 1;
                newCategoryName = [baseNewCategoryName '_' num2str(counter)];
            end
            
            newCategoryName = {['<' newCategoryName '>']};
        end
    end
end
        
        