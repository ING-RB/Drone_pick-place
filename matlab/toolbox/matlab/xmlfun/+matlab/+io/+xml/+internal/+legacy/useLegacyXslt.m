function tf = useLegacyXslt(inputs, xmlEngine)
%

% Copyright 2024 The MathWorks, Inc.

    if xmlEngine == "auto"
        % If at least one input argument is a Java object, then use the
        % legacy xslt implementation.
        fcn = @(arg) isjava(arg);
        isLegacyInputs = cellfun(fcn, inputs, UniformOutput=true);
        tf = any(isLegacyInputs);
    else
        tf = xmlEngine == "jaxp";
    end
end