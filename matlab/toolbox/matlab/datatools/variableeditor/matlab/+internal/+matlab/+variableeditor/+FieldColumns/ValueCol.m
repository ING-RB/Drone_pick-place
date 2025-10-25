classdef ValueCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class supports "Value" Column display for scalar struct view.

    % Copyright 2020-2022 The MathWorks, Inc.

    properties
        isMetaDataCell
    end

    methods
        function this = ValueCol()
            this.HeaderName = "Value";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Value'));
            this.Editable = true;
            this.Sortable = false;
            this.Visible_I = true;
            this.ColumnIndex_I = 2;
        end

        function viewData = getData(this, startRow, endRow, data, fields, virtualProps, origData, ~, isDataTruncated, fieldIds)
            arguments
                this
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
            % Get the Value column for the given data.  data is a cell array
            % containing the data to get the value for, while origData is the
            % actual object or structure.

            if isDataTruncated
                rows = 1:length(data);
            else
                rows = startRow:endRow;
            end
            currentFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();

            viewData = cell(length(rows), 1);
            viewDataIndex = 1;
            metaData = false(1, length(rows));
            for idx = rows
                [viewData(viewDataIndex), metaData(viewDataIndex)] = internal.matlab.variableeditor.FieldColumns.ValueCol.getValue(...
                    data{idx}, fields{idx}, virtualProps(idx), origData, currentFormat);
                viewDataIndex = viewDataIndex + 1;
            end

            % viewData = vertcat(viewData{:});
            this.isMetaDataCell = metaData;
        end

        function [value, editValue] = getEditValue(this, row, dataValue, formattedDataValue, displayFormat)
            arguments
                this
                row
                dataValue
                formattedDataValue
                displayFormat = "long"
            end
            value = formattedDataValue;
            editValue = formattedDataValue;
            % If we have a non-empty numeric value, that isn't a value summary create the full-precision representation of it.
            if ~this.isMetaDataCell(row) && isnumeric(dataValue) && ~isempty(dataValue)
                editValue = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(dataValue, displayFormat);
            end
            if (isa(dataValue, 'logical') && isscalar(dataValue))
                if strcmp(formattedDataValue, 'true') ||...
                        strcmp(formattedDataValue, '1') ||...
                        strcmp(formattedDataValue, 'on')
                    value = '1';
                else
                    value = '0';
                end
                editValue = value;
            end
        end

        function ismetadata = isMetaData(this, row)
            ismetadata = this.isMetaDataCell(row);
        end

        % No Sort Implementation for value column currently
        function sortedIndices = getSortedIndices(~, ~, ~)
            sortedIndices = [];
        end
    end

    methods(Static)
        function [val, isMeta] = getValue(cellData, fieldName, isVirtual, origData, currentFormat)
            if isVirtual
                % For virtual properties, use the class method to get the
                % value.
                val = {internal.matlab.datatoolsservices.FormatDataUtils.getVirtualObjPropValue(origData, fieldName)};
                isMeta = true;
            elseif isa (cellData, 'internal.matlab.variableeditor.StructArraySummary')
                % If Data is a StructArraySummary, display individual values as a summary
                % representation in [<>,...] format.
                formattedVals = internal.matlab.datatoolsservices.FormatDataUtils.formatDataBlockForMixedView( ...
                    1, 1, 1, length(cellData.Value), cellData.Value, currentFormat);
                val = "[" + strjoin(string(formattedVals), ',');
                if cellData.IsOverflowValue
                    val = val + ", ... ";
                end
                val = {val + "]"};
                isMeta = true;
            else
                [val, ~, isMeta] = internal.matlab.datatoolsservices.FormatDataUtils.formatDataBlockForMixedView( ...
                    1, 1, 1, 1, {cellData}, currentFormat);
            end
        end
    end
end

