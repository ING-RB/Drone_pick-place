function optValue = validatePerVariableOption(varNames, optName, optValue, validateFcn)
%VALIDATEPERVARIABLEOPTION Utility function used to validate parquetwrite's
% "per-variable" name-value arguments.

% Copyright 2022 The MathWorks, Inc.

    optValue = convertCharsToStrings(optValue);
    
    if isStringScalar(optValue)
        % Apply scalar expansion after validating the supplied option value.
        optValue = validateFcn(optValue);
        optValue = repmat(optValue, size(varNames));
    else
        % Check that number of options matches the number of variables.
        validateattributes(optValue, "string", ...
            {'numel', numel(varNames)}, "parquetio:write", optName);
        optValue = arrayfun(validateFcn, optValue);
    end
end

