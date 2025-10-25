classdef DeviceListPanel < matlab.ui.container.internal.appcontainer.Panel
    %DEVICELISTPANEL A custom Panel using clientapp-startpage-ui as a
    %dynamically loaded bundle.

    % Copyright 2022 The MathWorks, Inc.

    methods
        function obj = DeviceListPanel(clientId, varargin)
            obj = obj@matlab.ui.container.internal.appcontainer.Panel(varargin{:});

            % Setup dynamic bundle factory method for DeviceListPanel
            obj.Factory = struct("Modules", matlab.hwmgr.internal.DeviceListModuleInfo);

            % Prepare content to be passed to factory method
            contentPacket.clientId = clientId;
            obj.Content = contentPacket;
        end
    end
end