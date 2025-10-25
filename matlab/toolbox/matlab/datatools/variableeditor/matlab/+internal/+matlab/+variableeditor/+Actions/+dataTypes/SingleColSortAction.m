classdef SingleColSortAction < internal.matlab.variableeditor.Actions.dataTypes.SortAction
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles Single Column Sort in ascending-descending order

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'SingleColSortAction'
    end

    methods
        function this = SingleColSortAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.dataTypes.SingleColSortAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.dataTypes.SortAction(props, manager);
        end
    end

    methods(Access='protected')

        % Irrespective of selection, Single column sort action is always valid
        function isValid = isValidSelection(this, sRows, sCols, sz)
            isValid = true;
        end

        function sel = getSelectionIndices(this, focusedView, actionInfo)
            [~, idx] = focusedView.getHeaderInfoFromIndex(actionInfo.index + 1);
            sel = [idx idx];
        end

        function cmd = generateCommandForTabularViews(this, focusedDoc, actionInfo, missingPlacementValue)
            % Todo: Simplify actionInfo datatype on client.
            if isfield(actionInfo, 'actionInfo')
                menuID = actionInfo.actionInfo.menuID;
                actionInfo = struct('menuID', menuID, 'index', actionInfo.actionInfo.index);
            end
            try
                cmd = this.generateCommandForTabularViews@internal.matlab.variableeditor.Actions.dataTypes.SortAction(focusedDoc, actionInfo, missingPlacementValue);  
                sh = focusedDoc.ViewModel.ActionStateHandler;
                % Push code to ActionStateHandler so that this can work
                % interchangeably with Filtering
                sh.getCodegenCommands(actionInfo.index, "Sort");
                sh.updateCodeArrayState();
            catch me
            end
        end
    end
end

