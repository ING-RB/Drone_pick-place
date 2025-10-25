classdef NewSortAction < internal.matlab.legacyvariableeditor.VEAction
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'NewSortAction'
    end
    
    properties
        Manager;
    end
    
    methods
        function this = NewSortAction(props, manager)
            props.ID = internal.matlab.legacyvariableeditor.Actions.NewSortAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.legacyvariableeditor.VEAction(props, manager);
            this.Callback = @this.NewSort;
            this.Manager = manager;
            
        end
        
        function NewSort(this, sortInfo)
            index = sortInfo.actionInfo.index + 1;
            order = sortInfo.actionInfo.order;
            if strcmpi(order, 'ASC')
                direction = 'ascend';
            else
                direction = 'descend';
            end
            
            idx = arrayfun(@(x) isequal(x.DocID, sortInfo.docID), this.Manager.Documents);
            sh = this.Manager.Documents(idx).ViewModel.ActionStateHandler;
            
            sh.ViewModel.setTableModelProperty('LastSorted', struct('index', index -1, 'order', order), true);
            
             % Performs the sort by calling the sortrows command
            sh.DataModel.Data = sortrows(sh.DataModel.Data, index, direction);
            
            % Sort the filtering workspace if filtering feature is enabled
            
            this.updateRowHeadersInViewModel(sh);
            sh.updateClientView(sortInfo.range);
            
            mCode = {this.sortCodeGen(sh, struct('Index', index, 'Direction', direction))};
            executionCode = {sprintf('tempDM = sortrows(tempDM, %d, char("%s"));', index, direction)};
            
            % commandArray contains a list of call the interactive sort commands issued for a output
            sh.CommandArray = [sh.CommandArray, struct('Command', "Sort", 'Index', index, 'commandInfo', direction, ...
                'generatedCode', {mCode}, 'executionCode', {executionCode})];
                
            sh.getCodegenCommands(index, "Sort");
            sh.publishCode();
        end
        
        function sortCode = sortCodeGen(~, sh, commandInfo)
            % Function to generate code for the sort operation
            idx = commandInfo.Index;
            varName = sh.Name;
            colName = sh.DataModel.Data.Properties.VariableNames{idx};
            
            dir = commandInfo.Direction;
            % Add the direction to the generated code only if descending
            if strcmp(dir, 'ascend')
                sortCode = [varName ' = sortrows(' varName ',' char(39) colName char(39) ');'];
            else
                sortCode = [varName ' = sortrows(' varName ',' char(39) colName char(39) ',' char(39) dir char(39) ');'];
            end
        end
        
        
        function updateRowHeadersInViewModel(~, sh)
            % Updates the row headers on the client side after sort is performed
            % Check if it is a timetable
            if istimetable(sh.DataModel.Data)
                temp = 'RowTimes';
            else
                temp = 'RowNames';
            end
            % Need to do this because header prop is different for TT
            if ~isempty(sh.DataModel.Data.Properties.(temp))
                for i = 1:height(sh.DataModel.Data)
                    sh.ViewModel.RowModelProperties{i}.RowName = char(sh.DataModel.Data.Properties.(temp)(i));
                end
            end
        end
        
         function  UpdateActionState(this)
            this.Enabled = true;
         end
         
    end
end

