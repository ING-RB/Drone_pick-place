function paramValue = validateIterationParameter(arrds, paramName, paramValue)
%setIterationParameters   Validates OutputType, IterationDimension, or
%   ConcatenationDimension.

%   Copyright 2022 The MathWorks, Inc.

    try
        outputType = arrds.OutputType;
        iterationDimension = arrds.IterationDimension;
        concatenationDimension = arrds.ConcatenationDimension;

        % Validate the customized value and set it as the output.
        switch paramName
            case "OutputType"
                paramValue = validateOutputType(paramValue);
                outputType = paramValue;
            case "IterationDimension"
                paramValue = validateIterationDimension(paramValue);
                iterationDimension = paramValue;
            case "ConcatenationDimension"
                paramValue = validateConcatenationDimension(paramValue);
                concatenationDimension = paramValue;
        end

        % Cross-validation
        % 1. Verify that the dataype supports this iteration dimension too.
        validateData(arrds.Data, iterationDimension);
    
        % 2. Provide an error if IterationDimension > 1 is used with
        %    OutputType="same".
        validateRowIterationWithOutputTypeSame(outputType, iterationDimension, concatenationDimension);

    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end