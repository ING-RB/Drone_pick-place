function validateRequiredArgumentOrder(S, filename)
%

% Copyright 2023 The MathWorks, Inc.

    import matlab.io.xml.internal.write.validateRequiredArgumentOrder;
    import matlab.io.internal.interface.suggestWriteFunctionCorrection;

    validateRequiredArgumentOrder(S, filename, "struct");

    if ~isstruct(S)
        suggestWriteFunctionCorrection(S, "writestruct");
    end
end
