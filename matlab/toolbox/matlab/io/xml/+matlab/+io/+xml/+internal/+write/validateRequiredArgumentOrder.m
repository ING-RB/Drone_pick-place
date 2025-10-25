function validateRequiredArgumentOrder(firstArg, secondArg, expType)
% Provide an error message suggesting wrong argument order if filename
% and object to write arguments are swapped

% Copyright 2020 The MathWorks, Inc.

    switch (expType)
        case "struct"
            expTypeFcn = @isstruct;
            fcnName = "writestruct";
        case "table"
            expTypeFcn = @istable;
            fcnName = "writetable";
        case "dictionary"
            expTypeFcn = @(x) isa(x, "dictionary");
            fcnName = "writedictionary";
        otherwise
            error(message('MATLAB:io:xml:common:SwitchedArgumentOrderUnsupported', ...
                        expType));
    end

    if matlab.internal.datatypes.isScalarText(firstArg) && expTypeFcn(secondArg)
        error(message('MATLAB:io:xml:common:SwitchedArgumentOrder', ...
                        fcnName, expType));
    end
end
