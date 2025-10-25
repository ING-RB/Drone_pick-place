classdef SortAction < internal.matlab.variableeditor.VEAction

    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Class to handle sort actions in scalar structs, Variable Editor

    % Copyright 2019-2025 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'StructSortAction'
    end

    methods
        function this = SortAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.struct.SortAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.Sort;
        end

        function Sort(this, sortInfo)
            order = sortInfo.actionInfo.order;
            column = sortInfo.actionInfo.index + 1;
            sortAscending = true;
            if strcmpi(order, 'DESC')
                sortAscending = false;
            end

            idx = arrayfun(@(x) isequal(x.DocID, sortInfo.docID), this.veManager.Documents);
            structDoc = this.veManager.Documents(idx);
            if ~isempty(structDoc)
                structView = structDoc.ViewModel;
                % Update sortedColumnInfo on the view which will trigger
                % SortIndices to be computed.
                fieldCol = structView.findVisibleField(column);
                structView.SortedColumnInfo = struct('ColumnIndex', fieldCol.ColumnIndex, 'SortOrder', sortAscending);

                eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                dims = structView.getTabularDataSize;
                eventdata.StartRow = 1;
                eventdata.EndRow = dims(1);
                eventdata.StartColumn = 1;
                eventdata.EndColumn = dims(2);
                eventdata.SizeChanged = false;
                structView.notify('DataChange', eventdata);
                structView.updateRowMetaData();
            end
        end

         function  UpdateActionState(this)
            this.Enabled = true;
         end
    end
end
