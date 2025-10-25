function useJavaScript = useJavaScriptBackEnd()
%USEJAVASCRIPTBACKEND returns true if editor APIs should use JavaScript back end.
%
%   This function is unsupported and might change or be removed without
%   notice in a future version.
%
% Copyright 2021-2023 The MathWorks, Inc.


import matlab.internal.capability.Capability;

isWebUI = feature('webui');
isDesktopInUse = desktop('-inuse');
isRemoteClient = ~Capability.isSupported(Capability.LocalClient);
isNoDesktopWebuiFeatureAvailable = feature("NoDesktopWebui");

if isNoDesktopWebuiFeatureAvailable
    if batchStartupOptionUsed
        useJavaScript = false;
    else
        useJavaScript = isRemoteClient || isWebUI;
    end
else
    useJavaScript = isRemoteClient || (isWebUI && isDesktopInUse);
end

end