classdef EditAction < internal.matlab.variableeditor.VEAction & internal.matlab.variableeditor.Actions.struct.EditActionBase
    % EditAction puts the 'Value' column of the currently selected row into
    % edit mode.

    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'EditAction';
        EditField = 'Value';
    end

    methods
        function this = EditAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.struct.EditAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.struct.EditActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.editField;
        end         
    end
    
    methods(Access='protected')
        % Updates ActionState on EditAction. EditValue will not be available
        % if 'Value' column is hidden. 
        % For ScalarObjects, EditValue will only be available for public
        % editable properties.
        function setEnabledState(this, isEnabled)
            % We already check for view validity in editActionBase
            focusedView = this.Manager.FocusedDocument.ViewModel;
            col = focusedView.findFieldByHeaderName(this.EditField);
            % If Value Column is removed, disable edit action.
            if isEnabled 
                if isempty(col) || ~col.Visible
                    isEnabled = false;
                elseif isa(focusedView, 'internal.matlab.variableeditor.ObjectViewModel')
                    selection = focusedView.getSelection();
                    sRows = selection{1};
                    if ~isempty(sRows)
                        isEditableProp = focusedView.getCellModelProperty(sRows(1), col.ColumnIndex, 'editable');
                        if ~isempty(isEditableProp) && ~isEditableProp{1}
                            isEnabled = false;
                        end
                    end
                end   
            end           
            this.setEnabledState@internal.matlab.variableeditor.Actions.struct.EditActionBase(isEnabled);
        end
    end
end

