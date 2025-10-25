classdef TableSchema < matlab.mixin.Scalar
%TABLESCHEMA Represents the schema of an arrow::Table.

% Copyright 2022 The MathWorks, Inc.
    
    properties (SetAccess = private)
        ColumnNames(1, :) string
        ColumnDataTypes(1, :) matlab.io.internal.arrow.schema.DataType
    end

    properties(Dependent, SetAccess=private)
        NumColumns
    end

    methods(Access = private)
        function obj = TableSchema(columnNames, columnDataTypes)
            obj.ColumnNames = columnNames;
            obj.ColumnDataTypes = columnDataTypes;
        end
    end

    methods
        function numColumns = get.NumColumns(obj)
            numColumns = numel(obj.ColumnDataTypes);
        end
    end

    methods (Static, Access = public)
        function obj = buildTableSchema(arrowStruct)
            arguments
                arrowStruct(1, 1) struct {arrowTypeMustBeTable}
            end
            import matlab.io.internal.arrow.schema.TableSchema;
            import matlab.io.internal.arrow.schema.PrimitiveType;
            import matlab.io.internal.arrow.schema.DataType;
            
            columnNames = arrowStruct.Names;
            numVariables = numel(arrowStruct.Columns);

            % Pre-allocate a 1 by numVariables array. The for loop below
            % will replace the default PrimitiveType objects with other
            % PrimtiveType objects or NestedType objects.
            columns(numVariables) = PrimitiveType("int32");

            for ii = 1:numVariables
                columns(ii) = TableSchema.getVariableDataType(arrowStruct.Columns(ii));
            end
            obj = TableSchema(columnNames, columns);
        end
    end

    methods (Static, Access = private)
        function varDataType = getVariableDataType(arrowStruct)
            import matlab.io.internal.arrow.schema.DataType;
            import matlab.io.internal.arrow.schema.ListType;
            import matlab.io.internal.arrow.schema.StructType;
            import matlab.io.internal.arrow.schema.PrimitiveType;
            import matlab.io.internal.arrow.schema.TableSchema;

            if arrowStruct.ArrowType == "array"
                % arrowStruct represents a primitive (flat) array.
                varDataType = PrimitiveType(arrowStruct.Type);
            elseif arrowStruct.ArrowType == "list_array"
                % Need to recursively call getVariableDataType() to
                % determine the base primitive type(s) contained by the
                % list.
                innerType = TableSchema.getVariableDataType(arrowStruct.Data.Values);
                varDataType = ListType(innerType);
            elseif arrowStruct.ArrowType == "struct"
                % Need to recursively call getVariableDataType() to
                % determine the base primitive types contained by the
                % struct.
                numFields = numel(arrowStruct.Data.FieldData);
                
                % Pre-allocate a 1 by numVariables array. The for loop 
                % below will replace the default PrimitiveType objects with
                % other PrimtiveType objects or NestedType objects.
                fieldTypes(numFields) = PrimitiveType("int32");

                for ii = 1:numFields
                    fieldTypes(ii) = TableSchema.getVariableDataType(arrowStruct.Data.FieldData{ii});
                end
                varDataType = StructType(fieldTypes, arrowStruct.Data.FieldName);
            else
                errId = "MATLAB:io:arrow:schema:UnsupportedArrowType";
                error(message(errId, arrowStruct.ArrowType));
            end
        end
    end
end

function arrowTypeMustBeTable(arrowStruct)
    arrowType = string(arrowStruct.ArrowType);
    if arrowType ~= "table"
        error(message("MATLAB:io:arrow:schema:ExpectedTableArrowType"));
    end
end