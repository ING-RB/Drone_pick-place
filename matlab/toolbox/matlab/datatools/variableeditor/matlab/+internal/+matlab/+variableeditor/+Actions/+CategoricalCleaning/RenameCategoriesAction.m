classdef RenameCategoriesAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.variableeditor.Actions.CategoricalCleaning.CleanCategoriesActionBase
    % RenameCategoriesAction
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'RenameCategoriesAction';
    end

    methods
        function this = RenameCategoriesAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.CategoricalCleaning.RenameCategoriesAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.Callback = @this.RenameCategories;
            this.Manager = manager;
        end
        
        function RenameCategories(this, editInfo)
            doc = this.getOutputDocument(this.Manager, editInfo.docID);

            selection = editInfo.actionInfo.selection;
            selectedRow = selection(1).rows.start+1;
            newCategoryName = editInfo.actionInfo.newValue;
            oldCategoryName = editInfo.actionInfo.oldValue;
            selectionChangedAfterRename = editInfo.actionInfo.selectionChangedAfterRename;
            mergeToNew = editInfo.actionInfo.mergeToNew;
            if mergeToNew
                workspace = doc.Workspace;
                mergeVars = workspace.getMergedCategoriesList('<New Category>');
            end
            
            % if renamed category is empty then return
            % ideally client should never return an empty category as
            % newValue
            if isempty(strtrim(newCategoryName))
                return;
            end
            
            % if the old category name and the new one are the same then
            % do nothing
            if isequal(oldCategoryName, newCategoryName)
                return;
            end
            
            % update the categories string view and the counts
            this.renameSelectedStrings(selectedRow, newCategoryName, oldCategoryName, selectionChangedAfterRename, doc);
            
            % update the copy of the table output in the workspace
            if ~mergeToNew
                this.updateTableOutputDataInWorkspace(oldCategoryName, newCategoryName, doc);
            else
                this.updateTableOutputDataInWorkspaceForMergeToNew(newCategoryName, mergeVars, doc);
            end
        end
        
        function renameSelectedStrings(this, selectedRow, newCategoryName, oldCategoryName, selectionChangedAfterRename, doc)
            % if the table is in searched state
            workspace = doc.Workspace;
            colName = doc.DataModel.Name;
            
            % if table is in a searched state and the newCategoryName does
            % not match the search text then clear the search
            if workspace.isSearchedState() && ~workspace.isMatchesSearchCriteria(newCategoryName)
                workspace.clearSearch();
                % update the selectedRow to index in unsearched table
                selectedRow = workspace.getUnsearchedIndices({oldCategoryName}, colName);
            end
            
            % update the data
            doc.DataModel.Data = this.performRename(doc.DataModel.Data, ...
                selectedRow, oldCategoryName, newCategoryName, doc);
            
            % if the table is in searched state, update the unsearched
            % table
            if workspace.isSearchedState()
                unsearchedData = this.updateUnsearchedTable(newCategoryName, oldCategoryName, colName, doc);
                workspace.setVariableValue(colName, unsearchedData);
            else
                % if we do not do this, the data model sometimes does not
                % get updated..
                workspace.setVariableValue(colName, doc.DataModel.Data);
            end
            this.updateCategoriesInfo(doc);
            
            % call setSelection (since, the new name could have merged with another entry, 
            % could have resulted in the search being blown away, etc.) in all cases
            % except when the user selects another cell instead of hitting
            % enter after renaming a cell.
            if ~selectionChangedAfterRename
                % set selection to the new category
                targetCategoryIndex = find(strcmp(doc.DataModel.Data.Categories, ...
                    newCategoryName));            
                vm = doc.ViewModel;
                vm.setSelection([targetCategoryIndex targetCategoryIndex], []);   
            end
        end
        
        function isExistingCategory = isExistingCategoryWithNewName(this, newCategoryName, doc)
            % Get the table Variable Name from the workspace since we need
            % to update the output table
            colName = doc.Workspace.VariableName;

            data = this.getTableOutputData(doc);

            isExistingCategory = iscategory(data.(colName), newCategoryName);
        end
        
        function resultData = performRename(this, data, selectedRow, oldCategoryName, newCategoryName, doc)            
            % need to handle 2 broad cases and each of these case in case
            % Case 1: The new name corresponds to an existing category
            % Case 2: The new name does not correspond to any existing
            if this.isExistingCategoryWithNewName(newCategoryName, doc)
                % merge categories and update counts
                resultData = this.mergeCategories(data, selectedRow, oldCategoryName, newCategoryName, doc);               
            else
                % update the name of the edited category
                resultData = this.renameCategories(data, selectedRow, newCategoryName);
            end                        
        end
        
        function resultData = renameCategories(this, data, selectedRow, newCategoryName)
            % update the name of the edited category
            data.(this.Categories_Variable)(selectedRow) = newCategoryName;
            resultData = data;
        end
        
        function data = mergeCategories(this, data, selectedRow, oldCategoryName, newCategoryName, doc)
            % TODO: Look into consolidating more with the code in merge
            % action class and pulling out to base class
            % get the final combined count for the existing category
            % and update it
            combinedCategoryCount = this.getCombinedCategoryCount(oldCategoryName, newCategoryName, doc);
            mergedCategoryIndex = ...
                find(strcmp(data.(this.Categories_Variable), newCategoryName));
            data.Counts(mergedCategoryIndex) = combinedCategoryCount;
            
            % remove the edited category from the data
            data(selectedRow, :) = [];
        end        
        
        function unsearchedTable = updateUnsearchedTable(this, newCategoryName, oldCategoryName, colName, doc)
            workspace = doc.Workspace;
            originalTableIndices = workspace.getUnsearchedIndices({oldCategoryName}, colName);
            unsearchedTable = workspace.getUnsearchedTable(colName);
            
            % if there is no existing category with the new name, then 
            % get the unsearched index of the category and rename
            if ~this.isExistingCategoryWithNewName(newCategoryName, doc)
                unsearchedTable = this.renameCategories(unsearchedTable, originalTableIndices, newCategoryName);
            else
                % if there is an existing category with the new name
                % get the original indices of the categories to rename
                unsearchedTable = this.mergeCategories(unsearchedTable, originalTableIndices, oldCategoryName, newCategoryName, doc);
            end
        end
        
        % if there is an existing category with the new name and the user
        % chooses to merge, the function returns the combined count of the
        % merged category
        function resultCategoryCount = getCombinedCategoryCount(this, oldCategoryName, newCategoryName, doc)
            oldCategoryCounts = this.getCategoryCountsFromTableOutput(oldCategoryName, doc);
            newCategoryCounts = this.getCategoryCountsFromTableOutput(newCategoryName, doc);
            resultCategoryCount = oldCategoryCounts + newCategoryCounts;
        end
        
        function count = getCategoryCountsFromTableOutput(this, categoryName, doc)
            % get categories list from original table
            data = this.getTableOutputData(doc);
            index = this.getCategoryIndexFromTableOutput(categoryName, doc);
            
            % Get the table Variable Name from the workspace since we need
            % to update the output table
            colName = doc.Workspace.VariableName;           
            
            countsList = countcats(data.(colName));
            count = countsList(index);
        end
        
        function index = getCategoryIndexFromTableOutput(this, categoryName, doc)
            data = this.getTableOutputData(doc);
            
            % Get the table Variable Name from the workspace since we need
            % to update the output table
            colName = doc.Workspace.VariableName;

            categoriesList = categories(data.(colName));
            index = find(strcmp(categoriesList, categoryName));
        end
        
        % update the copy of the table data in the workspace
        function updateTableOutputDataInWorkspace(this, oldCategoryName, newCategoryName, doc)
            data = this.getTableOutputData(doc);
            
            % Get the table Variable Name from the workspace since we need
            % to update the output table
            colName = doc.Workspace.VariableName;

            if this.isExistingCategoryWithNewName(newCategoryName, doc)
                data.(colName) = mergecats(data.(colName), {newCategoryName, oldCategoryName});
            else
                data.(colName) = renamecats(data.(colName), oldCategoryName, {newCategoryName});
            end
            
            this.generateRenameCode(newCategoryName, oldCategoryName, false, doc);
            
            % update the workspace by calling setVariableName
            this.setTableOutputData(data, doc);             
        end
        
        % update the copy of the table data in the workspace
        function updateTableOutputDataInWorkspaceForMergeToNew(this, newCategoryName, mergeVars, doc)
            data = this.getTableOutputData(doc);
            
            % Get the table Variable Name from the workspace since we need
            % to update the output table
            colName = doc.Workspace.VariableName;
            
            mergeVars{1} = newCategoryName;
            data.(colName) = mergecats(data.(colName), mergeVars);
            
            this.generateRenameCode(newCategoryName, mergeVars, true, doc);
            
            % update the workspace by calling setVariableName
            this.setTableOutputData(data, doc);
        end
        
        function [publishCode, executeCode] = generateRenameCode(this, newCategoryName, oldCategoryName, mergeToNew, doc)
            workspace = doc.Workspace;

            % construct code to be published and the code executed on
            % undo/redo
            [publishCode, executeCode] = this.constructPublishExecuteCode(newCategoryName, ...
                oldCategoryName, mergeToNew, doc);                        
            
            workspace.updateGeneratedCode(struct('publishCode', {publishCode}, ...
                'executeCode', {executeCode}, 'commandInfo', 'Rename'), true);
        end
        
        function [publishCode, executeCode] = constructPublishExecuteCode(this, ...
                newCategoryName, oldCategoryName, mergeToNew, doc)
            % Get the table Variable Name from the workspace since we need
            % to update the output table
            colName = doc.Workspace.VariableName;
            outputName = doc.Workspace.getOutputName();
            if ~isvarname(colName)
                [~,~,colName] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentString(colName, outputName, NaN);
                colName = ['(' colName ')'];
            end
            
            if mergeToNew
                publishCode = [outputName '.' colName ' = mergecats(' outputName '.' colName ',' '['];
                executeCode = sprintf('tempDM.%s = mergecats(tempDM.%s, [', colName, colName);
            
                [publishCode, executeCode] = this.appendCategoriesToCodeGenerated(publishCode, ...
                    executeCode, oldCategoryName);
            else
                categoryExists = this.isExistingCategoryWithNewName(newCategoryName, doc);
                [quotes, ~, ~] = internal.matlab.variableeditor.peer.PeerUtils.getCodegenConstructsForDatatype("string");
                oldCategoryName = internal.matlab.variableeditor.peer.PeerUtils.getCleanedNamesForCodegen({oldCategoryName}, quotes, "string");
                newCategoryName = internal.matlab.variableeditor.peer.PeerUtils.getCleanedNamesForCodegen({newCategoryName}, quotes, "string");

                if categoryExists
                    publishCode = [outputName '.' colName ' = mergecats(' outputName '.' colName ',' ...
                        oldCategoryName{1} ',' newCategoryName{1} ');'];

                    executeCode = sprintf('tempDM.%s = mergecats(tempDM.%s,', colName, colName);            
                    executeCode = [executeCode oldCategoryName{1} ',' newCategoryName{1} ');'];
                else
                    publishCode = [outputName '.' colName ' = renamecats(' outputName '.' colName ',' ...
                        oldCategoryName{1} ',' newCategoryName{1} ');'];

                    executeCode = sprintf('tempDM.%s = renamecats(tempDM.%s,', colName, colName);            
                    executeCode = [executeCode oldCategoryName{1} ',' newCategoryName{1} ');'];                
                end
                            
                publishCode = {publishCode};
                executeCode = {executeCode};
            end
        end
    end    
end
        
        