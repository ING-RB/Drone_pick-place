classdef IndexCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % INDEXCOL
    % Represents the Index Column in Variable Editor.
    % The data is returned as a cell array containing the "Index"
    % information that must be displayed between "startRow"
    % and "endRow".

    % Copyright 2021 The MathWorks, Inc.   

     methods
        function this = IndexCol()
            this.HeaderName = 'Index';
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Index'));
            this.Editable = false;
            this.Sortable = false;
            this.Visible_I = true;
            this.ColumnIndex_I = 13;  
        end   
        
        function viewData = getData(this, startRow, endRow, ~, ~, ~, ~, formatData, isDataTruncated, fieldIds)
            arguments
                this           internal.matlab.variableeditor.FieldColumns.SimulinkDataset.IndexCol
                startRow       {mustBeNumeric}
                endRow         {mustBeNumeric}
                ~
                ~
                ~
                ~
                formatData logical = true;
                isDataTruncated logical = false;
                fieldIds = "";
            end

            if startRow > 0 && endRow > 0
                viewData = cellstr(string(startRow:endRow));
                return;
            end
            viewData = {};
        end
        
        % No Sort Implementation Currently.
        function sortedIndices = getSortedIndices(~, ~, ~)
            % Abstract method that must be implemented if column is
            % sortable.
            sortedIndices = [];
        end
     end
end

