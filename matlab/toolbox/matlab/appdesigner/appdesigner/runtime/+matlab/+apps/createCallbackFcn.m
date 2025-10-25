function newCallback = createCallbackFcn(obj, callback, requiresEventData)
%CREATECALLBACKFCN Components authored in App Designer assign callbacks to
%uicomponents using this wrapper, which forwards exceptions to App
%Designer for correct alerts in App Designer.

% Copyright 2021, MathWorks Inc.

if nargin == 2
    requiresEventData = false;
end

newCallback = @(source, event)executeCallback(appdesigner.internal.service.AppManagementService.instance(), ...
    obj, callback, requiresEventData, event);

end
