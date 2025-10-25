function ex = propertyClassCoercionException(ex, className, propName, propType, origin, valueBeingValidated, functionHandleToPropType)
%

%   Copyright 2019-2024 The MathWorks, Inc.

    % MCOS-8653
    if matlab.internal.validation.ExecutionContextWrapper.hasPackagesFeature
        callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper(matlab.lang.internal.ExecutionContext.caller);
    else
        callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper;
    end

    handler = matlab.internal.validation.PropertyValidationExceptionHandlerBase.getFromOrigin(origin);

    if nargin == 6
        functionHandleToPropType = str2func(propType);
    end

    ex = handler.classCoercionException(ex, className, propName, propType, callerContextWrapper, functionHandleToPropType, valueBeingValidated);
end
