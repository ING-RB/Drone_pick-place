classdef ListType < matlab.io.internal.arrow.schema.NestedType
%LISTTYPE Represents an arrow::ListArray.

% Copyright 2022 The MathWorks, Inc.

    properties (SetAccess = private)
        DataTypeEnum = matlab.io.internal.arrow.schema.DataTypeEnum.List
    end
    
    methods
        function obj = ListType(childType)
            obj = obj@matlab.io.internal.arrow.schema.NestedType(childType(1));
        end
    end
end
