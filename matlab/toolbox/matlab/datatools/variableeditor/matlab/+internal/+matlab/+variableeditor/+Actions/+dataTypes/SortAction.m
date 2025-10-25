classdef SortAction < internal.matlab.variableeditor.VEAction ...
        & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.
    
    % This class handles Sort ascending and descending on base array-like
    % datatypes as well as tabular types like tables/timetables.
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'SortAction'
    end
    
    methods
        function this = SortAction(props, manager)
            if ~isfield(props, 'ID')              
                props.ID = internal.matlab.variableeditor.Actions.dataTypes.SortAction.ActionName;
            end 
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
        end
        
        % Turn off sorting for half datatypes as this is not supported.
        function toggleEnabledState(this, isEnabled)
            if isEnabled
                focusedDoc = this.Manager.FocusedDocument;
                data = focusedDoc.ViewModel.DataModel.Data;
                if ~isempty(focusedDoc)
                    view = focusedDoc.ViewModel;
                    if isa(data, 'half') || isa(data, 'char') || isa(data, 'calendarDuration') || (isnumeric(data) && ~isreal(data)) || ...
                            isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureViewModel') || ...
                            isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.ObjectArrayViewModel') || ...
                            isa(data, 'dataset') || ...
                            isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.MxNArrayViewModel')
                        isEnabled = false;
                    elseif isa(view, 'internal.matlab.variableeditor.ArrayViewModel')
                        ss = view.getSelectionIndices();
                        sz = view.getTabularDataSize();
                        sRows = ss{1};
                        sCols = ss{2};
                        % If empty selection, do not update action state,
                        % This can happen on initial focus before selection update reaches server
                        isEnabled = this.isValidSelection(sRows, sCols, sz);
                        if isEnabled && ~isempty(sCols) && isa(view, 'internal.matlab.variableeditor.TableViewModel')
                            % For tables alone,Set enabled only if current colSelection is sortable. (For E.g Mixed cols like cellarrays within tables are not sortable)                            
                            colNumbers = [];
                            for curr = sCols.'
                                colNumbers = [colNumbers curr(1):curr(2)];
                            end
                            if ~isempty(colNumbers) && sz(2) > 0
                                % Selection could still be updating after
                                % sizeChange, access upto max of the table size.
                                selectedTable = data(:, min(colNumbers, sz(2)));
                                isSortable = all(internal.matlab.variableeditor.peer.PeerUtils.checkIsSortable(selectedTable, false));
                                isEnabled = isSortable;
                            else
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
        % For multi-column sort, sorting action should be allowed only when
        % entire columns are selected.
        function isValid = isValidSelection(this, sRows, sCols, sz)
             isValid = true;
             if ~(isempty(sRows) && isempty(sCols))
                % If all rows are not selected, disable sort action
                allRowsSelected = sz(1) == 1 || (size(sRows,1) == 1 && (sRows(2) - sRows(1) + 1 >= sz(1)));
                if ~allRowsSelected
                    isValid = false;
                end
             end
        end

        function idx = getColIndex(this, actionInfo)
            idx = '';
            if isfield(actionInfo, 'actionInfo')
                idx = actionInfo.actionInfo.index;
            elseif isfield(actionInfo, 'index')
                idx = actionInfo.index;
            end
        end
        
        % generates command for table sort action based on whether it was a
        % sortAscending or sortDescending action.
        function [cmd, executionCmd] = generateCommandForAction(this, focusedDoc, actionInfo)
            focusedView = focusedDoc.ViewModel;
            executionCmd = '';
            selection = focusedView.getSelection;
            data = focusedView.DataModel.Data;
            slice = '';
            if isprop(focusedView.DataModel, 'DataI')
                data = focusedView.DataModel.DataI;
                slice = focusedView.DataModel.Slice;
            end
            s = settings;
            missingPlacementValue = s.matlab.desktop.variables.sorting.MissingValuePlacement.ActiveValue;
            if istabular(data)
                cmd = this.generateCommandForTabularViews(focusedDoc, actionInfo, missingPlacementValue);
            else
                variableName = focusedDoc.Name;
                % Iterate to get a list of all column indices to be sorted. For
                % e.g [1 1;3 5] should return [1 3 4 5]
                c = [];
                cSelection = selection{2};
                for i = 1:height(cSelection)
                    c = unique([c, cSelection(i,1):cSelection(i,2)]);
                end
                colIndices = num2str(c);
                if ~isscalar(c)
                    colIndices = ['[' colIndices ']'];
                end
                if strcmp(actionInfo.menuID, 'SortAscending')
                    direction = true;
                elseif strcmp(actionInfo.menuID, 'SortDescending')
                    direction = false;
                end
                warn = '';

                if isstring(data)
                    [cmd, warn] = internal.matlab.array.StringArrayVariableEditorAdapter.variableEditorSortCode(...
                        data, variableName, colIndices, direction, missingPlacementValue);
                elseif isstruct(data)
                    fnames = fieldnames(data);
                    selectedFnames = {};
                    for col = selection{2}.'
                        selectedFnames = [selectedFnames, fnames(unique(col(1): col(2)))'];
                    end
                    [cmd, warn] = internal.matlab.array.StructArrayVariableEditorAdapter.variableEditorSortCode(...
                        data, variableName, selectedFnames, direction, missingPlacementValue);
                elseif (isnumeric(data) || islogical(data) || iscell(data))
                    [cmd, warn] = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.variableEditorSortCode(...
                        data, variableName, colIndices, direction, slice, missingPlacementValue);
                else
                    [cmd, warn]  = variableEditorSortCode(data, variableName, colIndices, direction, missingPlacementValue);
                end
                % if warning was thrown, dispatch event to client.
                if ~isempty(warn)
                    focusedView.dispatchEventToClient(struct( ...
                        'type', 'actionError', ...
                        'status', 'error', ...
                        'message', warn, ...
                        'errorType', 'warning', ...
                        'source', 'server'));
                end
            end
        end

        function sel = getSelectionIndices(this, focusedView, actionInfo)
            selection = focusedView.getSelection();
            sel = selection{2};
            if isa(focusedView, 'internal.matlab.variableeditor.TableViewModel') && ~isempty(focusedView.getGroupedColumnCounts)
                sel = internal.matlab.variableeditor.TableViewModel.getColumnsFromSelectionString(sel, focusedView.getGroupedColumnCounts);
            end
        end
        
        function cmd = generateCommandForTabularViews(this, focusedDoc, actionInfo, missingPlacementValue, varName)
            arguments
                this
                focusedDoc
                actionInfo
                missingPlacementValue
                varName = focusedDoc.Name
            end
            focusedView = focusedDoc.ViewModel;
            tableData = focusedView.DataModel.getCloneData;
            sel = this.getSelectionIndices(focusedView, actionInfo);
            if any(sel)
                if isa(tableData, "timetable")
                    [variableNames, ~] = unique(this.getSelectedColumnVariableNames(...
                        [tableData.Properties.DimensionNames{1} tableData.Properties.VariableNames], sel), "stable");
                elseif isa(tableData, "dataset")
                    [variableNames, ~] = unique(this.getSelectedColumnVariableNames(...
                        tableData.Properties.VarNames, sel), "stable");
                else
                    [variableNames, ~] = unique(this.getSelectedColumnVariableNames(...
                        tableData.Properties.VariableNames, sel), "stable");
                end
            else
                variableNames = {};
            end

            % If any selected variableNames are cells,reset
            % missingPlacement to auto (Use Data to run varfun on the table
            % impl, For timetables, if VariableNames is the rowtimes column,
            % varfun check would error.
            if isa(focusedView.DataModel.Data, "dataset")
                cellVars = datasetfun(@iscell, focusedView.DataModel.Data, 'DataVars', variableNames, 'UniformOutput', true);
            else
                cellVars = varfun(@iscell, focusedView.DataModel.Data, 'InputVariables', variableNames, 'OutputFormat', 'uniform');
            end
            if any(cellVars)
                missingPlacementValue = 'auto';
            end
            
            % double check on syntax, using cell of chars.
            variableName = varName;
            if strcmp(actionInfo.menuID, 'SortAscending')
                if isa(tableData, 'dataset')
                    cmd = variableEditorSortCode(tableData, variableName, variableNames, true);
                else
                    cmd = variableEditorSortCode(tableData, variableName, variableNames, true, missingPlacementValue);
                end
            elseif strcmp(actionInfo.menuID, 'SortDescending')
                if isa(tableData, 'dataset')
                    cmd = variableEditorSortCode(tableData, variableName, variableNames, false);
                else
                    cmd = variableEditorSortCode(tableData, variableName, variableNames, false, missingPlacementValue);
                end
            end
        end
    end
end
