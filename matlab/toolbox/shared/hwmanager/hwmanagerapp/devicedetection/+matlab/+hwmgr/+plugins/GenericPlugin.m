classdef GenericPlugin < matlab.hwmgr.internal.plugins.PluginBase
    %GENERICPLUGIN This is the plugin class for generic providers for
    %generic USB devices
    
    % Copyright 2018 The Mathworks Inc.
    
    methods
        function deviceProviders = getDeviceProvider(~)
            % Return all the device providers defined for GenericPlugins
            deviceProviders = matlab.hwmgr.internal.providers.GenericDeviceProvider;
        end
        
        function appletProviders = getAppletProvider(~)
            % Return all the applet providers defined for GenericPlugins
            appletProviders = matlab.hwmgr.internal.providers.GenericAppletProvider;
        end
    end
    
end
