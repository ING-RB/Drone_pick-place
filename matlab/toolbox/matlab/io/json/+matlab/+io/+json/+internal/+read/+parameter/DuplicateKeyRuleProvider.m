classdef DuplicateKeyRuleProvider < matlab.io.internal.FunctionInterface...
        & matlab.io.internal.common.properties.GetFunctionNameProvider
%

% Copyright 2024 The MathWorks, Inc.

    properties (Parameter)
        % Controls the behavior when the parser encounters duplicate key
        % names in a JSON object.
        DuplicateKeyRule = "auto";
    end

    methods
        function func = set.DuplicateKeyRule(func, rhs)
            func_name = func.getFunctionName();

            % Verify that the input value is one of the valid values
            func.DuplicateKeyRule = validatestring(rhs, ["auto", "preserveLast", "error", "makeUnique"], func_name, "DuplicateKeyRule");;
        end
    end
end
