classdef ClassCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Size" Column display for scalar struct view.

    % Copyright 2020-2024 The MathWorks, Inc.

    properties(Constant)
        COLUMN_NAME = "Class"; % TODO: Define HeaderName as constants for all fieldcolumns.
    end

    methods
        function this = ClassCol()
            this.HeaderName = internal.matlab.variableeditor.FieldColumns.ClassCol.COLUMN_NAME;
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Class'));
            this.Editable = false;
            this.Sortable = true;
            this.Visible_I = true;
            this.ColumnIndex_I = 4;
        end

        function viewData = getData(~, startRow, endRow, data, fields, virtualProps, origData, ~, isDataTruncated, fieldIds)
            arguments
                ~
                startRow
                endRow
                data
                fields
                virtualProps
                origData
                ~;  % formatData, unused
                isDataTruncated = false;
                fieldIds = fields;
            end
            % Get the Class name for the given data. data is a cell array
            % containing the data to get the value for, while origData is the
            % actual object or structure.

            if isDataTruncated
                rows = 1:length(data);
            else
                rows = startRow:endRow;
            end

            viewData = cell(length(rows), 1);
            viewDataIndex = 1;
            for idx = rows
                viewData{viewDataIndex} = internal.matlab.variableeditor.FieldColumns.ClassCol.getClass(...
                    data{idx}, fields{idx}, virtualProps(idx), origData);
                viewDataIndex = viewDataIndex + 1;
            end
        end

        % Returns the sorted indices w.r.t order of fields in the struct.
        % Sort by the formatted class string that shows up on display.
        % i.e. double < double(complex).
        function sortIndices = getSortedIndices(this, data, fields, virtualProps, origData)
            count = length(data);
            viewData = cell(count, 1);
            for idx = 1:count
                viewData{idx} = internal.matlab.variableeditor.FieldColumns.ClassCol.getClassString(...
                    data{idx}, fields{idx}, virtualProps(idx), origData);
            end

            % Convert to a table, and add in the variable names at the end.  This way, the variable
            % names are the tie-breaker in the case where classes are the same.
            tb = table(viewData);
            if isrow(fields)
                tb.VarNames = fields';
            else
                tb.VarNames = fields;
            end

            if this.SortAscending
                [~, sortIndices] = sortrows(tb);
            else
                [~,sortIndices] = sortrows(tb, tb.Properties.VariableNames, 'descend');
            end
        end
    end

    methods(Static)
        function val = getClass(cellData, fieldName, isVirtual, origData)
            if isVirtual
                % For virtual properties, use the class method to get the
                % class name.
                val = origData.getVariableEditorClassProp(fieldName);
            elseif isa (cellData, 'internal.matlab.variableeditor.StructArraySummary')
                % If Data is a StructArraySummary, display as - to
                % indicate uncomputed value, but if there is no
                % overflow, compute common class if fields are of homogeneous type.
                val = internal.matlab.variableeditor.FieldColumns.ClassCol.UNDEFINED_DISPLAY_VAL;
                if ~cellData.IsOverflowValue
                    classValues = unique(cellfun(@class, cellData.Value, 'UniformOutput', false));
                    if numel(classValues) == 1
                        val = classValues{1};
                    end
                end
            else
                val = internal.matlab.datatoolsservices.FormatDataUtils.getClassString(cellData, false, true);
            end
        end

        function classStr = getClassString(x, fieldName, isVirtual, origData)
            % Utility that returns class string. For ObjectValueSummary types,
            % return the DisplayClass of the object.

            if isVirtual
                % For virtual properties, use the class from the virtual
                % class method for sorting.
                classStr = origData.getVariableEditorClassProp(fieldName);
            elseif isa(x, 'internal.matlab.workspace.ObjectValueSummary')
                classStr = x.DisplayClass;
            else
                classStr = internal.matlab.datatoolsservices.FormatDataUtils.getClassString(x, false, true);
            end
        end
    end
end


