classdef RemoveCategoriesAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.variableeditor.Actions.CategoricalCleaning.CleanCategoriesActionBase
    % EditCategoriesAction
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'RemoveCategoriesAction';
    end

    methods
        function this = RemoveCategoriesAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.CategoricalCleaning.RemoveCategoriesAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.Callback = @this.RemoveCategories;
            this.Manager = manager;
        end
        
        function RemoveCategories(this, editInfo)
            doc = this.getOutputDocument(this.Manager, editInfo.docID);

            % retrieve the selected rows from the selection event
            % information
            selectedRows = this.getSelectedRows(editInfo.actionInfo.selection);
            
            % retrieve the category names to be removed from the selected rows
            % information
            categoriesToRemove = {};                        
            for k=1:length(selectedRows)
                categoriesToRemove{k} = char(doc.DataModel.Data.Categories(selectedRows(k)));
            end
            % generate the publish code before the actual update for
            % indexing purpose
            this.generateRemoveCode(categoriesToRemove, doc);
                        
            % update the categories string data in the workspace
            this.removeSelectedStrings(selectedRows, categoriesToRemove, doc);
            
            % update the copy of the table data in the workspace
            this.updateTableOutputDataInWorkspace(categoriesToRemove, doc);                         
        end
        
        function removeSelectedStrings(this, selectedRows, categoriesToRemove, doc)
            workspace = doc.Workspace;
            colName = doc.DataModel.Name;
            
            % set the selected row entries to empty in the currently
            % displayed table
            doc.DataModel.Data(selectedRows, :) = [];
            
            % update the unsearched table values in the workspace
            if workspace.isSearchedState()
                unsearchedTable = this.removeFromUnsearchedTable(categoriesToRemove, colName, doc);
                workspace.setVariableValue(colName, unsearchedTable);
            else
                % if this is not updated then on removing, then searching,
                % the removed category is shown again in the searched view
                % since the workspace was not updated.
                workspace.setVariableValue(colName, doc.DataModel.Data);
            end
            
            this.updateCategoriesInfo(doc);
        end        
        
        % update the copy of the table data in the workspace
        function updateTableOutputDataInWorkspace(this, categoriesToRemove, doc)
            data = this.getTableOutputData(doc);
            
            % Get the table Variable Name from the workspace since we need
            % to update the output table
            colName = doc.Workspace.VariableName;
            
            % set the variable in the output data to the new data
            data.(colName) = removecats(data.(colName), categoriesToRemove);
            
            % get the undefined count in the output and update the cleaner
            % with the information
            undefinedCategoriesCount = length(find(isundefined(data.(colName))));
            doc.ViewModel.setTableModelProperty('UndefinedCount', undefinedCategoriesCount);
            
            % update the workspace by calling setVariableName
            this.setTableOutputData(data, doc);              
        end
        
        % generate remove code
        function generateRemoveCode(this, categoriesToRemove, doc)                        
            workspace = doc.Workspace;

            % if the last command in the command array is not a clean of
            % the same type then it is a boundary condition (new line of 
            % code is generated)
            isBoundaryCondition = this.checkBoundaryCondition(workspace.getRemovedCategoriesList(), ...
                'Remove', doc);
            if isBoundaryCondition
                % reset any cached lists of removed categories in the
                % workspace 
                workspace.resetCategoriesLists();
            end            
            
            %  update the workspace cache of the removed categories list
            workspace.updateRemovedCategoriesList(categoriesToRemove);
            allRemovedCategories = workspace.getRemovedCategoriesList();
            
            % construct code to be published and the code executed on
            % undo/redo
            [publishCode, executeCode] = this.constructPublishExecuteCode(allRemovedCategories, doc);
            
            workspace.updateGeneratedCode(struct('publishCode', {publishCode}, ...
                'executeCode', {executeCode}, 'commandInfo', 'Remove'), isBoundaryCondition);
        end 
        
        % constructs the code to be published and the code to be executed
        % on undo/redo
        function [publishCode, executeCode] = constructPublishExecuteCode(this, allRemovedCategories, doc)
            % Get the actual table variable name since this is what we need
            % for codeGen (publish and execute)
            colName = doc.Workspace.VariableName;
            outputName = doc.Workspace.getOutputName();
            if ~isvarname(colName)
                [~,~,colName] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentString(colName, outputName, NaN);
                colName = ['(' colName ')'];
            end
            publishCode = [outputName '.' colName ' = removecats(' outputName '.' colName ',' '['];
            executeCode = sprintf('tempDM.%s = removecats(tempDM.%s, [', colName, colName);            
            
            [publishCode, executeCode] = this.appendCategoriesToCodeGenerated(publishCode, ...
                executeCode, allRemovedCategories);            
        end        
    end
end
        
        