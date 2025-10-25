function callbackHelper(callbackFcn, context, eventData, options)
%

%   Copyright 2024 The MathWorks, Inc.

    callbackInfo = matlab.internal.filebrowser.CallbackInfo(context, eventData, options);
    feval(callbackFcn, callbackInfo);
end
