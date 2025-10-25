classdef InsertAction < internal.matlab.variableeditor.VEAction ...
        & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles insert action (insert column to left or right and
    % insert row above or below) for datatypes like numeric/logical/cell
    % arrays.
    % Copyright 2020-2023 The MathWorks, Inc.

    properties (Constant)
        ActionName = 'InsertRowColumn'
    end

    methods
        function this = InsertAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.dataTypes.InsertAction.ActionName;
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.SupportedInInfintieGrid = true;
        end

        % Turn off newWorkspaceVariable Action for object types
        function toggleEnabledState(this, isEnabled)
            view = this.Manager.FocusedDocument.ViewModel;
            if isa(view, 'internal.matlab.variableeditor.peer.RemoteObjectArrayViewModel')
                % Delete should not be available for objects arrays.
                this.Enabled = false;
                return;
            end


            if isEnabled
                focusedDoc = this.Manager.FocusedDocument;
                data = focusedDoc.DataModel.Data;
                if isprop(focusedDoc.DataModel, 'DataI')
                    data = focusedDoc.DataModel.DataI;
                end
                % Action not supported in ND arrays
                if ndims(data) > 2
                    this.Enabled = false;
                    return;
                end
                % Turn off InsertAction until it is supported for all
                % container types.
                if ~(isnumeric(data) || islogical(data) || iscell(data))
                    isEnabled = false;
                else
                    % Insert action must not be allowed until entire
                    % row/column is selected.
                    view = this.Manager.FocusedDocument.ViewModel;
                    if isa(view, 'internal.matlab.variableeditor.ArrayViewModel')
                        ss = view.getSelection();
                        sz = view.getSize();
                        rowSelection = ss{1};
                        colSelection = ss{2};
                        % If empty selection, do not update action state,
                        % This can happen on initial focus before selection update reaches server
                        % When selection includes infinite grid ranges, account for > size while checking for vector
                        % selection ranges.
                        if ~(isempty(rowSelection) && isempty(colSelection))
                            allColsSelected = (sz(2) == 1 || (size(colSelection, 1) == 1 &&(colSelection(2) - colSelection(1) + 1 >= sz(2))));
                            allRowsSelected = sz(1) == 1 || (size(rowSelection,1) == 1 && (rowSelection(2) - rowSelection(1) + 1 >= sz(1)));
                            if ~(allColsSelected || allRowsSelected)
                                isEnabled = false;
                            end
                        end
                    end
                end
            end
            this.Enabled = isEnabled;
        end
    end

    methods(Access='protected')

        % generates command for inserting a column/row to the left/right or
        % above/below the current selection based on the actionInfo.
        function [cmd, callbackCmd] = generateCommandForAction(this, focusedDoc, actionInfo)
            focusedView = focusedDoc.ViewModel;
            selection = {focusedView.UnclippedSelectedRows; focusedView.UnclippedSelectedColumns};
            data = focusedView.DataModel.Data;
            variableName = focusedDoc.Name;
            isCellArr = iscell(data);
            if isCellArr
                emptyValCmd = 'cell';
            else
                emptyValCmd = 'zeros';
            end
            % In Addition to the insert command, also update the current
            % selection on the client.
            callbackCmd = 'internal.matlab.variableeditor.Actions.dataTypes.InsertAction.updateSelection';
            if strcmp(actionInfo.menuID, 'InsertColumnLeft')
                [cmd, ~, colSelection] = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.insertColumnToLeftCode(...
                    data, variableName, selection{2}, emptyValCmd);
                callbackCmd = sprintf('%s(''%s'',''%s'',''%s'')', callbackCmd, this.Manager.Channel, ...
                    jsonencode(colSelection), 'true');
            elseif strcmp(actionInfo.menuID, 'InsertColumnRight')
                [cmd, ~, colSelection] = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.insertColumnToRightCode(...
                    data, variableName, selection{2}, emptyValCmd);
                callbackCmd = sprintf('%s(''%s'',''%s'',''%s'')', callbackCmd, this.Manager.Channel, ...
                    jsonencode(colSelection), 'true');
            elseif strcmp(actionInfo.menuID, 'InsertRowAbove')
                [cmd, ~, rowSelection] = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.insertRowAboveCode(...
                    data, variableName, selection{1}, emptyValCmd);
                callbackCmd = sprintf('%s(''%s'',''%s'',''%s'')', callbackCmd, this.Manager.Channel, ...
                    jsonencode(rowSelection), 'false');
            elseif strcmp(actionInfo.menuID, 'InsertRowBelow')
                [cmd, ~, rowSelection] = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.insertRowBelowCode(...
                    data, variableName, selection{1}, emptyValCmd);
                callbackCmd = sprintf('%s(''%s'',''%s'',''%s'')', callbackCmd, this.Manager.Channel, ...
                    jsonencode(rowSelection), 'false');
            end
        end
    end

    methods(Static)
        % selection is updated with the the provided selection (row or
        % col).
        % updateCol is 'true' if column selection is to be updated (restore
        % existing row selection) and 'false' if row selection is to be
        % updated (restore column selection)
        function updateSelection(channel, selection, updateCol)
            factory = internal.matlab.variableeditor.peer.VEFactory.getInstance;
            mgr = factory.createManager(channel, false);
            focusedView = mgr.FocusedDocument.ViewModel;
            currentSelection = focusedView.getSelection();
            selectionForUpdate = jsondecode(selection);
            % For a single range selection vector, jsondecode transposes the
            % matrix. Do not update selection if indices are empty
            if ~isempty(selectionForUpdate)
                if all(size(selectionForUpdate) == [2 1])
                    selectionForUpdate = selectionForUpdate';
                end
                if strcmp(updateCol, 'true')
                    rowSelection = currentSelection{1};
                    colSelection = selectionForUpdate;
                else
                    rowSelection = selectionForUpdate;
                    colSelection = currentSelection{2};
                end
                focusedView.setSelection(rowSelection, colSelection);
                focusedView.setUnclippedSelection(rowSelection, colSelection);
            end
        end
    end
end

