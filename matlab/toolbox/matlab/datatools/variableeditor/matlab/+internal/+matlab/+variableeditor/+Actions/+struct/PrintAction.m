classdef PrintAction < internal.matlab.variableeditor.VEAction
    %PRINTACTION This class is used to enable PrintAction in
    %VariableEditor/WorkspaceBrowser. 
    % NOTE: Print Action has a client side callback.
    
    % Copyright 2020-2024 The MathWorks, Inc.
 
    properties (Constant)
        ActionID = 'Variableeditor.print'
    end
    
    methods
        function this = PrintAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.struct.PrintAction.ActionID;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
        end
     
        % NOOP, by defaut the action is available
       function  UpdateActionState(this)
           focusedDoc = this.veManager.FocusedDocument;
           if ~isempty(focusedDoc)
              this.Enabled = ~isa(focusedDoc.DataModel.Data, 'dataset');
           end
       end
    end
end

