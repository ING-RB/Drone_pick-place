function E = sizeConversionException(ex, functionName, callSiteInfo, ... 
    argumentPosition, argumentName, targetSize, isDefault, isNamed, inputOrOutput)
% sizeConversionException Exception thrown for size conversion error

%   Copyright 2019-2022 The MathWorks, Inc.

import matlab.internal.validation.Exception
import matlab.internal.validation.RuntimeArgumentException

error_fn = RuntimeArgumentException.getSizeConversionExceptionCreater(isDefault, isNamed, inputOrOutput);
sizeStruct = Exception.sizeStrToStruct(targetSize);

if inputOrOutput == "output"
    %% ignore callSiteInfo for oav
    callSiteInfo = struct.empty;
end

E = error_fn(...
    functionName,...
    callSiteInfo,...
    argumentPosition,...
    argumentName,...
    'MATLAB:validation:IncompatibleSize',...
    Exception.getSizeSpecificMessage(ex, sizeStruct));

% Until we have a way to directly manipulate Exceptions error stacks,
% use message struct to rethrow default value errors.
% Scalar values do not rethrow any error, so ex is empty.
if ~isDefault
    return;
end

if ~isempty(ex)
    % use new error id/msg; reuse error stack from caught exception
    msgStruct.identifier = E.identifier;
    msgStruct.message = E.message;
    msgStruct.stack = ex.stack;
    rethrow(msgStruct);
else
    % get around an issue with current error stack
    try
        throwAsCaller(E);
    catch E
        msgStruct.identifier = E.identifier;
        msgStruct.message = E.message;
        msgStruct.stack = E.stack;
        rethrow(msgStruct);
    end
end

end

