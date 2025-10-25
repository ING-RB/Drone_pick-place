classdef ClientEnumeratorPlugin < matlab.hwmgr.internal.plugins.PluginBase
    %CLIENTENUMERATORPLUGIN This is the plugin class for providers for
    %client enumerators
    
    % Copyright 2022 The MathWorks, Inc.
    
    methods
        function deviceProviders = getDeviceProvider(~)
            % Return all the device providers defined for ClientEnumeratorPlugin
            deviceProviders = matlab.hwmgr.internal.providers.ClientEnumeratorDeviceProvider;
        end
        
        function appletProviders = getAppletProvider(~)
            % Return all the applet providers defined for ClientEnumeratorPlugin
            appletProviders = [];
        end
    end
end
