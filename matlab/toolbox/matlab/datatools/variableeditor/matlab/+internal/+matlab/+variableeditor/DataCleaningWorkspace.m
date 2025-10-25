% DataCleaningWorkspace 
classdef DataCleaningWorkspace < internal.matlab.variableeditor.MLWorkspace & dynamicprops
    
    properties(Access='public')
        % Table's Categorical Variable Name 
        VariableName;
    end
    
    properties(Constant)
        % Internal prop. to access the cat cleaner table containing the
        % categories and counts
        InternalTableProp = 'CatCleanerTable';
    end
    
    properties(Access='protected')
        % the search string applied
        SearchStrings_I;
        IndexMap_I;
        
        % the original table
        OrigTable_I;
        OrigTableName_I
        
        % the categorical cleaner with the column summary
        CategorySummaryTable_I;
        
        % the displayed summary. If no search string is applied then this
        % is the same as the category summary table
        DisplayedCategorySummaryTable_I; 
        
        % removed categories list
        RemovedCategories_I;
        
        % merged categories list
        MergedCategories_I;
        
        % add categories list
        AddedCategories_I;
        
        % renamed categories list;
        RenamedCategories_I;
        
        % data cleaning actions cache (code stack)
        CodeGenerated_I;
    end
    
    methods
        function this = DataCleaningWorkspace(outputName, outputData, variableName, variableDataSummary)
            this.OrigTableName_I = outputName;
            this.OrigTable_I = outputData;
            this.VariableName = variableName;

            this.CategorySummaryTable_I = variableDataSummary;
            this.DisplayedCategorySummaryTable_I = variableDataSummary;
            
            % set the variable in the workspace with the variable name and
            % the DisplayedSummaryData
            this.setVariableValue(this.InternalTableProp, this.DisplayedCategorySummaryTable_I);
            this.setVariableValue(this.OrigTableName_I, this.OrigTable_I);
            
            % create an index map 
            if ~isempty(variableDataSummary)
                this.IndexMap_I = containers.Map(cellstr(variableDataSummary.Categories), [1:length(variableDataSummary.Categories)]');
            end            
        end
        
        function setVariableValue(this, varName, varValue, doNotify)
            internalVariableName = [varName '_I'];
            if ~isprop(this, varName)
                % Create an hidden internal property
                p = addprop(this, internalVariableName);
                p.Hidden = true;
                p.SetAccess = 'protected';
                this.(internalVariableName) = varValue;

                p = addprop(this, varName);
                getFcn = @(o)getPropVal(o,varName);
                setFcn = @(o,v)setPropVal(o,varName,v);
                p.GetMethod = getFcn;
                p.SetMethod = setFcn;
            else
                this.(internalVariableName) = varValue;
                if (nargin>3 && doNotify)                    
                    notify(this, 'VariablesChanged');
                end
            end
        end         
        
        function isSearched = isSearchedState(this)
            isSearched = ~isempty(this.SearchStrings_I);
        end
        
        function originalIndices = getUnsearchedIndices(this, categoryNames, varName)
            originalIndices = zeros(1, length(categoryNames));
            % get the unsearched table indices for the categoryNames corresponding to the 
            % rowIndices in the searched table
            categories = this.([varName '_I']).Categories;
            this.IndexMap_I = containers.Map(cellstr(categories), [1:length(categories)]');
            
            % indexmap stores the row indices in the unsearched table
            for i=1:length(categoryNames)                
                % get the index corresponding to the category Name
                originalIndices(i) = this.IndexMap_I(categoryNames{i});                
            end
        end
        
        %%
        % Search Functions
        
        % returns the unsearched table
        function unsearchedTable = getUnsearchedTable(this, varName)
            unsearchedTable = this.([varName '_I']);
        end
        
        % sets the search string and updates the view to show 
        % entries matching the search
        function searchVariable(this, searchString)
            this.SearchStrings_I = searchString;
            try
                notify(this, 'VariablesChanged');
            catch
                % Ignore the exceptions
            end
        end
        
        % clears the search string
        function clearSearch(this)            
            this.SearchStrings_I = [];
            
            try
                notify(this, 'VariablesChanged');
            catch
                % Ignore the exceptions
            end
        end
        
        function ismatches = isMatchesSearchCriteria(this, str)
            ismatches = contains(lower(str), lower(this.SearchStrings_I));
        end
        
        %% Selection Functions
        
        function selectedRows = getSelectedRowsUnsearchedTable(this)
            selectedRows = this.SelectedRowsInUnsearchedTable_I;
        end
        
        function updateSelectedRowsInUnsearchedTable(this, selection)
            this.SelectedRowsInUnsearchedTable_I = selection;
        end
        
        %%
        % Workspace keeps record of the cleaned categories 
        % This is needed when the user performs multiple operations of the
        % same type and we want to generate consolidated code
        % Ex: Performs 3 remove operations in a sequence
        
        % Removed categories 
        % Updates the list of categories removed till now
        function updateRemovedCategoriesList(this, removedCategories)
            if isempty(this.RemovedCategories_I)
                this.RemovedCategories_I = {};
            end
            this.RemovedCategories_I = [this.RemovedCategories_I, removedCategories];
        end
        
        % returns the categories removed till now
        function removedCategories = getRemovedCategoriesList(this)
            removedCategories = this.RemovedCategories_I;
        end
                
        % Merged categories
        % mergedCategories is a struct array where each field is the target
        % merged category and the corresponding values are the categories which 
        % have been merged into it        
        function updateMergedCategoriesList(this, mergedCategories)
            if isempty(this.MergedCategories_I)
                this.MergedCategories_I = containers.Map();
            end
            
            if isempty(mergedCategories)
                return;
            end
            
            % check if the target merged category is an existing field in
            % the struct (target merged category is the first element of the 
            % mergedCategories array)
            targetCategory = mergedCategories{1};
            if isKey(this.MergedCategories_I, targetCategory)
                % add the remaining  actegories to this field's value
                this.MergedCategories_I(targetCategory) = [this.MergedCategories_I(targetCategory), ...
                    mergedCategories{2:end}];                
            else                
                % categories are being merged to a new category
                this.MergedCategories_I(targetCategory) = mergedCategories;
            end            
        end
        
        function mergedCategories = getMergedCategoriesList(this, targetCategory)
            % check if there exists any fields correponding to the
            % target catehory passed in
            mergedCategories = [];
            if isempty(targetCategory)
                return;
            end
            
            if ~isempty(this.MergedCategories_I) && isKey(this.MergedCategories_I, targetCategory)
                mergedCategories = this.MergedCategories_I(targetCategory);
            end                
        end
        
        % Added categories        
        function updateAddedCategoriesList(this, addedCategories)
             if isempty(this.AddedCategories_I)
                this.AddedCategories_I = {};
             end
             this.AddedCategories_I = [this.AddedCategories_I, addedCategories];
        end
        
        function addedCategories = getAddedCategoriesList(this)
            addedCategories = this.AddedCategories_I;
        end
        
        % Renamed Categories
        % We need to maintain the list so that if a user 
        % 1. edits A->B then edits B->C, we want to generate A->C only
        % 2. edits A->B then edits A->C, we want to generate A->C only
        function updatedRenamedCategoriesList(this, oldCategoryName, newCategoryName)
            % if map is empty then add the key-value pair to the map
            if isempty(this.RenamedCategories_I)
                this.RenamedCategories_I = containers.Map();
            end
            
            % if the oldCategory name is in the keyset, then map it to the newcategory name
            if this.RenamedCategories_I.isKey(oldCategoryName)
                this.RenamedCategories_I(oldCategoryName) = newCategoryName;
            else
                % if oldCategory name is in the valueset then map its key to
                % the new category name 
                values = this.RenamedCategories_I.values;
                if ~isempty(values)
                    index = find(strcmp(values, oldCategoryName), 1);
                    if ~isempty(index)
                        keys = this.RenamedCategories_I.keys;
                        key = keys{index};
                        this.RenamedCategories_I(key) = newCategoryName;
                    end
                else
                    % if brand new key-value pair, then add to the list
                    this.RenamedCategories_I(oldCategoryName) = newCategoryName;
                end
            end

        end
        
        function renamedCategories = getRenamedCategoriesList(this)
            if isempty(this.RenamedCategories_I)
                this.RenamedCategories_I = containers.Map();
            end
            
            renamedCategories = this.RenamedCategories_I;
        end
        
        function resetCategoriesLists(this)
            this.RemovedCategories_I = [];
            this.MergedCategories_I = [];
            this.AddedCategories_I = [];
            this.RenamedCategories_I = [];
        end
        
        %%
        % Workspace keeps track of all the code corresponding to clean 
        % operations performed.
        
        % updates the array of code generated till now
        function updateGeneratedCode(this, codeGenerated, isBoundaryCondition)
            if isBoundaryCondition
                this.CodeGenerated_I = [this.CodeGenerated_I, codeGenerated];
            else
                % if it is not a boundary condition then update the last
                % command
                this.CodeGenerated_I(end) = codeGenerated;
            end
        end 
        
        % returns the array of code generated till now
        function codeGenArray = getCodeGeneratedArray(this)
            codeGenArray = this.CodeGenerated_I;
        end
        
        % required only for testing
        function resetCodeGeneratedArray(this)
            this.CodeGenerated_I = [];
        end
        
        %%
        % General Accessor methods
        
        % returns the output name
        function outputName = getOutputName(this)
            outputName = this.OrigTableName_I;
        end
        
        function outputData = getOriginalOutputData(this)
            outputData = this.OrigTable_I;
        end
    end
    
    methods(Access='private')
        function setPropVal(this, varName, varValue)
            % Commenting this out since on editing cells in the table,
            % we fire data changed which updates the data in the cleaner
            % for the unsearched state also. This results in the wrong row reading
            % the new value. Currently calling setVariableValue for updating            
%             eq = isequal(this.(varName), varValue) && ...
%                 ((istable(varValue) || istimetable(varValue)) &&...
%                 isempty(this.doCompare(this.(varName), varValue)));
%             if ~eq
%                 this.([varName '_I']) = varValue;
%                 notify(this, 'VariablesChanged');  
%             end
        end
                
        function val = getPropVal(this, varName)
            val = this.([varName '_I']);
            if isequal(varName, this.OrigTableName_I)
                return;
            end
            filter = this.SearchStrings_I;
            if ~isempty(filter)
                val = val(contains(string(val.Categories), filter, 'IgnoreCase', true),:);
            end
        end
        
        function [I,J] = doCompare(this, origData, newData)
            % If we have cell columns OR if the table variable names have changed
            % don't bother trying to figure out the differences just assume everything changed
            colNameChanged = ~isempty(setdiff(origData.Properties.VariableNames, newData.Properties.VariableNames));
            
            [~, I] = setdiff(origData, newData);
            if length(I) == 1
                [~,J] = find(cellfun(@(a,b) ~isequal(a,b), table2cell(origData(I,:)), table2cell(newData(I,:))));
                if length(J) > 1
                    [I,J] = meshgrid(I,J); 
                end
            else
                J = 1:width(origData);
                [I,J] = meshgrid(I,J); 
            end
        end
    end
end

