classdef NameCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Name" Column display for scalar struct view.

    % Copyright 2020-2024 The MathWorks, Inc.

    methods
        function this = NameCol()
            this.HeaderName = "Name";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Field'));
            this.Editable = true;
            this.Sortable = true;
            this.Visible_I = true;
            this.ColumnIndex_I = 1;
            this.DataAttributes = "IconLabelNameColumn";
        end

        function viewData = getData(this, startRow, endRow, cellData, fieldNames, virtualVals, data, formatOutput, isDataTruncated, fieldNameIds)
            arguments
                this
                startRow
                endRow
                cellData
                fieldNames
                virtualVals
                data
                formatOutput logical = false
                isDataTruncated logical = false;
                fieldNameIds = fieldNames;
            end
            if ~isDataTruncated
                viewData = fieldNames(startRow: endRow)';
            else
                viewData = cellstr(fieldNames)';
            end
        end

        % Returns the sorted indices w.r.t order of fields in the struct.
        function sortedIndices = getSortedIndices(this, ~, fieldnames, ~, ~)
            caseInsensitiveNames = lower(fieldnames);
            if this.SortAscending
                [~, sortedIndices] = sortrows(caseInsensitiveNames);
            else
                [~, sortedIndices] = sortrows(caseInsensitiveNames, 'descend');
            end
        end
    end
end
