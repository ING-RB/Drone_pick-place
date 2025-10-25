function invokeValidationFunction(validation, coercedValue)
 % apply validators

%   Copyright 2018-2020 The MathWorks, Inc.

    vfcns = validation.validators;
    for i=1:numel(vfcns)
        try
            vfcns{i}(coercedValue);
        catch me
            throwAsCaller(me);
        end
    end
end
