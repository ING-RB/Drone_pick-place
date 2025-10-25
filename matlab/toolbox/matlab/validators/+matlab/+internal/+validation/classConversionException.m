function E = classConversionException(ex, functionName, callSiteInfo, ...
    argumentPosition, argumentName, targetClass, isDefault, isNamed, ...
    inputOrOutput, valueBeingValidated, functionHandleToTargetClass)
%

%   Copyright 2019-2024 The MathWorks, Inc.

    import matlab.internal.validation.RuntimeArgumentException
    import matlab.internal.validation.Exception

    if nargin == 10
        % Use a @targetClass if the last input is not provided.
        functionHandleToTargetClass = str2func(targetClass);
    end

    error_fn = RuntimeArgumentException.getConversionExceptionCreater(isDefault, isNamed, inputOrOutput);

    % MCOS-8653
    if matlab.internal.validation.ExecutionContextWrapper.hasPackagesFeature
        callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper(matlab.lang.internal.ExecutionContext.caller);
    else
        callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper;
    end

    msg = Exception.getClassConversionMessage(targetClass, callerContextWrapper, functionHandleToTargetClass, valueBeingValidated);

    if inputOrOutput == "output"
        %% ignore callSiteInfo for oav
        callSiteInfo = struct.empty;
    end

    E = error_fn(...
        functionName,...
        callSiteInfo,...
        argumentPosition,...
        argumentName,...
        'MATLAB:validation:UnableToConvert',...
        msg);
    
    % until we have a way to directly manipulate MException's error stacks, use message struct to rethrow default value errors.
    if isDefault
        % use new error id/msg; reuse error stack from caught exception
        msgStruct.identifier = E.identifier;
        msgStruct.message = E.message;
        msgStruct.stack = ex.stack;
        rethrow(msgStruct);
    end
end
