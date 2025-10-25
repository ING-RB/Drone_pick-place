classdef OverflowToInfinityProvider < matlab.io.internal.FunctionInterface ...
        & matlab.io.internal.common.properties.GetFunctionNameProvider
%

% Copyright 2024 The MathWorks, Inc.

    properties (Parameter, Hidden)
        % Controls whether the JSON parser will parse numeric values that
        % exceed realmax/realmin as +/- infinity
        OverflowToInfinity = true;
    end

    methods
        function func = set.OverflowToInfinity(func, rhs)
            func_name = func.getFunctionName();

            % Numeric inputs can be converted to logical, and will be
            % accepted
            validateattributes(rhs, ["logical", "numeric"], "scalar", func_name, "OverflowToInfinity");
            func.OverflowToInfinity = logical(rhs);
        end
    end
end
