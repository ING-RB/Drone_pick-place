classdef (Abstract) NestedType < matlab.io.internal.arrow.schema.DataType
%NESTEDTYPE Represents a nested arrow array. 

% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = protected)
        ChildTypes(1, :) matlab.io.internal.arrow.schema.DataType
    end

    properties(Dependent, SetAccess = private)
        NumChildren
    end

    methods
        function obj = NestedType(fieldTypes)
            obj.ChildTypes = fieldTypes;
        end
    end

    methods
        function numFields = get.NumChildren(obj)
            numFields = numel(obj.ChildTypes);
        end
    end
end
