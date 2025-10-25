classdef SerialportPlugin < matlab.hwmgr.internal.plugins.PluginBase
    % SERIALPORTPLUGIN class returns the DeviceProvider and AppProvider
    % supported by serial ports.

    % Copyright 2021 The Mathworks, Inc.

    methods
        function deviceProviders = getDeviceProvider(~)
            % Provides list of all serial ports.
            deviceProviders = transportapp.serialport.internal.SerialportDeviceProvider();
        end

        function appProviders = getAppletProvider(~)
            % Returns the app provider that supports serial ports.
            appProviders = transportapp.serialport.internal.SerialportAppProvider();
        end
    end
end