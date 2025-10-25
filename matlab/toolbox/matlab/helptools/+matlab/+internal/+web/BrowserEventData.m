classdef (ConstructOnLoad) BrowserEventData < event.EventData
    properties        
        WebCommandSuccess (1,1) logical
        BrowserLauncherSuccess (1,1) logical
        BrowserLauncherErrorID char
    end

    methods
        function obj = BrowserEventData(webCommandSuccess, browserLauncherSuccess, browserLauncherErrorID)
            obj.WebCommandSuccess = webCommandSuccess;
            obj.BrowserLauncherSuccess = browserLauncherSuccess;
            obj.BrowserLauncherErrorID = browserLauncherErrorID;
        end
    end
end

%   Copyright 2022 The MathWorks, Inc.