function varNames = validateNumVariableNames(varNames, info)
%validateNumVariableNames   Verifies that the number of variable names
%   matches the number of variable names in the Parquet file.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        varNames (1, :) string {mustBeNonmissing}
        info
    end

    Nactual = numel(varNames);
    Nexpected = numel(info.VariableNames);

    if Nactual ~= Nexpected
        error(message("MATLAB:io:common:builder:NumberOfVariablesMustBeConstant", Nexpected));
    end
end