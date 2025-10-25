classdef RyzeDataPlugin < matlab.hwmgr.internal.data.plugins.PluginBase
    % Ryze data plugin for Hardware Manager apps

    % Copyright 2021-2023 The MathWorks, Inc.

    properties(Constant)

        % Device icon id
        AppletIcon = "ryzeTelloNavigatorApp"
        RyzeIOBaseCode = "RYZEIO"
    end

    methods

        function obj = RyzeDataPlugin()

            % Troubleshooting in MATLAB Support Package for Ryze Tello
            % Drones
            troubleshootingLink = matlab.hwmgr.internal.data.DataFactory.createLinkData(...
                getString(message("hwmanagerapp:clientappdata:ryzetellonavigator:ryzeioTroubleshooting")),...
                "https://www.mathworks.com/help/supportpkg/ryzeio/troubleshooting-in-matlab-support-package-for-ryze-tello-drones.html");

            % Learn more about Ryze Tello Navigator app
            ryzeioLearnMoreLink = matlab.hwmgr.internal.data.DataFactory.createLinkData(...
                getString(message("hwmanagerapp:clientappdata:ryzetellonavigator:ryzeioLearnMore")),...
                "https://www.mathworks.com/matlabcentral/fileexchange/111210-navigating-ryze-tello-drones-with-matlab-app?s_tid=srchtitle");

            % Create Ryze Tello Navigator applet data
            ryzeNavAppData = matlab.hwmgr.internal.data.DataFactory.createAppletData(...
                getString(message("hwmanagerapp:clientappdata:ryzetellonavigator:ryzeTelloNavigatorTitle")),...
                "telloapplet.RyzeTelloNavigatorApplet",...
                "telloapplet.RyzeTelloPlugin",...
                getString(message("hwmanagerapp:clientappdata:ryzetellonavigator:ryzeioLearnMore")),...
                obj.AppletIcon, ryzeioLearnMoreLink, troubleshootingLink,...
                "SupportPackageBaseCodes", obj.RyzeIOBaseCode);
            obj.addAppletData(ryzeNavAppData);

            % Create AddOn Data for the MATLAB Support Package for Ryze Tello Drones
            ryzeioAddOnData = matlab.hwmgr.internal.data.DataFactory.createAddOnData( ...
                obj.RyzeIOBaseCode,...
                getString(message("hwmanagerapp:clientappdata:ryzetellonavigator:ryzeioSPKGFullName")));
            obj.addAddOnData(ryzeioAddOnData);

            % Hardware keyword data is skipped as we do not want GitHub based
            % Drone HWMgr app discovery through "Add Device" workflow
        end
    end
end
