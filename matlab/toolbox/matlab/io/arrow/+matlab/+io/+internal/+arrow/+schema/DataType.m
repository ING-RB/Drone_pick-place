classdef (Abstract) DataType < matlab.mixin.Heterogeneous
%DATATYPE Base class that represents the datatype of an arrow::Array.

% Copyright 2022 The MathWorks, Inc.

    properties(Abstract, SetAccess = private)
        DataTypeEnum(1, 1) matlab.io.internal.arrow.schema.DataTypeEnum
    end

    methods (Static, Sealed, Access = protected)
        function obj = getDefaultScalarElement()
        % getDefaultScalarElement enables the creation of arrays using
        % index assignment with gaps in the numbers. By default, create a
        % PrimitiveType whose Type property is set to "int32".
            obj = matlab.io.internal.arrow.schema.PrimitiveType("int32");
        end
    end
end