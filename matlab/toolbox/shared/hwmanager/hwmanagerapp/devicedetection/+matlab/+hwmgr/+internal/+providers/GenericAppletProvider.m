classdef GenericAppletProvider < matlab.hwmgr.internal.AppletProviderBase
    %GENERICAPPLETPROVIDER This is a generic applet provider that works
    %with generic plugin and generic devices
    
    % Copyright 2018 The Mathworks Inc.
    
    methods
        function appletList = getApplets(obj)
            appletList = {};
        end
        
        function appletList = getAppletsByDevice(obj, device)
            appletList = {};
        end
    end
end