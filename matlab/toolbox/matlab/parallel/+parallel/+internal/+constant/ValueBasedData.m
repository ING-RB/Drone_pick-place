%ValueBasedData Represents the structural data for a value-based Constant.

% Copyright 2022-2023 The MathWorks, Inc.

classdef ValueBasedData < parallel.internal.constant.AbstractConstantData

    properties (SetAccess = immutable, GetAccess = private)
        % ValueBasedData must have it's Value set on construction.
        Value
    end

    methods
        function obj = ValueBasedData(value)
            obj.Value = value;
        end

        function obj = initialize(obj)
            % Does nothing for ValueBasedData.
        end

        function cleanup(~)
            % Does nothing for ValueBasedData.
        end

        function value = getValue(obj)
            value = obj.Value;
        end

        function args = getConstructorArgs(obj)
            args = {obj.Value};
        end
    end
end