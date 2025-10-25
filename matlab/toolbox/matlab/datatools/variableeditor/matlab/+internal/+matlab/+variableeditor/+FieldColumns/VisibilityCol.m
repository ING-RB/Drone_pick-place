classdef VisibilityCol < internal.matlab.variableeditor.FieldColumns.FieldVariableColumn
    % Copyright 2023-2024 The MathWorks, Inc.

    methods
        function this = VisibilityCol()
            this.HeaderName = "Visible";
            this.TagName = getString(message('MATLAB:codetools:variableeditor:Visible'));
            this.Visible_I = false;
            this.ColumnIndex_I = 5;
            this.DataAttributes = "VisibilityIconColumn";
            this.CustomColumn = true;
        end

        % Get the view data from the given data, start row, end row, and
        % additional information.
        %
        % The output is in cell format, and matches the length of
        % endRow - startRow + 1. Each element must be either 0 (hidden) or
        % 1 (visible).
        %
        % Example output: {-1, 1, 0, 1}.
        % - This indicates rows 2 and 4 are visible, and row 3 is
        %   hidden. Row 1 has no eye icon.
        function viewData = getData(this, ~, ~, cellData, fieldNames, ~, data, formatData, isDataTruncated, fieldNameIds)
            arguments
                this
                ~
                ~
                cellData
                fieldNames
                ~
                data
                formatData logical = true; %#ok<INUSA>
                isDataTruncated logical = false; %#ok<INUSA>
                fieldNameIds = fieldNames;
            end

            % Note that fieldNames is already paginated for us; we do not
            % need to use the "startRow" and "endRow" variables.

            % Get the table name from the struct, if it exists.
            viewData = cell(1, length(fieldNames));

            % Go through all the values in cellData. cellData example:
            % { table
            %   cell array
            %   cell array
            %   table
            %   cell array }
            %
            % In this case, we're dealing with two tables. Table 1 has two
            % columns, and Table 2 has one column.
            for i = 1:length(cellData)
                curValue = cellData{i};
                curValueIsTable = istabular(curValue);

                % Now that we have a value from cellData, we check if it's
                % a table or cell array. Depending on the data type, we
                % must parse the respective fieldName differently.
                %
                % Table fieldName example: StructName.TableName
                % Column fieldName example: StructName.TableName.VariableName

                if curValueIsTable
                    if isprop(curValue.Properties.CustomProperties, 'VisibilityFlags')
                        visMetadata = curValue.Properties.CustomProperties.VisibilityFlags;

                        try
                            viewData{i} = visMetadata(fieldNameIds(i));
                        catch e
                            % g3355681: Visibility data is tracked through custom table properties as a dictionary,
                            % where each dictionary key is a string representing a row.
                            %
                            % As of the time this change was made, renaming any row in the Variable Editor does
                            % _not_ update the corresponding dictionary key. The consumer of the Variable Editor
                            % must manually make this update. In the future, we should auto-update this key.
                            %
                            % As a consequence of this behavior, users renaming tables/columms leads to unexpected
                            % issues. Imagine a user renamed table "t" to "t2". We attempt to retrieve key "t2"
                            % from the dictionary, but since that key does not exist, an error gets thrown.
                            %
                            % As a temporary workaround (until we revisit this behavior), we hide the eye icon
                            % for this row when we encounter an error.
                            internal.matlab.datatoolsservices.logDebug( ...
                                "variableeditor::FieldVariableColumn::VisibilityCol", "Could not fetch visibility data for row ID '" + fieldNameIds(i) + "': " + e.message);
                            viewData{i} = -1; % "-1" means that we should show no eye icon.
                        end
                    else
                        % This is a nested table that does not have any visibility data.
                        % As such, we treat it as a normal column.
                        viewData{i} = this.getViewDataForColumn(data, fieldNameIds(i));
                    end
                else % Contains column values
                    viewData{i} = this.getViewDataForColumn(data, fieldNameIds(i));
                end
            end
        end

        function viewData = getViewDataForColumn(~, data, fieldNameId)
            try
                splitCurId = internal.matlab.variableeditor.VEUtils.splitRowId(fieldNameId);
                tableName = splitCurId(2);

                visMetadata = data.(tableName).Properties.CustomProperties.VisibilityFlags;
                viewData = visMetadata(fieldNameId);
            catch
                viewData = 0;
            end
        end

        function sortedIndices = getSortedIndices(~, ~, ~, ~, ~)
            % This column does not support sorting.
            sortedIndices = [];
        end
    end
end
