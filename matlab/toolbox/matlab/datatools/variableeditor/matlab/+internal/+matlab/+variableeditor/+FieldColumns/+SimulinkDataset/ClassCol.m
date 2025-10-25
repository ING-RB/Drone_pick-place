classdef ClassCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % CLASSCOL
    % Represents the Class Column in Variable Editor.
    % The data is returned as a cell array containing the "Class"
    % information that must be displayed between "startRow"
    % and "endRow".

    % Copyright 2021 The MathWorks, Inc.

    properties (Access = 'private')
        dsClasses
    end

    methods
        function this = ClassCol()
            this.HeaderName = 'Class';
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Class'));
            this.Editable = false;
            this.Sortable = false;
            this.Visible_I = true;
            this.ColumnIndex_I = 4;
        end

        function viewData = getData(this, startRow, endRow, ~, ~, ~, ~, formatData, isDataTruncated, fieldIds)
            arguments
                this
                startRow
                endRow
                ~
                ~
                ~
                ~
                formatData logical = true;
                isDataTruncated logical = false;
                fieldIds = "";
            end
            if ~isempty(this.dsClasses) && startRow > 0 && endRow > 0
                viewData = this.dsClasses(startRow:endRow);
                return;
            end

            % Empty Object
            viewData = {};
        end

        function updateClasses(this, classes)
            this.dsClasses = classes;
        end

        % No Sort Implementation Currently.
        function sortIndices = getSortedIndices(this, data, fields, virtualProps, origData)
            sortIndices = [];
        end
    end
end


