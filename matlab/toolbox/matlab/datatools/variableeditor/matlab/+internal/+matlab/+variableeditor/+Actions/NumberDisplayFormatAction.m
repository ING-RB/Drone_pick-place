classdef NumberDisplayFormatAction < internal.matlab.variableeditor.VEAction
    % This class is unsupported and might change or be removed without notice in
    % a future version.
    
    % This class reacts to number display format changes on the client
    % view.
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'NumberDisplayFormat'
    end
    
    methods
        function this = NumberDisplayFormatAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.NumberDisplayFormatAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.changeNumberDisplayFormat;
        end
        
      
        function changeNumberDisplayFormat(this, actionInfo)
            focusedDoc = this.veManager.FocusedDocument;
            if ~isempty(focusedDoc)
               viewModel = focusedDoc.ViewModel;
               viewModel.DisplayFormatProvider.NumDisplayFormat = actionInfo.format;
               eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
               size = viewModel.getTabularDataSize;
               eventdata.StartRow = 1;
               eventdata.StartColumn = 1;
               eventdata.EndRow = size(1);
               eventdata.EndColumn = size(2);
               viewModel.notify('DataChange', eventdata);
            end           
        end
        
        function  UpdateActionState(this)
            focusedDoc = this.veManager.FocusedDocument;
            if ~isempty(focusedDoc)
                data = focusedDoc.DataModel.Data;
                this.Enabled = isnumeric(data) || internal.matlab.datatoolsservices.VariableUtils.isContainerType(data);
            end
        end
    end
end

