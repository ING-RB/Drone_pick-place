classdef MergeCategoriesAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.variableeditor.Actions.CategoricalCleaning.CleanCategoriesActionBase
    % EditCategoriesAction
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'MergeCategoriesAction';
    end

    methods
        function this = MergeCategoriesAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.CategoricalCleaning.MergeCategoriesAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.Callback = @this.MergeCategories;
            this.Manager = manager;
        end
        
        function MergeCategories(this, editInfo)
            doc = this.getOutputDocument(this.Manager, editInfo.docID);

            % retrieve the selected rows from the selection event
            % information
            selectedRows = this.getSelectedRows(editInfo.actionInfo.selection);
            targetMergedCategory = editInfo.actionInfo.mergedCategory;
            targetMergedCategory = internal.matlab.variableeditor.peer.PeerUtils.formatStringToServerViewFromClientView(targetMergedCategory);
            
            % compute a cell array with the category names to merge
            [categoriesToMerge, selectedRows] = this.getCategoriesToMerge(selectedRows, targetMergedCategory, doc);
            % generate the publish code before the actual update for
            % indexing purpose
             if ~strcmp(editInfo.actionInfo.mergedCategory, '<New Category>')
                this.generateMergeCode(categoriesToMerge, doc);
             else
                workspace = doc.Workspace;
                workspace.updateMergedCategoriesList(categoriesToMerge);
                this.generateMergeCode(categoriesToMerge, doc);
             end
            
            % merge the categories in the categorical cleaner and update
            % the counts
            if strcmp(targetMergedCategory, '<New Category>')
                this.mergeSelectedStringsWithNewCategory(selectedRows, ...
                    targetMergedCategory, categoriesToMerge, doc);
            else
                this.mergeSelectedStrings(selectedRows, targetMergedCategory, categoriesToMerge, doc);
            end
                
            % update the copy of the output table data in the workspace
            if ~strcmp(targetMergedCategory, '<New Category>')
                this.updateTableOutputDataInWorkspace(categoriesToMerge, doc);
            end
        end
        
        function updateTargetCategoryCounts(~, selectedRows, targetMergedCategory, doc)
            % get the index of the target category to merge to
            targetMergedCategoryIndex = find(strcmp(doc.DataModel.Data.Categories, targetMergedCategory));
            
            % compute the increase in count for the target category and
            % update the counts for that entry in the data model
            numCategoriesBeingMerged = 0;
            for k=1:length(selectedRows)
                numCategoriesBeingMerged = numCategoriesBeingMerged + double(doc.DataModel.Data.Counts(selectedRows(k)));
            end
            doc.DataModel.Data.Counts(targetMergedCategoryIndex) = ...
                doc.DataModel.Data.Counts(targetMergedCategoryIndex) + numCategoriesBeingMerged;
            
            % if table is in searched state, update the counts for the
            % unsearched state also
            workspace = doc.Workspace;
            colName = doc.DataModel.Name;
            if workspace.isSearchedState()
                originalIndexForTargetMergedCategory = workspace.getUnsearchedIndices({targetMergedCategory}, colName);
                unsearchedTable = workspace.getUnsearchedTable(colName);
                unsearchedTable.Counts(originalIndexForTargetMergedCategory) = ...
                    unsearchedTable.Counts(originalIndexForTargetMergedCategory) + numCategoriesBeingMerged;
                workspace.setVariableValue(colName, unsearchedTable);
            end
        end
        
        
        
        function mergeSelectedStringsWithNewCategory(this, selectedRows, targetMergedCategory, ~, doc)
            a = this.Manager.ActionManager.ActionList.keys;
            addAction = this.Manager.ActionManager.ActionList(a{1});
            
            numCategoriesBeingMerged = 0;
            for k=1:length(selectedRows)
                numCategoriesBeingMerged = numCategoriesBeingMerged + double(doc.DataModel.Data.Counts(selectedRows(k)));
            end
            
            addAction.AddCategories(struct('count', numCategoriesBeingMerged, 'codeGen', false, 'docID', doc.DocID));
            doc.DataModel.Data(selectedRows, :) = [];
            doc.DataModel.Data.Order = ...
                (1:size(doc.DataModel.Data,1))';
            unsearchedTable = doc.DataModel.Data;
            colName = doc.DataModel.Name;
            workspace = doc.Workspace;
            workspace.setVariableValue(colName, unsearchedTable);
            
            this.updateCategoriesInfo(doc);                        
            
            % recompute merged category index and set the selection to just
            % the target merged category
            targetMergedCategoryIndex = find(strcmp(doc.DataModel.Data.Categories, targetMergedCategory));
            vm = doc.ViewModel;
            vm.setSelection([targetMergedCategoryIndex targetMergedCategoryIndex], []);
        end
        
        function mergeSelectedStrings(this, selectedRows, targetMergedCategory, categoriesToMerge, doc)
            % remove the selected categories from view            
            this.updateTargetCategoryCounts(selectedRows, targetMergedCategory, doc);
            doc.DataModel.Data(selectedRows, :) = [];
            doc.DataModel.Data.Order = ...
                (1:size(doc.DataModel.Data,1))';
            unsearchedTable = doc.DataModel.Data;
            
            % if table is in searched state, update the counts for the
            % unsearched state also
            workspace = doc.Workspace;
            colName = doc.DataModel.Name;
            if workspace.isSearchedState()
                % additional brace needed in case its a
                % categoriesToMerge{2:end} has just one element
                unsearchedTable = this.removeFromUnsearchedTable({categoriesToMerge{2:end}}, colName, doc);
            end
            workspace.setVariableValue(colName, unsearchedTable);
            
            this.updateCategoriesInfo(doc);                        
            
            % recompute merged category index and set the selection to just
            % the target merged category
            targetMergedCategoryIndex = find(strcmp(doc.DataModel.Data.Categories, targetMergedCategory));
            vm = doc.ViewModel;
            vm.setSelection([targetMergedCategoryIndex targetMergedCategoryIndex], []);            
        end
        
        % update the copy of the table data in the workspace
        function updateTableOutputDataInWorkspace(this, categoriesToMerge, doc)
            data = this.getTableOutputData(doc);
            
            % Get the table Variable Name from the workspace since we need
            % to update the output table
            colName = doc.Workspace.VariableName;

            data.(colName) = mergecats(data.(colName), categoriesToMerge);

            % update the workspace   
            this.setTableOutputData(data, doc);             
        end
        
        % generate merge code
        function generateMergeCode(this, categoriesToMerge, doc)
            workspace = doc.Workspace;
            
            % if the last command in the command array is not a clean of
            % the same type then it is a boundary condition (new line of 
            % code is generated)
            isBoundaryCondition = this.checkBoundaryCondition(workspace.getMergedCategoriesList(''), ...
                'Merge', doc);            
            if isBoundaryCondition
                % reset any cached lists of removed categories in the
                % workspace 
                workspace.resetCategoriesLists();
            end
            
            % TODO: enhance merge to consolidate code when merged to same category as a previous merge
            % update the workspace categories list
%             workspace.updateMergedCategoriesList(categoriesToMerge);
%             allMergedCategories = workspace.getMergedCategoriesList(categoriesToMerge{1});

            % construct code to be published and the code executed on
            % undo/redo
            [publishCode, executeCode] = this.constructPublishExecuteCode(categoriesToMerge, doc);
            
            workspace.updateGeneratedCode(struct('publishCode', {publishCode}, ...
                'executeCode', {executeCode}, 'commandInfo', 'Merge'), isBoundaryCondition);            
        end 
        
        function [publishCode, executeCode] = constructPublishExecuteCode(this, allMergedCategories, doc)
            % Get the actual table variable name since this is what we need
            % for codeGen (publish and execute)
            colName = doc.Workspace.VariableName;
            outputName = doc.Workspace.getOutputName();
            if ~isvarname(colName)
                [~,~,colName] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentString(colName, outputName, NaN);
                colName = ['(' colName ')'];
            end
            publishCode = [outputName '.' colName ' = mergecats(' outputName '.' colName ',' '['];
            executeCode = sprintf('tempDM.%s = mergecats(tempDM.%s, [', colName, colName);
            
            [publishCode, executeCode] = this.appendCategoriesToCodeGenerated(publishCode, ...
                executeCode, allMergedCategories);             
        end
        
    end    
end
        
        