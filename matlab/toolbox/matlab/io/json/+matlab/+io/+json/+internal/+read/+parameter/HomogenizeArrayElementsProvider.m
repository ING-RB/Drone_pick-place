classdef HomogenizeArrayElementsProvider < matlab.io.internal.FunctionInterface ...
        & matlab.io.internal.common.properties.GetFunctionNameProvider
%

% Copyright 2023-2024 The MathWorks, Inc.

    properties (Parameter)
        % Controls whether JSON parser will allow C/C++/Javascript style
        % comments
        HomogenizeArrayElements = "auto";
    end

    methods
        function func = set.HomogenizeArrayElements(func, rhs)
            func_name = func.getFunctionName();

            func.HomogenizeArrayElements = validatestring(rhs, ["auto" "never"], func_name, "HomogenizeArrayElements");
        end
    end
end
