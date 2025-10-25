classdef PrimitiveType < matlab.io.internal.arrow.schema.DataType
%PRIMITIVE Represents the datatype of a primitive arrow::Array. 
%   Type must be set to one of the following values:
%
%       "string", "int8", "int16", "int32", "int64", "uint8", "uint16",
%       "uint32", "uint64", "double", "single", "datetime", "duration",
%       "categorical", "logical"
    
% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private)
        Type(1, 1) string
        DataTypeEnum = matlab.io.internal.arrow.schema.DataTypeEnum.Primitive
    end

    methods(Access = {?matlab.io.internal.arrow.schema.DataType, ...
                      ?matlab.io.internal.arrow.schema.TableSchema})
        function obj = PrimitiveType(type)
            obj.Type = type;
        end
    end
end

