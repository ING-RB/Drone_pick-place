function ex = propertySizeCoercionException(ex, className, propName, dimStr, origin)
%

%   Copyright 2019-2024 The MathWorks, Inc.

    % MCOS-8653
    if matlab.internal.validation.ExecutionContextWrapper.hasPackagesFeature
        callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper(matlab.lang.internal.ExecutionContext.caller);
    else
        callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper;
    end

    handler = matlab.internal.validation.PropertyValidationExceptionHandlerBase.getFromOrigin(origin);
    ex = handler.sizeCoercionException(ex, className, callerContextWrapper, propName, dimStr);
end
