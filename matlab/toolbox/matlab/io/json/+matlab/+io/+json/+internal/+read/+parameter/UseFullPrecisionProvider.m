classdef UseFullPrecisionProvider < matlab.io.internal.FunctionInterface
%

% Copyright 2024 The MathWorks, Inc.

    properties (Parameter, Hidden)
        % Controls whether JSON parser will use the full precision strtod
        % converter.
        UseFullPrecision = true;
    end

    methods
        function func = set.UseFullPrecision(func, rhs)

            func_name = func.getFunctionName();

            % Numeric inputs can be converted to logical, and will be
            % accepted
            validateattributes(rhs, ["logical", "numeric"], "scalar", func_name, "UseFullPrecision");
            func.UseFullPrecision = logical(rhs);
        end
    end
end
