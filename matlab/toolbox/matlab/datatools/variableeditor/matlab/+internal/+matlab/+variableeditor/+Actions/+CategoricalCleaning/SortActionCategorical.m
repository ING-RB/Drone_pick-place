classdef SortActionCategorical < internal.matlab.variableeditor.VEAction & internal.matlab.variableeditor.Actions.CategoricalCleaning.CleanCategoriesActionBase
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Class to handle sort actions in the categorical cleaner UI
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'SortActionCategorical'
    end

    methods
        function this = SortActionCategorical(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.CategoricalCleaning.SortActionCategorical.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.Sort;
            this.Manager = manager;            
        end
        
        function Sort(this, sortInfo)
            doc = this.getOutputDocument(this.Manager, sortInfo.docID);

            index = sortInfo.actionInfo.index + 1;
            order = sortInfo.actionInfo.order;
            if strcmpi(order, 'ASC')
                direction = 'ascend';
            else
                direction = 'descend';
            end            
            
            sh = doc.ViewModel.ActionStateHandler;
            
            % retrieve the selected rows from the selection event
            % information. Selection is preserved on a sort if only one row
            % is selected. If many rows are selected, we blow away
            % selection.
            selection = sortInfo.actionInfo.selection;
            selectedRows = [];
            if ~isempty(selection)
                selectedRows = this.getSelectedRows(selection);
            end
            
            % get the order value of the selected rows
            if ~isempty(selectedRows) && length(selectedRows) == 1
                data = doc.DataModel.Data;                
                selectedOrderValue = data(selectedRows(1),:).Order;                
            end
                        
             % Performs the sort by calling the sortrows command
            sh.DataModel.Data = sortrows(sh.DataModel.Data, index, direction);
                        
            sh.updateClientView();
            
            vm = doc.ViewModel;
            % set selection to the selectedOrderValues
            if ~isempty(selectedRows) && length(selectedRows) == 1                               
                newSelectedRow = ...
                        find(doc.DataModel.Data.Order == selectedOrderValue);                
                vm.setSelection([newSelectedRow, newSelectedRow], []);
            end
            
            % update the workspace with the new data
            workspace = doc.Workspace;
            colName = doc.DataModel.Name;
            % if table is in searched state then call sort rows on the
            % unsearched table and update the workspace
            if workspace.isSearchedState()
                unsearchedTable = this.sortUnsearchedTable(index, direction, doc);
                workspace.setVariableValue(colName, unsearchedTable);
            else
                % update the workspace
                workspace.setVariableValue(colName, doc.DataModel.Data);
            end
        end
        
        function unsearchedTable = sortUnsearchedTable(~, index, direction, doc)
            workspace = doc.Workspace;
            colName = doc.DataModel.Name;

            unsearchedTable = workspace.getUnsearchedTable(colName);
            unsearchedTable = sortrows(unsearchedTable, index, direction);
        end
        
         function  UpdateActionState(this)
            this.Enabled = true;
         end
         
    end
end

