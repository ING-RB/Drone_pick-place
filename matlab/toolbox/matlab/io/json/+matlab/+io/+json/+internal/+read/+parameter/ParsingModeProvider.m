classdef ParsingModeProvider < matlab.io.internal.FunctionInterface ...
        & matlab.io.internal.common.properties.GetFunctionNameProvider
%

% Copyright 2023-2024 The MathWorks, Inc.

    properties (Parameter)
        % Controls whether JSON parser will allow non-standard JSON
        % features: comments, trailing commas, reading Inf and NaN
        % entries as numeric values. "lenient" by default.
        ParsingMode = "lenient";
    end

    methods
        function func = set.ParsingMode(func, rhs)
            func_name = func.getFunctionName();

            % Verify that the input value is one of the valid values
            func.ParsingMode = validatestring(rhs, ["lenient", "strict"], func_name, "ParsingMode");
        end
    end

    methods (Access = protected)
        function func = applyParsingMode(func, supplied)
        % Only modify the nv arguments if ParsingMode is set to
        % 'strict', as the default values for all three are 'true'
            if supplied.ParsingMode && (func.ParsingMode=="strict")
                if (~supplied.AllowComments)
                    func.AllowComments = false;
                end
                if (~supplied.AllowInfAndNaN)
                    func.AllowInfAndNaN = false;
                end
                if (~supplied.AllowTrailingCommas)
                    func.AllowTrailingCommas = false;
                end
            end
        end
    end
end
