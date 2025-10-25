classdef VEPasteAction < internal.matlab.variableeditor.VEAction
    % VEPasteAction
    % Pastes the clipboard data to the view's current selection for
    % Matrices in the VariableEditor
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'VEPasteAction'
    end
    
    methods
        function this = VEPasteAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.dataTypes.VEPasteAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.SetDataFromClipboard;
            this.Enabled = true;
        end
        
        function SetDataFromClipboard(this, pasteInfo)
            idx = arrayfun(@(x) isequal(x.DocID, pasteInfo.docID), this.veManager.Documents);
            doc = this.veManager.Documents(idx);
            dm = doc.DataModel;

            if isfield(pasteInfo.actionInfo, 'clipboardData') && ...
                ~isempty(pasteInfo.actionInfo.clipboardData)
                clipboardData = pasteInfo.actionInfo.clipboardData;
            else
            % g2909141: Excel (desktop) on Windows OS inserts a newline at
            % the end of any copied data which needs to be removed.
            clipboardData = clipboard('paste');
            end
            if ((length(clipboardData) > 1) && clipboardData(end) == newline)
                clipboardData(end) = [];
            end

            % g3360939
            % Convert the clipboard's character array to a cell array that
            % can be processed later for missing values
            tempData = strsplit(clipboardData, '\n');
            splitTempData = cellfun(@(x) strsplit(x, '\t', 'CollapseDelimiters', false), tempData, 'UniformOutput', false);
            splitTempData = strtrim(splitTempData);
            data = vertcat(splitTempData{:});


            if (internal.matlab.datatoolsservices.FormatDataUtils.isNumericType(dm.ClassType) || islogical(dm.Data))
                errorMsg = getString(message('MATLAB:codetools:variableeditor:NumericArrayPasteTypeError'));
                try
                    data(ismissing(data)) = {'nan'};
                    data = cellfun(@(x) str2num(x), data);
                catch e
                    doc.ViewModel.dispatchEventToClient(struct( ...
                        'type', 'actionError', ...
                        'status', 'error', ...
                        'message', errorMsg, ...
                        'source', 'server'));
                    return;
                end
            end

            selectedRowIndices = pasteInfo.actionInfo.selectedRowIndices + 1;
            selectedColumnIndices = pasteInfo.actionInfo.selectedColumnIndices + 1;

            % If selection is smaller than the clipboard data, the for
            % loops will ensure that only the selected subset is
            % overwritten
            rowIndexLen = length(selectedRowIndices);
            colIndexLen = length(selectedColumnIndices);
            sz = size(data);
            if (rowIndexLen < sz(1) || colIndexLen < sz(2))
                % If selection is smaller than the data being pasted, expand the selection indices to match the clipboard data
                % If either of the indices is larger, first clip selected bounds
                selectedRowIndices = selectedRowIndices(1:min(sz(1), rowIndexLen));
                selectedColumnIndices = selectedColumnIndices(1:min(sz(2), colIndexLen));

                % Now 
                rowDiff = sz(1) - length(selectedRowIndices);
                if rowDiff > 0
                    selectionIncr = selectedRowIndices(end):selectedRowIndices(end)+rowDiff;
                    selectedRowIndices = [selectedRowIndices selectionIncr(2:end)];
                end
                colDiff = sz(2) - length(selectedColumnIndices);
                if colDiff > 0
                    selectionIncr = selectedColumnIndices(end):selectedColumnIndices(end)+colDiff;
                    selectedColumnIndices = [selectedColumnIndices selectionIncr(2:end)];
                end
            elseif (rowIndexLen == sz(1) && mod(colIndexLen, sz(2))==0 ) || (colIndexLen == sz(2) && mod(rowIndexLen, sz(1))==0)
                % The row or column selection is a multiple of the row/column indices, expand
                % data into selection
                data = repmat(data, length(selectedRowIndices), length(selectedColumnIndices));
            else
                % Selection and data sizes do not match, paste data as-is
                selectedRowIndices = selectedRowIndices(1:min(sz(1), length(selectedRowIndices)));
                selectedColumnIndices = selectedColumnIndices(1:min(sz(2), length(selectedColumnIndices)));
            end
            varData = dm.Data;
            
            try
                if isstruct(varData)
                    % Paste in struct arrays is dependant on the data size and
                    % the selection start similar to the lead cell case.
                    selectedRowIndices = [1:height(data)] + selectedRowIndices(1) - 1;
                    selectedColumnIndices = [1:width(data)] + selectedColumnIndices(1) - 1;
                    for i = 1:width(data)
                        internal.matlab.array.StructArrayVariableEditorAdapter.variableEditorPaste(varData, 'varData', selectedRowIndices, selectedColumnIndices(i), data(:,i), true);
                    end
                elseif iscategorical(varData) || isdatetime(varData) || isduration(varData) || iscalendarduration(varData)
                    varData = variableEditorPaste(varData, selectedRowIndices, selectedColumnIndices, data);                
                else
                    for i = 1:length(selectedRowIndices)
                        for j = 1:length(selectedColumnIndices)
                            varData(selectedRowIndices(i), selectedColumnIndices(j)) = data(i,j);
                        end
                    end
                end
            catch e
                doc.ViewModel.dispatchEventToClient(struct( ...
                    'type', 'actionError', ...
                    'status', 'error', ...
                    'message', e.message, ...
                    'source', 'server'));
                return;
            end

            % Overrite the base worksapce variable
            %% TODO: Remove this and replace with assignin debug workspace. Presently, assigin debug is not workin as expected.
            assignin('base', doc.Name, varData);
        end


        function  UpdateActionState(~)
        end
    end 
end