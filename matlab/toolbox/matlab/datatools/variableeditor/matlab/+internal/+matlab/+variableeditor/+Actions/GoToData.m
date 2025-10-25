classdef GoToData < internal.matlab.variableeditor.VEAction 
    % This class defines the action to go to the location in current variable view

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'GoToData'
    end

    methods
        function this = GoToData(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.GoToData.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.navigateToLocation;
        end

        function navigateToLocation(this, gotoInfo)
            focusedDoc = this.veManager.FocusedDocument;
            if ~isempty(focusedDoc)
                viewModel = focusedDoc.ViewModel;
                data = viewModel.DataModel.Data;

                rowVal = gotoInfo.actionInfo.row;
                colVal = gotoInfo.actionInfo.col;
                % flags to check if row/colum is index or name
                rowIsIndex = gotoInfo.actionInfo.rowFlag;
                colIsIndex = gotoInfo.actionInfo.colFlag;

                rowIndex = 1;
                colIndex = 1;

                % set scroll value directly if rowVal/colVal is index
                if rowIsIndex
                    rowIndex = rowVal;
                end
                if colIsIndex
                    colIndex = colVal;
                end

                % try to match rowVal/colVal to rowNames/variableNames, if
                % matched, set the corresponding index to scroll value
                isMatched = true;
                % check if data is table/timetime datatype
                if isa(data, 'table') || isa(data, 'timetable')
                    rowNames = data.Properties.RowNames;
                    if ~rowIsIndex && ~isempty(rowNames)
                        tempRowIndex = find(strcmp(rowNames, rowVal),1);
                        if ~isempty(tempRowIndex)
                            rowIndex = tempRowIndex;
                        else
                            isMatched = false;
                        end
                    end
                    variableNames = data.Properties.VariableNames;
                    if ~colIsIndex && ~isempty(variableNames)
                        tempColIndex = find(strcmp(variableNames, colVal),1);
                        if ~isempty(tempColIndex)
                            colIndex = tempColIndex;
                        else
                            isMatched = false;
                        end
                    end
                % check if data is struct vector datatype
                elseif isa(data, 'struct')
                    fieldNames = fieldnames(data);
                    if ~colIsIndex && ~isempty(fieldNames)
                        tempColIndex = find(strcmp(fieldNames, colVal),1);
                        if ~isempty(tempColIndex)
                            colIndex = tempColIndex;
                        else
                            isMatched = false;
                        end
                    end
                elseif isa(viewModel, 'internal.matlab.variableeditor.peer.RemoteObjectArrayViewModel')
                    props = properties(data);
                    if ~colIsIndex && ~isempty(props)
                        tempColIndex = find(strcmp(props, colVal),1);
                        if ~isempty(tempColIndex)
                            colIndex = tempColIndex;
                        else
                            isMatched = false;
                        end
                    end
                end

                if isMatched
                    viewModel.scrollViewOnClient(rowIndex, colIndex);
                    viewModel.setCellFocusOnClient(rowIndex, colIndex);
                end
            end
        end

        % The Action will be disabled for scalar struct.
        function UpdateActionState(this)
            focusedDoc = this.veManager.FocusedDocument;
            if ~isempty(focusedDoc)
                viewModel = focusedDoc.ViewModel;
                data = viewModel.DataModel.Data;
                isEnabled = (~isempty(data));
                if isscalar(data) || ischar(data) || isa(viewModel, 'internal.matlab.variableeditor.MLUnsupportedViewModel') || isa(data, 'dataset')
                    isEnabled = false;
                end
                this.Enabled = isEnabled;
            end
        end

    end
end

