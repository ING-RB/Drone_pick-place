classdef BlockPathCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % BLOCKPATHCOL
    % Represents the BlockPath Column in Variable Editor.
    % Maintains cache of Block Paths for a given Dataset
    % Object. The data is returned as a cell array containing the
    % "BlockPath" information that must be displayed between "startRow"
    % and "endRow".
    
    % Copyright 2021 The MathWorks, Inc.

    properties (Access = 'private')
        dsBlockPaths
    end

     methods
        function this = BlockPathCol()
            this.HeaderName = 'BlockPath';
            this.TagName = getString(message('MATLAB:codetools:variableeditor:BlockPath'));
            this.Editable = false;
            this.Sortable = false;
            this.Visible_I = true;
            this.ColumnIndex_I = 14;
        end   

        function viewData = getData(this, startRow, endRow, ~, ~, ~, ~, formatData, isDataTruncated, fieldIds)
            arguments
                this           internal.matlab.variableeditor.FieldColumns.SimulinkDataset.BlockPathCol
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

            if ~isempty(this.dsBlockPaths) && startRow > 0 && endRow > 0
                viewData = this.dsBlockPaths(startRow:endRow);
                return;
            end

            % Empty Object
            viewData = {};
        end

        function updateBlockPaths(this, blockPaths)
            this.dsBlockPaths = blockPaths;
        end
        
        % No Sort Implementation for value column currently
        function sortedIndices = getSortedIndices(~, ~, ~)
            % Abstract method that must be implemented if column is
            % sortable.
            sortedIndices = [];
        end
     end
end

