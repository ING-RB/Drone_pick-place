classdef StructArraySummary < handle
    % StructArraySummary is a class used to represent display of struct
    % arrays in container types (Mainly used by StructureTreeTableView)

    % Copyright 2022 The MathWorks, Inc.

    properties
        Value cell
        IsOverflowValue logical
    end

    methods
        % Constructor
        function this = StructArraySummary(Value, isOverflow)
            arguments
                Value cell = {}
                isOverflow logical = false
            end
            this.Value = Value;
            this.IsOverflowValue = isOverflow;
        end
    end
end