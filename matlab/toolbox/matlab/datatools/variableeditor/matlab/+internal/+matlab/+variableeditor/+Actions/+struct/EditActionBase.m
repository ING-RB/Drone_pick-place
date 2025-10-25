classdef EditActionBase < handle
    %EDITACTIONBASE Base class that defines edit callback for structs containing
    % fieldColumns
    
    % Copyright 2022-2025 The MathWorks, Inc.

    properties (Transient, WeakHandle)
        Manager internal.matlab.variableeditor.MLManager;
    end
    
    properties (Abstract,Constant)
        EditField;
    end
    
    methods
        function this = EditActionBase(manager)
            arguments
                manager (1,1) internal.matlab.variableeditor.Manager
            end
            this.Manager = manager;
        end
        
        % Updates ActionState to set Action to enabled only when a single
        % row is selected.
        function UpdateActionState(this)
            focusedDoc = this.Manager.FocusedDocument;
            if ~isempty(focusedDoc) && (isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureViewModel') || ...
                    isa(focusedDoc.ViewModel, 'internal.matlab.desktop_workspacebrowser.DesktopWSBViewModel'))
                editable = focusedDoc.ViewModel.getTableModelProperty('editable');
                % if editable is not false, check more conditions to decide
                if (isempty(editable) || editable == true)
                    ss = focusedDoc.ViewModel.getSelection;
                    sRows = ss{1};
                    if isscalar(sRows)
                        editable = true;
                    else
                        editable = height(sRows) == 1 && (sRows(2)-sRows(1)+1 == 1);
                    end
                    % Only single row is selected, for struct trees, ensure
                    % this is not a field of a struct array.
                    if (editable && isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureTreeViewModel'))
                        fields = focusedDoc.ViewModel.getSelectedFields;
                        editable = ~focusedDoc.ViewModel.isStructArrayField(fields(1));
                    end
                end
                this.setEnabledState(editable);
            end
        end
    end
    
    methods(Access='protected')
        function setEnabledState(this, isEnabled)
            this.Enabled = isEnabled;
        end
        
        % Dispatch editCell peerEvent on 'EditField' column
         function editField(this)
             focusedDoc = this.Manager.FocusedDocument;
             if ~isempty(focusedDoc)
                 if isa (focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureViewModel') || ...
                         isa (focusedDoc.ViewModel, 'internal.matlab.desktop_workspacebrowser.DesktopWSBViewModel') || ...
                         isa (focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureTreeViewModel')
                    selection = focusedDoc.ViewModel.getSelection();
                    sRows = selection{1};  
                    col = focusedDoc.ViewModel.findFieldByHeaderName(this.EditField).ColumnIndex;
                    focusedDoc.ViewModel.dispatchEventToClient(struct('type','editCell', ...
                        'source', 'server', 'row',sRows(1),'column', col));
                 end
             end
         end
    end
end

