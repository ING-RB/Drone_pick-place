classdef TcpclientAppProvider < matlab.hwmgr.internal.AppletProviderBase
    % TCPCLIENTAPPPROVIDER returns the tcpclient app supported by the
    % TCP/IP devices.

    % Copyright 2021 The Mathworks, Inc.

    methods
        function appList = getApplets(~)
            appList = [];
        end

        function appList = getAppletsByDevice(~, ~)
            % Returns the list of the supported apps for the TCP/IP devices.
            appList = "transportapp.tcpclient.internal.TcpclientApp";
        end
    end
end