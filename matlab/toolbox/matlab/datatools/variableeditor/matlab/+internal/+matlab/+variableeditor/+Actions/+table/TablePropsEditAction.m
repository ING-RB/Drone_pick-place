classdef TablePropsEditAction < internal.matlab.variableeditor.VEAction
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles action callback for summoning table property
    % editor on a side panel.

    % Copyright 2021-2023 The MathWorks, Inc.  
    
    properties (Constant)
        ActionName = 'TablePropsEdit';
    end
    
    methods
        function this = TablePropsEditAction(props, manager)            
            props.ID = internal.matlab.variableeditor.Actions.table.TablePropsEditAction.ActionName;           
            props.Enabled = true;
            props.MenuActionEnabled = jsonencode(struct('TablePropsEdit', true, 'VariablePropsEdit', true));
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.showTablePropEditor;
        end
        
        % Update state of menu items, TablePropsEdit is always enabled. 
        % If this is not a columnSelection, disable VariablePropsEdit
        function UpdateActionState(this)
            doc = this.veManager.FocusedDocument;
            if ~isempty(doc) && isa(doc.ViewModel, 'internal.matlab.variableeditor.TableViewModel')
                view = doc.ViewModel;
                % If brushing mode is enabled, turn off propediting action
                % as row-based selection is being used to drive brushing.
                mode = view.getProperty('BrushingMode');
                if ~isempty(mode) && mode
                    menuEnabled = struct('TablePropsEdit', false, 'VariablePropsEdit', false);
                else
                    s = view.getSelection();
                    rowSelection = s{1};
                    colSelection = s{2};
                    menuEnabled = struct('TablePropsEdit', true, 'VariablePropsEdit', true);
                    sz = view.getTabularDataSize();
                    allRowsSelected = sz(1) == 1 || (size(rowSelection,1) == 1 && (rowSelection(2) - rowSelection(1) + 1 >= sz(1)));
                    isColSelection = ~isempty(colSelection) && allRowsSelected;
                    if ~isColSelection
                        menuEnabled.VariablePropsEdit = false;
                    end
                end
                this.MenuActionEnabled = jsonencode(menuEnabled);
            end
        end
    end
    
    methods(Access='protected')       
        function showTablePropEditor(this, propInfo)
            focusedDoc = this.veManager.FocusedDocument;
            message.publish('/TablePropsEditAction', struct('widgetName', focusedDoc.Name, 'EditType', propInfo.menuID));
        end
    end
end


