classdef RenameAction < internal.matlab.variableeditor.VEAction & internal.matlab.variableeditor.Actions.struct.EditActionBase
    % RenameAction puts the 'Name' column of the currently selected row into
    % edit mode.

    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'VariableEditor.struct.rename';
        EditField = 'Name';
    end
    
    methods
        function this = RenameAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.struct.RenameAction.ActionType;
            props.Enabled = true;  
            this@internal.matlab.variableeditor.Actions.struct.EditActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.editField;
        end
    end
end

