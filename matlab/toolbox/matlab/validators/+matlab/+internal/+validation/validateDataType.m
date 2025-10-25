function value = validateDataType(validation, value, invokeValidation)   
     % Helper function to validate the values contained in the valdiation
     % struct injected for typed properties

     % Copyright 2018-2020 The MathWorks, Inc.

     % avoid creating ValidationHelper object if there is no need
     if (isempty(validation.class) || isa(value, validation.class)) && isempty(validation.dimensions) && ~invokeValidation
         return;
     end
         
     H = matlab.internal.validation.ValidationHelper(validation);

     % do class conversion
     if ~isa(value, H.ClassName)
         % g1984150 TODO: Change the call to use validateClass.
         [value, ex] = validateClassForDataTypeUseCase(H, value);
         if ~isempty(ex)
             throwAsCaller(ex);
         end
     end

    % do size conversion
    if ~isempty(H.CodedSize)
        [value, ex] = validateSize(H, value);
        if ~isempty(ex)
            throwAsCaller(ex);
        end
    end

    % apply validators
    if invokeValidation
        ex = validateUsingValidationFunctions(H, value);
        if ~isempty(ex)
            throwAsCaller(ex);
        end
    end
end

