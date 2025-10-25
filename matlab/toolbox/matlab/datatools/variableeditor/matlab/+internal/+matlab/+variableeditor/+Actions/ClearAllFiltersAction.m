classdef ClearAllFiltersAction < internal.matlab.variableeditor.VEAction
    %ClearAction
    %        clear all variables in workspacebroswer
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'ClearAllFiltersAction'
    end
    
    methods
        function this = ClearAllFiltersAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.ClearAllFiltersAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.ClearAllFilters;
        end
        
        function ClearAllFilters(this, clearAllFiltersInfo)
            % get the command Array of the table
            idx = arrayfun(@(x) isequal(x.DocID, clearAllFiltersInfo.docID), this.veManager.Documents);
            sh = this.veManager.Documents(idx).ViewModel.ActionStateHandler;
            codeExecutionArray = sh.CodeExecutionArray;
            mapCodeExecutionToCommand = sh.MapExecutionCodeToCommand;
            commandArray = sh.CommandArray;
            
            for i=1:length(codeExecutionArray)
                executionCommandIndex = mapCodeExecutionToCommand(i);
                executionCommand = commandArray(executionCommandIndex);
                if strcmp(executionCommand.Command, 'Filter')
                    tws = internal.matlab.variableeditor.Actions.UndoAction.getFilteringWorkspace(clearAllFiltersInfo);
                    colIndex = executionCommand.Index;
                    colName = sh.ViewModel.getHeaderInfoFromIndex(colIndex);
                    % clear current filtering                        
                    % If the current filter column is of type
                    % Numeric, then reset the filterFigure
                    if tws.isSupportedNumeric(sh.DataModel.Data.(colName))                             
                        % Do not notify here, notify after
                        % includeMissing is reset.
                        tws.includeMissing(colName, false);
                        tws.clearNumericRange(colName);
                        actionInfo = struct('index', colIndex-1, 'userAction', 'SelectAll');
                        eventData = struct('actionInfo', actionInfo, 'docID', clearAllFiltersInfo.docID);
                        editTextBoxActionArgs = struct('EventData',eventData);
                        action = this.veManager.ActionManager.ActionDataService.getAction('EditTextboxAction');
                        actionInstance = action.Action;
                        actionInstance.EditTextbox(eventData);
                    % If the current filter column is of type Text, then dispatch SelectAll action 
                    elseif tws.isCategoricalLikeVariable(sh.DataModel.Data.(colName)) || tws.isLogicalVariable(sh.DataModel.Data.(colName))                            
                        actionInfo = struct('index', colIndex-1, 'userAction', 'SelectAll');
                        eventData = struct('actionInfo', actionInfo, 'docID', clearAllFiltersInfo.docID);
                        selectAllArgs = struct('EventData',eventData);
                        action = this.veManager.ActionManager.ActionDataService.getAction('EditCheckboxAction');
                        actionInstance = action.Action;
                        actionInstance.EditCheckbox(eventData);
                    end
                    sh.ViewModel.setColumnModelProperty(executionCommand.Index, 'IsFiltered', false);
                end
            end
            sh.ViewModel.setTableModelProperty('IsFiltered', false);
        end
                
        function  UpdateActionState(this)
           this.Enabled = true;
        end
    end
end

