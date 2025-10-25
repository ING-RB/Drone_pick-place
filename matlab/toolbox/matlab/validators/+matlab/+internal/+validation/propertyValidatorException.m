function newEx = propertyValidatorException(ex, className, propName, origin)
    % callValidationException Handles validator exceptions from argument validation
    
    %   Copyright 2019-2024 The MathWorks, Inc.
    
    persistent knownUsageErrors;

    if isempty(knownUsageErrors)
        knownUsageErrors = getKnownUsageErrors;
    end

    % a matlab.internal.validation.Exception indicates an author error
    usageError = ...
        startsWith(ex.identifier, knownUsageErrors) ||...
        isa(ex, 'matlab.internal.validation.Exception');

    % validation errors
    handler = matlab.internal.validation.PropertyValidationExceptionHandlerBase.getFromOrigin(origin);

    % MCOS-8653
    if matlab.internal.validation.ExecutionContextWrapper.hasPackagesFeature
        callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper(matlab.lang.internal.ExecutionContext.caller);
    else
        callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper;
    end

    newEx = handler.propertyValidatorException(ex, className, callerContextWrapper, propName, usageError);

    if usageError
        msgStruct.identifier = newEx.identifier;
        msgStruct.message = newEx.message;
        msgStruct.stack = ex.stack;
        rethrow(msgStruct);
    end
end
