classdef DeleteDataAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles Delete Row/Delete Column actions on
    % base array-like datatypes.
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'DeleteData'
    end  
 
    
    methods
        function this = DeleteDataAction(props, manager)            
            props.ID = internal.matlab.variableeditor.Actions.dataTypes.DeleteDataAction.ActionName;           
            props.Enabled = true; 
            props.MenuActionEnabled = jsonencode(struct('DeleteRow', true, 'DeleteColumn', true));
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
        end
        
        % Updates action state for delete row/delete column.
        % For timetables, Times column is not deletable. 
        % For tables/timetables, do not allow delete column if this is a
        % nx1 table and do not allow delete row if this is a 1xn table.
        function toggleEnabledState(this, isEnabled)
            % toggleEnabledState is called only when focusedDoc exists and
            % is of the right type
            view = this.Manager.FocusedDocument.ViewModel;
            if isa(view, 'internal.matlab.variableeditor.peer.RemoteObjectArrayViewModel')
                % Delete should not be available for objects arrays.
                isEnabled = false;
            elseif isa(view, 'internal.matlab.variableeditor.ArrayViewModel') && ...
                    ~isa(view, 'internal.matlab.variableeditor.ObjectViewModel')
                % Delete should not be available for scalar objects. (Only edgecase with scalar struct views)
                data = view.DataModel.Data;
                if isprop(view.DataModel, 'DataI')
                    data = view.DataModel.DataI;
                end
                % Action not supported in ND arrays
                if ndims(data) > 2
                    this.Enabled = false;
                    return;
                end
                s = view.getSelection();
                rowSelection = s{1};
                colSelection = s{2};

                % isEnabled for DeleteRow and DeleteColumn defaults are driven by
                % DataTypesActionBase, which toggles based on whether this is a
                % valid selection taking InfiniteGrid into account.
                menuEnabled = struct('DeleteRow', isEnabled, 'DeleteColumn', isEnabled);
                if isa (view, 'internal.matlab.variableeditor.TimeTableViewModel')                        
                    if any(ismember(colSelection, 1))
                        menuEnabled.DeleteColumn = false;
                    end
                end                    
                sz = view.getSize();
                if ~isempty(colSelection) && ~isempty(rowSelection)
                    % When selection includes infinite grid ranges, account for > size while checking for vector
                    % selection ranges.
                    allColsSelected = (sz(2) == 1 || (size(colSelection, 1) == 1 &&(colSelection(2) - colSelection(1) + 1 >= sz(2))));
                    allRowsSelected = sz(1) == 1 || (size(rowSelection,1) == 1 && (rowSelection(2) - rowSelection(1) + 1 >= sz(1)));
                    invalidSelection = ~(allColsSelected || allRowsSelected);
                    % Turn off the menu items if we do not have a valid
                    % selection
                    if allColsSelected || invalidSelection
                        menuEnabled.DeleteColumn = false;
                    end
                    if allRowsSelected || invalidSelection
                        menuEnabled.DeleteRow = false;
                    end     

                    % Allow column deletion for arrays, even if all rows &
                    % columns are selected -- except for "structured"
                    % containers like tables and struct arrays.
                    if allColsSelected && allRowsSelected && ...
                            ~(istabular(data) || isstruct(data) || isa(data, "dataset") || ischar(data))
                        menuEnabled.DeleteRow = false;
                        menuEnabled.DeleteColumn = true;
                    end
                     % If neither of these options are enabled, disable the
                     % overall menu.
                    if ~menuEnabled.DeleteColumn && ~menuEnabled.DeleteRow
                        isEnabled = false;
                    end
                end
                this.MenuActionEnabled = jsonencode(menuEnabled);
            else
                isEnabled = false;
            end
            % Overall action is enabled or disabled based on the
            % current selection.
            this.Enabled = isEnabled;
        end
    end
    
    methods(Access='protected')
        % generates code for DeleteRow/DeleteColumn actions for individual datatypes.
        function [cmd, executionCmd] = generateCommandForAction(this, focusedDoc, actionInfo)
            %% TODO: Remove
            % This is tech debt. that we are introducing to enable sorting
            % via the header menu for tables in the MOTW VE. Remove this
            % once the ADS is switched to Mf0 and the contract to send
            % information across is established.
            if isfield(actionInfo, 'actionInfo')
                menuID = actionInfo.actionInfo.menuID;
                actionInfo = struct('menuID', menuID);
            end

            selection = focusedDoc.ViewModel.getSelection;
            executionCmd = '';
            variableName = focusedDoc.Name;
            focusedView = focusedDoc.ViewModel;
            data = focusedView.DataModel.getCloneData;
            if strcmp(actionInfo.menuID, 'DeleteColumn')
                if isstring(data)
                    cmd = internal.matlab.array.StringArrayVariableEditorAdapter.variableEditorColumnDeleteCode(...
                        data, variableName, selection{2});
                elseif isstruct(data)
                    varSize = size(data);           
                    if length(varSize) == 2 && (varSize(1) == 1 || varSize(2) == 1)
                        cmd = internal.matlab.array.StructArrayVariableEditorAdapter.variableEditorColumnDeleteCode(...
                             data, variableName, selection{2});
                    else
                        cmd = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.variableEditorColumnDeleteCode(...
                         data, variableName, selection{2});
                    end
                elseif (isnumeric(data) || islogical(data) || iscell(data) || this.isObjectArray(data))
                    cmd = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.variableEditorColumnDeleteCode(...
                         data, variableName, selection{2});
                elseif istabular(data)
                    cmd = this.variableEditorColDeleteForTabularTypes(focusedView, data, variableName, selection{2});
                else
                    cmd  = variableEditorColumnDeleteCode(data, variableName, selection{2});
                end
            elseif strcmp(actionInfo.menuID, 'DeleteRow')
                if isstring(data)
                    cmd = internal.matlab.array.StringArrayVariableEditorAdapter.variableEditorRowDeleteCode(...
                        data, variableName, selection{1});
                elseif isstruct(data)
                    varSize = size(data);           
                    if length(varSize) == 2 && (varSize(1) == 1 || varSize(2) == 1)
                        cmd = internal.matlab.array.StructArrayVariableEditorAdapter.variableEditorRowDeleteCode(...
                             data, variableName, selection{1});
                    else
                         cmd = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.variableEditorRowDeleteCode(...
                         data, variableName, selection{1});
                    end
                elseif (isnumeric(data) || islogical(data) || iscell(data) || this.isObjectArray(data))
                    cmd = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.variableEditorRowDeleteCode(...
                         data, variableName, selection{1});
                else
                    cmd  = variableEditorRowDeleteCode(data, variableName, selection{1});
                end
            end
        end

        function cmd = variableEditorColDeleteForTabularTypes(this, focusedView, data, variableName, colSelection)
            % This code expects raw columns not variable columns (so in the
            % case of grouped columns there is no need to adjust the
            % selection to the actual variable column).
            %
            % TODO: When we support nested tables in the Variable Editor we
            % will need to modify the variableEditorColumnDeleteCode to
            % handle them
            cmd  = variableEditorColumnDeleteCode(data, variableName, colSelection);
        end
    end
end


