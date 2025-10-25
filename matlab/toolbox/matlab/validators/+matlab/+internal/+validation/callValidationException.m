function E = callValidationException(ex, functionName, callSiteInfo, ...
                                     argumentPosition, argumentName, ...
                                     isDefault, isNamed, inputOrOutput)
    % callValidationException Handles validator exceptions from argument validation

    %   Copyright 2019-2022 The MathWorks, Inc.

    persistent known_usage_errors;

    if isempty(known_usage_errors)
        known_usage_errors = getKnownUsageErrors;
    end

    % these errors are likely caused by author mistakes
    if startsWith(ex.identifier, known_usage_errors)
        rethrow(ex);
    end

    % catching an exception we threw indicates an author error
    if isa(ex, 'matlab.internal.validation.Exception')
        rethrow(ex);
    end

    error_fn = matlab.internal.validation.RuntimeArgumentException.getValidatorExceptionCreater(isDefault, isNamed, inputOrOutput);

    E = error_fn(...
        functionName,...
        callSiteInfo,...
        argumentPosition,...
        argumentName,...
        ex);

    % until we have a way to directly manipulate MException's error stacks, use message struct to rethrow default value errors.
    if isDefault
        % use new error id/msg; reuse error stack from caught exception
        msgStruct.identifier = E.identifier;
        msgStruct.message = E.message;
        msgStruct.stack = ex.stack;
        rethrow(msgStruct);
    end
end
