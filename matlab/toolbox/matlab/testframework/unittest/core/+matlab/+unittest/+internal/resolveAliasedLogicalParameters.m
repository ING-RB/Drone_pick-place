function bool = resolveAliasedLogicalParameters(options, parameters)
%

% Copyright 2023 The MathWorks, Inc.

bool = false;

isSpecified = isfield(options, parameters);
specifiedParameters = parameters(isSpecified);
if numel(specifiedParameters) > 1
    error(message("MATLAB:unittest:NameValue:OverdeterminedParameters", ...
        specifiedParameters(1), specifiedParameters(2)));
elseif numel(specifiedParameters) == 1
    bool = options.(specifiedParameters);
end
end
