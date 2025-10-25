classdef WebCommandNotifier < handle
    events
        BrowserLaunched
    end
    
    methods (Access = ?matlab.internal.web.WebCommandBrowserLauncher)
        function browserLaunched(obj, webCommandSuccess, browserLauncherSuccess, browserLauncherErrorID)
            data = matlab.internal.web.BrowserEventData(webCommandSuccess, browserLauncherSuccess, browserLauncherErrorID);
            notify(obj, "BrowserLaunched", data);
        end
    end
end

%   Copyright 2022 The MathWorks, Inc.