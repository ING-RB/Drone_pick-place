classdef NonQuotedTextType
    % This is an interface for data types that want to have their text values
    % shown without quotes

    % Copyright 2021 The MathWorks, Inc.

    properties
        Value
    end

    methods
        function obj = NonQuotedTextType(value)
            obj.Value = value;
        end

          function value = getValue(obj)
            value = obj.Value;
        end
    end
end