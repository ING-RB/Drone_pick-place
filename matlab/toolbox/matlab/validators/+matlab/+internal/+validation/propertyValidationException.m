function ex = propertyValidationException(ex, functionName, callSiteInfo, ...
                                          argumentPosition, argumentName)
%

%   Copyright 2019-2020 The MathWorks, Inc.

% Handle case:
% arguments
%     opts.?OptionClass
% end
ex = matlab.internal.validation.RuntimeNameValueException.createExceptionUsingCaughtException(...
    functionName, callSiteInfo, argumentPosition, argumentName, ex);
end
