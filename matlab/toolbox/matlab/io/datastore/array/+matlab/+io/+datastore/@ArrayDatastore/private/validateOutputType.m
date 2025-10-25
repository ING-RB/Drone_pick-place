function outputType = validateOutputType(outputType)
%

%   Copyright 2020 The MathWorks, Inc.

    validateattributes(outputType, ["string" "char"], "scalartext", ...
                       "ArrayDatastore", "OutputType");
    outputType = string(outputType);

    % OutputType must be an exact (case-sensitive and complete) match to one of
    % the allowed values.
    if outputType == "same" || outputType == "cell"
        return;
    end

    % The value specified for "OutputType" was not recognized. Error in this case.
    msgid = "MATLAB:io:datastore:array:validation:UnexpectedOutputTypeValue";
    error(message(msgid, outputType));
end
