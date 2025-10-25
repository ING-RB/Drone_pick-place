function validateVariableName(variableName, T)
%validateVariableName   verifies that the input table/timetable contains
%   the input variable name.
%
%   Will also check the "Row" dimension name, since filters can be applied
%   over those too.
%
%   Copyright 2021 The MathWorks, Inc.

    arguments
        variableName (1, 1) string;
        T {matlab.io.internal.filter.validators.validateTabular};
    end

    if variableName == string(T.Properties.DimensionNames(1))
        return;
    end

    if any(matches(T.Properties.VariableNames, variableName))
        return;
    end

    variableNames = string([T.Properties.DimensionNames(1), T.Properties.VariableNames]);

    error(message("MATLAB:io:filter:filter:InvalidVariableName", ...
        variableName, join(variableNames, ", ")));
end

