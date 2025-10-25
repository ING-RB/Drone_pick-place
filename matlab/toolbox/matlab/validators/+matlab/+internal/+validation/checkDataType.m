function checkDataType(validation, coercedValue)
     % Helper function to check the size and class restrictions of the 
     % datatype value, based on the validation struct. It also invokes the
     % validation functions

     % Copyright 2018-2020 The MathWorks, Inc.
     
     if ~isempty(validation.class) && ~isa(coercedValue, validation.class)
        % Error
        msg = message('MATLAB:type:PropSetClsMismatch', validation.class);
        throwAsCaller(MException('MATLAB:type:PropSetClsMismatch', msg.getString));
     end
    
    % Validation function
     matlab.internal.validation.invokeValidationFunction(validation, coercedValue);
end
