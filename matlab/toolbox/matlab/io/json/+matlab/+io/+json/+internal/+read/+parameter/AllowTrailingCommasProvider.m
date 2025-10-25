classdef AllowTrailingCommasProvider < matlab.io.internal.FunctionInterface ...
        & matlab.io.internal.common.properties.GetFunctionNameProvider
%

% Copyright 2023-2024 The MathWorks, Inc.

    properties (Parameter)
        % Controls whether JSON parser will allow C/C++/Javascript style
        % comments
        AllowTrailingCommas = true;
    end

    methods
        function func = set.AllowTrailingCommas(func, rhs)
            func_name = func.getFunctionName();

            % Numeric inputs can be converted to logical, and will be
            % accepted
            validateattributes(rhs, ["logical", "numeric"], "scalar", func_name, "AllowTrailingCommas");
            func.AllowTrailingCommas = logical(rhs);
        end
    end
end
