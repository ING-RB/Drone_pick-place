function VariableTypes = validateVariableTypes(opts, VariableTypes, UseSelectedVariables)
%validateVariableTypes   Verifies that VariableTypes or SelectedVariableTypes
%   is the same length as VariableNames or SelectedVariableIndices.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        opts
        VariableTypes (1, :) string
        UseSelectedVariables (1, 1) logical
    end

    if UseSelectedVariables
        Nexpected = numel(opts.SelectedVariableIndices);
    else
        Nexpected = numel(opts.OriginalVariableNames);
    end

    Nactual = numel(VariableTypes);
    if Nactual ~= Nexpected
        error(message("MATLAB:io:common:builder:IncorrectNumberOfVariableTypes", Nexpected, Nactual));
    end
end
