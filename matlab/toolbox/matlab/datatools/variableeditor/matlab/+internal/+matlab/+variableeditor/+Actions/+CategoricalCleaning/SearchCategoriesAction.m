classdef SearchCategoriesAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.variableeditor.Actions.CategoricalCleaning.CleanCategoriesActionBase
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'SearchCategoriesAction';
    end

    methods
        function this = SearchCategoriesAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.CategoricalCleaning.SearchCategoriesAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.Callback = @this.SearchFilter;
            this.Manager = manager;
        end
        
        function SearchFilter(this, filtInfo)
            doc = this.getOutputDocument(this.Manager, filtInfo.docID);

            searchText = filtInfo.actionInfo.searchText;
            
            % Get the workspace
            dataCleaningWorkspace = doc.DataModel.Workspace;
            
            if isempty(searchText)
                dataCleaningWorkspace.clearSearch();
            else
                dataCleaningWorkspace.searchVariable(searchText);
            end
            catcleanerView = doc.ViewModel;
            dataSize = catcleanerView.getTabularDataSize();
            internal.matlab.variableeditor.peer.HeaderMenuStateHandler.refreshView(...
                catcleanerView, 1, dataSize(1), 1, dataSize(2));
        end
    end
end

