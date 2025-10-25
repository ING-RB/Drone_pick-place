classdef NameCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % NAMECOL
    % Represents the Name Column in Variable Editor.
    % The data is returned as a cell array containing the "Name"
    % information that must be displayed between "startRow"
    % and "endRow".

    % Copyright 2021 The MathWorks, Inc.

    methods
        function this = NameCol()         
            this.HeaderName = 'Name';
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Name'));
            this.Editable = false;
            this.Sortable = false;
            this.Visible_I = true;
            this.ColumnIndex_I = 1;
        end

        function viewData = getData(~, startRow, endRow, ~, fieldNames, ~, ~, formatOutput, isDataTruncated, fieldNameIds)
            arguments
                ~
                startRow
                endRow
                ~
                fieldNames
                ~
                ~
                formatOutput logical = true;
                isDataTruncated logical = false;
                fieldNameIds = fieldNames;
            end
            if startRow > 0 && endRow > 0
                viewData = fieldNames(startRow:endRow)';
                return;
            end
            viewData = {};
        end

        % No Sort Implementation Currently.
        function sortedIndices = getSortedIndices(this, ~, fieldnames, ~, ~)
            sortedIndices = [];
        end
    end
end

