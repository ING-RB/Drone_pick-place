classdef TcpclientPlugin < matlab.hwmgr.internal.plugins.PluginBase
    % TCPCLIENTPLUGIN class returns the DeviceProvider and AppProvider
    % supported by TCP/IP devices.

    % Copyright 2021 The Mathworks, Inc.

    methods
        function deviceProviders = getDeviceProvider(~)
            % Provide the list of non-enumerable TCP/IP devices to Hardware
            % Manager.
            deviceProviders = transportapp.tcpclient.internal.TcpclientDeviceProvider();
        end

        function appProviders = getAppletProvider(~)
            % Returns the app provider that supports TCP/IP devices.
            appProviders = transportapp.tcpclient.internal.TcpclientAppProvider();
        end
    end
end