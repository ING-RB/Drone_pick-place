classdef NameCopyAction < internal.matlab.variableeditor.VEAction
    % NameCopyAction - Copies to clipboard from the view's current selection
    % for structs in the  the VariableEditor, and for the Workspace Browser
    
    % Copyright 2025 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'NameCopyAction';
    end
    
    methods
        function this = NameCopyAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.struct.NameCopyAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.CopyToClipboard;
            this.Enabled = true;
        end
        
        function CopyToClipboard(this, copyInfo)
            % g2631664: Disable the futher copy actions while one is
            % processing to prevent a potential slowdown.
            this.Enabled = false;

            idx = arrayfun(@(x) isequal(x.DocID, copyInfo.docID), this.veManager.Documents);
            doc = this.veManager.Documents(idx);
            if isempty(doc)
                doc = this.veManager.Documents;
            end
            vm = doc.ViewModel;

            currentSelection = vm.getSelection();
            rows = currentSelection{1};
            cols = currentSelection{2};
            % If no row or column selection exists, nothing to paste to
            % clipboard
            if isempty(rows) || isempty(cols)
                this.Enabled = true;
                return;
            end

            selFieldsDelimited = vm.SelectedFields;
            selFields = internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(selFieldsDelimited);
            strData = strjoin(selFields, ", ");
            clipboard('copy', strData);

            % Re-enable new copy action once it is finished 
            this.Enabled = true;
        end      
        
         function  UpdateActionState(~)
        end
    end 
end

