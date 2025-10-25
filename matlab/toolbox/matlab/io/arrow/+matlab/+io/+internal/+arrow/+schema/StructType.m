classdef StructType < matlab.io.internal.arrow.schema.NestedType
%STRUCTTYPE Represents an arrow::StructArray.

% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private)
        DataTypeEnum = matlab.io.internal.arrow.schema.DataTypeEnum.Struct
        FieldNames(1, :) string
    end

    methods
        function obj = StructType(fieldTypes, fieldNames)
            obj = obj@matlab.io.internal.arrow.schema.NestedType(fieldTypes);
            obj.FieldNames = fieldNames;
        end
    end
end
