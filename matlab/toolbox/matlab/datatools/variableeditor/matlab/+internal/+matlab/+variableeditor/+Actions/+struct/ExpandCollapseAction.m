classdef ExpandCollapseAction < internal.matlab.variableeditor.VEAction        
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Class to handle sort actions in scalar structs, Variable Editor
    
    % Copyright 2022-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'ExpandCollapseAction'
    end

    properties(Access=private)
        ExpandCollapseState
    end
    
    methods
        function this = ExpandCollapseAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.struct.ExpandCollapseAction.ActionType;
            props.Enabled = true;
            menuEnabledInfo = struct( ...
                'Expand', true, 'ExpandField', true, 'ExpandAllInField', true, 'ExpandAll', true, ...
                'Collapse', true, 'CollapseField', true, 'CollapseAllInField', true, 'CollapseAll', true ...
            );
            props.MenuActionEnabled = jsonencode(menuEnabledInfo);
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.onExpandCollapse;
        end
        
        function onExpandCollapse(this, actionInfo)            
            actionPerformed = actionInfo.menuID;
            doc = this.veManager.FocusedDocument;
            vm = doc.ViewModel;
            switch actionPerformed
                case 'ExpandField'
                    rows = this.getRowsFromSelection(vm);
                    vm.expand(rows);
                case 'ExpandAllInField'
                    % vm will expand all of the SelectedFields
                    vm.expandAllInField();
                case 'ExpandAll'
                    vm.expandAll();
                case 'CollapseField'
                    rows = this.getRowsFromSelection(vm);
                    vm.collapse(rows);
                case 'CollapseAllInField'
                    % vm will expand all of the SelectedFields
                    vm.collapseAllInField();
                case 'CollapseAll'
                    vm.collapseAll();
            end
        end       
        
        function  UpdateActionState(this)
            doc = this.veManager.FocusedDocument;
            if ~isempty(doc) && isa(doc.ViewModel, 'internal.matlab.variableeditor.StructureTreeViewModel')
                % The expand/collapse action has two menu options ("Expand" and "Collapse"),
                % and each of these options have their own sub-menu options.
                menuEnabled = struct( ...
                    'Expand', true, 'ExpandField', true, 'ExpandAllInField', true, 'ExpandAll', true, ...
                    'Collapse', true, 'CollapseField', true, 'CollapseAllInField', true, 'CollapseAll', true ...
                );

                % If the entire tree struct is already fully expanded, disable all expansion items
                % (and do the same for collapse).
                % If any sub-menu item remains enabled, the corresponding menu item will be enabled
                % on the client.
                if doc.ViewModel.IsFullyExpanded
                    menuEnabled.Expand = false;
                    menuEnabled.ExpandField = false;
                    menuEnabled.ExpandAllInField = false;
                    menuEnabled.ExpandAll = false;
                elseif doc.ViewModel.IsFullyCollapsed
                    menuEnabled.Collapse = false;
                    menuEnabled.CollapseField = false;
                    menuEnabled.CollapseAllInField = false;
                    menuEnabled.CollapseAll = false;
                end

                % For every selected row:
                selectedRowIDs = doc.ViewModel.SelectedFields;
                for i=1:length(selectedRowIDs)
                    fname = selectedRowIDs(i);
                    try
                        fieldData = doc.ViewModel.getFieldData(doc.DataModel.Data, fname);
                        isExpandable = doc.ViewModel.checkExpandability(fieldData);

                        % If this specific row is not expandable, disable the expand/collapse options.
                        if ~isExpandable
                            menuEnabled = this.disableLocalExpandCollapseOptions(menuEnabled);
                            break;
                        end
                    catch
                        menuEnabled = this.disableLocalExpandCollapseOptions(menuEnabled);
                        break;
                    end
                end

                this.MenuActionEnabled = jsonencode(menuEnabled);
            end
        end
    end

    methods(Access='private')
        function menuEnabledInfo = disableLocalExpandCollapseOptions(~, menuEnabledInfo)
            menuEnabledInfo.Expand = menuEnabledInfo.ExpandAll; % Keep "Expand" enabled if "Expand All" is enabled
            menuEnabledInfo.ExpandField = false;
            menuEnabledInfo.ExpandAllInField = false;

            menuEnabledInfo.Collapse = menuEnabledInfo.CollapseAll; % Keep "Collapse" enabled if "Collapse All" is enabled
            menuEnabledInfo.CollapseField = false;
            menuEnabledInfo.CollapseAllInField = false;
        end

        function rows = getRowsFromSelection(~, viewModel)
            selection = viewModel.getSelection();
            selectedRows = selection{1};
            rows = [];
            for i=1:height(selectedRows)
                rows = [rows selectedRows(i,1):selectedRows(i,2)];
            end
        end
    end
end

