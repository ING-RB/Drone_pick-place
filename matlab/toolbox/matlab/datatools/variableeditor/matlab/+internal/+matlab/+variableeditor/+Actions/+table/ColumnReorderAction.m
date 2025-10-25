classdef ColumnReorderAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase    
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles column reordering for tables and timetables in VE

    % Copyright 2022-2024 The MathWorks, Inc.  
    
    properties (Constant)
        ActionName = 'ColumnReorderAction';
    end
    
    methods
        function this = ColumnReorderAction(props, manager)            
            props.ID = internal.matlab.variableeditor.Actions.table.ColumnReorderAction.ActionName;           
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
        end
        
        function UpdateActionState(~)          
        end
    end
    
    methods(Access='protected')       
        % This method generates cmd to reorder columns in table/timetable
        % datatypes and chains executionCmd to update column widths
        % asynchronously
        function [cmd, executionCmd] = generateCommandForAction(~, focusedDoc, eventInfo)
            [cmd, executionCmd] = internal.matlab.variableeditor.Actions.table.ColumnReorderAction.getCommand(focusedDoc, eventInfo);
        end
    end

    methods(Static, Hidden)
        function [cmd, executionCmd] = getCommand(focusedDoc, eventInfo)
            data = focusedDoc.DataModel.getCloneData();
            cmd = '';
            executionCmd = '';
            if ~istabular(data) && ~isa(data, 'dataset')
                return;
            end
            sourceIndex = eventInfo.actionInfo.sourceIndex;
            targetIndex = eventInfo.actionInfo.targetIndex;
            if iscell(sourceIndex)
                sourceIndex = str2double(sourceIndex{1});
            end

            viewModel = focusedDoc.ViewModel;
            % Do not allow drop beyond table size.
            sz = viewModel.getTabularDataSize();
            targetIndex = min(targetIndex, sz(2));
            selectionIndex = targetIndex;
            if isa(data, 'timetable')
                sourceIndex = sourceIndex - 1;
                selectionIndex = targetIndex;
                targetIndex = targetIndex - 1;
            end
            endCol = targetIndex;
            % For timetables, discount time column.

            % For movement in incr direction, ensure we add to targetIndex
            if targetIndex > sourceIndex
                endCol = targetIndex + 1;
            end

            % The variableEditorMoveColumn function expects indices to be
            % based on the grouped columns, given target index already has flattened index
            cmd = variableEditorMoveColumn(data, focusedDoc.DataModel.Name, sourceIndex, endCol); 

            if ~ischar(focusedDoc.DataModel.Workspace)
                focusedDoc.DataModel.Workspace.evalin(cmd);
                cmd = '';
            end
            % Update selection on the target index.
            ss = viewModel.getSelection();
            viewModel.setSelection(ss{1},[selectionIndex selectionIndex]);
        end       
    end
end


