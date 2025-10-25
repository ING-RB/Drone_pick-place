function executeCallback(obj, appOrUserComponent, callback, requiresEventData, event)
%

%   Copyright 2024 The MathWorks, Inc.

    notify(obj, 'PreCallbackExecution', appdesigner.internal.service.CallbackExecutionEventData(appOrUserComponent));

    % use onCleanup to ensure fire 'PostCallbackExecution' event
    % even though there's an exception from callback
    oc = onCleanup(@()notify(obj, 'PostCallbackExecution', appdesigner.internal.service.CallbackExecutionEventData(appOrUserComponent)));

    if requiresEventData
        callback(appOrUserComponent, event);
    else
        callback(appOrUserComponent);
    end
end
