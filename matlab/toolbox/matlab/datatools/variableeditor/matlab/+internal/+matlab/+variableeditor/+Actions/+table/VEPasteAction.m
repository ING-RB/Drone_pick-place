classdef VEPasteAction < internal.matlab.variableeditor.VEAction
    % VEPasteAction
    % Pastes the clipboard data to the view's current selection for Tables
    % in the VariableEditor
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionType = 'VETablePasteAction'
    end

    methods
        function this = VEPasteAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.table.VEPasteAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.SetDataFromClipboard;
            this.Enabled = true;
        end
        
        function SetDataFromClipboard(this, pasteInfo)
            idx = arrayfun(@(x) isequal(x.DocID, pasteInfo.docID), this.veManager.Documents);
            doc = this.veManager.Documents(idx);
            vm = doc.ViewModel;
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

            strData = string(clipboardData);
            tempData = splitlines(strData);
            tempData = cellfun(@(x)(strsplit(x, '\t')), tempData, 'UniformOutput', false);
            data = vertcat(tempData{:});

            selectedRowIndices = pasteInfo.actionInfo.selectedRowIndices + 1;
            selectedColumnIndices = pasteInfo.actionInfo.selectedColumnIndices + 1;

            varData = dm.Data;
            
            if (size(data, 1) == 1 && size(data, 2) == 1)
                % If clipboard contains a single cell, expand it to match the selection range
                data = repmat(data, length(selectedRowIndices), length(selectedColumnIndices));
            elseif (length(selectedRowIndices) == 1 && length(selectedColumnIndices) == 1)
                % If selection is just the lead cell, expand the selection indices to match the clipboard data
                selectedRowIndices = [1:height(data)] + selectedRowIndices - 1;
                selectedColumnIndices = [1:width(data)] + selectedColumnIndices - 1;
            end

            % When paste is mxn data into mxn cells, verify the sizes
            if (size(data, 1) ~= length(selectedRowIndices) || ...
                    size(data, 2) ~= length(selectedColumnIndices) || ...
                    (selectedRowIndices(1) < height(varData) && selectedRowIndices(end) > height(varData)) || ...
                    (selectedColumnIndices(1) < width(varData) && selectedColumnIndices(end) > width(varData)))
                errordlg(getString(message('MATLAB:codetools:variableeditor:TablePasteSizeError')), getString(message('MATLAB:codetools:variableeditor:PasteErrorDialogTitle')));
                return;
            end

            % Check if lead cell is immediately outside data bounds, if so, concat data.
            try
                if (selectedColumnIndices(1) == size(varData, 2) + 1)
                    % Concat data horizontally
                    if (dm.ClassType == "dataset")
                        target_indices = selectedColumnIndices(1) + [1:size(data,2)] - 1;
                        string_indices = "data" + string(target_indices);
                        string_indices = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(string_indices, convertCharsToStrings(varData.Properties.VarNames));
                        new_data = cell2dataset(data, 'ReadVarNames', false);
                        new_data.Properties.VarNames = convertCharsToStrings(string_indices);
                        tData = horzcat(varData, new_data);
                    else
                        tData = horzcat(varData, data);
                    end
                elseif (selectedRowIndices(1) == size(varData, 1) + 1)
                    % Concat clipboard data vertically to existing data
                    if (dm.ClassType == "dataset")
                        data = this.formatClipboardDataForDataset(data, selectedColumnIndices, vm);
                        data.Properties.VarNames = varData.Properties.VarNames;
                    else
                        data = this.formatClipboardDataForTable(data, selectedColumnIndices, vm);
                        data.Properties.VariableNames = varData.Properties.VariableNames;
                    end
                    tData = vertcat(varData, data);
                else
                    % Overrite selected cells since selection is within the data
                    if (dm.ClassType == "dataset")
                        data = this.formatClipboardDataForDataset(data, selectedColumnIndices, vm);
                    else
                        data = this.formatClipboardDataForTable(data, selectedColumnIndices, vm);
                    end
                    varData(selectedRowIndices, selectedColumnIndices) = data;
                    tData = varData;
                end
            catch
                errordlg(getString(message('MATLAB:codetools:variableeditor:TablePasteTypeError')), getString(message('MATLAB:codetools:variableeditor:PasteErrorDialogTitle')));
                return;
            end

            % Overrite the base worksapce variable
            %% TODO: Remove this and replace with assignin debug workspace. Presently, assigin debug is not workin as expected.
            assignin('base', doc.Name, tData);
        end

        function formattedData = formatClipboardDataForTable(~, data, selectedColumns, vm)
            tempData = array2table(string(data));
            for i = 1:width(selectedColumns)
                columnClass = vm.getColumnModelProperty(selectedColumns(i), 'class');
                columnClass = columnClass{1};
                columnClassFunc = str2func(columnClass);
                varName = tempData.Properties.VariableNames{i};
                tempData.(varName) = columnClassFunc(tempData.(varName));
            end
            formattedData = tempData;
        end

        function formattedData = formatClipboardDataForDataset(~, data, selectedColumns, vm)
            tempData = mat2dataset(string(data));
            tempTableData = array2table(string(data));
            for i = 1:width(selectedColumns)
                columnClass = vm.getColumnModelProperty(selectedColumns(i), 'class');
                columnClass = columnClass{1};
                columnClassFunc = str2func(columnClass);
                varName = tempData.Properties.VarNames{i};
                tempData.(varName) = columnClassFunc(tempTableData.(varName));
            end
            formattedData = tempData;
        end

        function  UpdateActionState(~)
        end
    end 
end

