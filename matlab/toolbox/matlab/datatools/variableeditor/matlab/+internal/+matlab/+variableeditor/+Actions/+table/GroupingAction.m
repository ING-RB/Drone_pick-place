classdef GroupingAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles grouping and ungrouping table column variables.

    % Copyright 2020-2025 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'GroupingAction';
    end
    
    methods
        function this = GroupingAction(props, manager)            
            props.ID = internal.matlab.variableeditor.Actions.table.GroupingAction.ActionName;           
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
        end           
    end
    
    methods(Access='protected')       
       
        % This action is only supported for consecutive groupable columns
        % or a single ungroupable column. In addition to codegen, selection
        % is updated asynchronously once the table is grouped/ungrouped.
        function [cmd, callbackCmd] = generateCommandForAction(this, focusedDoc, actionInfo)
            import internal.matlab.variableeditor.Actions.ActionUtils;
            varName = focusedDoc.Name;
            focusedView = focusedDoc.ViewModel;
            selection = focusedView.getSelection();            
            tableData = focusedView.DataModel.getCloneData;
            % Selection could be out of order, sortrows so
            % grouping/ungrouping work as expected
            colSelection = sortrows(selection{2});
            % Grouped columns are all flat on the view, no need to update selection post grouping/ungrouping
            callbackCmd = '';
            if strcmp(actionInfo.menuID, 'GroupColumnVariable')             
                cmd = variableEditorGroupCode(tableData, varName, colSelection(1), colSelection(2));  
            elseif strcmp(actionInfo.menuID, 'UngroupColumnVariable')
                cmd = variableEditorUngroupCode(tableData, varName, colSelection(1));
            end 
        end
    end
end


