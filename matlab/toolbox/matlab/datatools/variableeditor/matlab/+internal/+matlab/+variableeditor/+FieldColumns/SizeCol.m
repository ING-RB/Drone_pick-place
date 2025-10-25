classdef SizeCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Size" Column display for scalar struct view.

    % Copyright 2020-2024 The MathWorks, Inc.

    methods
        function this = SizeCol()
            this.HeaderName = "Size";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Size'));
            this.Editable = false;
            this.Sortable = true;
            this.Visible_I = true;
            this.ColumnIndex_I = 3;
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
                isDataTruncated logical = false;
                fieldIds = fields;
            end
            % Get the size column for the given data. data is a cell array
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
                viewData{viewDataIndex} = internal.matlab.variableeditor.FieldColumns.SizeCol.getSize(...
                    data{idx}, fields{idx}, virtualProps(idx), origData);
                viewDataIndex = viewDataIndex + 1;
            end
        end

        % Returns the sorted indices w.r.t order of fields in the struct.
        function sortIndices = getSortedIndices(this, data, fields, virtualProps, origData)
            % allocate to the right height, and assume two dimensions.
            % This can grow by columns if a 3d or 4d variable is
            % encountered, but at least it doesn't grow by height each time
            % through the loop.
            sizeArr = zeros(length(data), 2);

            % In order to sort sizes, stack the sizes in sizeArr and do
            % a numeric sort on the array.
            for i = 1:length(data)
                a = size(data{i});

                % For objectValueSummary types, we need to fetch size from
                % DisplaySize.
                if virtualProps(i)
                    % For virtual properties, use the class method to get the
                    % size for sorting
                    a = origData.getVariableEditorSize(fields(i));
                elseif isa(data{i}, 'internal.matlab.workspace.ObjectValueSummary')
                    times = internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL;
                    a = str2double(strsplit(data{i}.DisplaySize,['(' times '|\-D)'],'DelimiterType','RegularExpression'));
                    a = a(~isnan(a));
                elseif length(a) > internal.matlab.datatoolsservices.FormatDataUtils.NUM_DIMENSIONS_TO_SHOW
                    a = length(a);
                end

                sizeArr(i, 1:length(a)) = a;
            end

            % Convert to a table, and add in the variable names at the end.  This way, the variable
            % names are the tie-breaker in the case where sizes are the same.
            tb = array2table(sizeArr);
            if isrow(fields)
                tb.VarNames = fields';
            else
                tb.VarNames = fields;
            end

            if this.SortAscending
                [~,sortIndices] = sortrows(tb);
            else
                [~,sortIndices] = sortrows(tb, tb.Properties.VariableNames, 'descend');
            end
        end
    end

    methods(Static)
        function val = getSize(cellData, fieldName, isVirtual, origData)
            if isVirtual
                % For virtual properties, use the class method to get the
                % size
                val = internal.matlab.datatoolsservices.FormatDataUtils.getVirtualObjPropSize(origData, fieldName);
            elseif isa (cellData, 'internal.matlab.variableeditor.StructArraySummary')
                % If Data is a StructArraySummary, display as - to
                % indicate uncomputed value.
                val = internal.matlab.variableeditor.FieldColumns.SizeCol.UNDEFINED_DISPLAY_VAL;
            else
                val = internal.matlab.datatoolsservices.FormatDataUtils.getSizeString(cellData);
            end
        end
    end
end
