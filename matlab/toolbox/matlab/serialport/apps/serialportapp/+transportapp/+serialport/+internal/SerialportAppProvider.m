classdef SerialportAppProvider < matlab.hwmgr.internal.AppletProviderBase
    % SERIALPORTAPPPROVIDER returns the serialport app supported for
    % serial ports.

    % Copyright 2021 The Mathworks, Inc.

    methods
        function appList = getApplets(~)
            appList = [];
        end

        function appList = getAppletsByDevice(~, ~)
            % Returns the list of the supported apps for serial ports.
            appList = "transportapp.serialport.internal.SerialportApp";
        end
    end
end