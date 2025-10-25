classdef VNTDataPlugin < matlab.hwmgr.internal.data.plugins.PluginBase
    %VNTDATAPLUGIN Data plugin class for VNT HWMgr Apps.

    % Copyright 2021-2024 The MathWorks, Inc.

    properties(Constant, Access = private)
        % String constants for creating AppletData
        ProductShortName = "vnt"
        CANExplorerName = getString(message("hwmanagerapp:clientappdata:vntexplorerdata:CANExplorerName"))
        CANFDExplorerName = getString(message("hwmanagerapp:clientappdata:vntexplorerdata:CANFDExplorerName"))
        VNTPluginClass = "matlab.hwmgr.plugins.VNTPlugin"

        % String constants for creating HardwareKeywordData
        VNTExplorerHardwareKeyword = getString(message("hwmanagerapp:clientappdata:vntexplorerdata:VNTExplorerHardwareKeyword"))
        VNTExplorerHardwareTooltip = getString(message("hwmanagerapp:clientappdata:vntexplorerdata:VNTExplorerHardwareTooltip"))

        % Toolbox and Support package base code names
        VNTBaseCode = "VN"
        KvaserBaseCode= "KVASERCAN"
        VectorBaseCode= "VECTORCAN"
        PEAKSystemBaseCode= "PEAKSCAN"
        NIXNETBaseCode= "NIXNET"
        SocketCANBaseCode= "SOCKETCAN"
    end

    properties(Access = private)
        % Troubleshooting Link for both CAN Explorer and CAN FD Explorer
        TroubleshootingLink

        % Learn More Link for CAN Explorer
        CANExplorerLearnMoreLink

        % Learn More Link for CAN FD Explorer
        CANFDExplorerLearnMoreLink
    end

    methods
        function obj = VNTDataPlugin()
            %% AppletData
            % Populate doc link data structs.
            obj.TroubleshootingLink = matlab.hwmgr.internal.data.DataFactory.createDocLinkData( ...
                obj.ProductShortName, ... Product Short Name
                "can_apps_category", ... Doc Topic ID
                getString(message("hwmanagerapp:clientappdata:vntexplorerdata:VNTTroubleshootLinkTitle")), ... Title
                "https://www.mathworks.com/help/vnt/can-app-communication.html"); ... Troubleshooting Link URL

            obj.CANExplorerLearnMoreLink = matlab.hwmgr.internal.data.DataFactory.createDocLinkData( ...
                obj.ProductShortName, ... Product Short Name
                "can_explorer_app", ... Doc Topic ID
                obj.CANExplorerName, ... Title
                "https://www.mathworks.com/help/vnt/ug/canexplorer-app.html"); ... Learn More Link URL

            obj.CANFDExplorerLearnMoreLink = matlab.hwmgr.internal.data.DataFactory.createDocLinkData( ...
                obj.ProductShortName, ... Product Short Name
                "canfd_explorer_app", ... Doc Topic ID
                obj.CANFDExplorerName, ... Title
                "https://www.mathworks.com/help/vnt/ug/canfdexplorer-app.html"); ... Learn More Link URL

            % Create and add AppletData for CAN Explorer.
            canExplorerData = matlab.hwmgr.internal.data.DataFactory.createAppletData(...
                obj.CANExplorerName, ... Display Name
                "canapplet.applet.CANApplet", ... Applet Class
                obj.VNTPluginClass, ... Plugin Class
                getString(message("hwmanagerapp:clientappdata:vntexplorerdata:CANExplorerDescription")), ... Description
                "canExplorerApp", ... Icon ID
                obj.CANExplorerLearnMoreLink, ... Learn More Link
                obj.TroubleshootingLink, ... Troubleshooting Link
                ToolboxBaseCodes = obj.VNTBaseCode);
            obj.addAppletData(canExplorerData);

            % Create and add AppletData for CAN FD Explorer.
            canFDExplorerData = matlab.hwmgr.internal.data.DataFactory.createAppletData(...
                obj.CANFDExplorerName, ... Display Name
                "canfdapplet.applet.CANFDApplet", ... Applet Class
                obj.VNTPluginClass, ... Plugin Class
                getString(message("hwmanagerapp:clientappdata:vntexplorerdata:CANFDExplorerDescription")), ... Description
                "canFdExplorerApp", ... Icon ID
                obj.CANFDExplorerLearnMoreLink, ... Learn More Link
                obj.TroubleshootingLink, ... Troubleshooting Link
                ToolboxBaseCodes = obj.VNTBaseCode);
            obj.addAppletData(canFDExplorerData);

            %% AddOnData
            % Asyncio device enumeration plugins for specific vendor.
            arch = computer('arch');
            KvaserDevicePath = fullfile(toolboxdir(fullfile('shared','testmeaslib','hwutils','vnt')), 'private', arch, 'kvaserlistplugin');
            VectorDevicePath = fullfile(toolboxdir(fullfile('shared','testmeaslib','hwutils','vnt')), 'private', arch, 'vectorlistplugin');
            PeakSystemDevicePath = fullfile(toolboxdir(fullfile('shared','testmeaslib','hwutils','vnt')), 'private', arch, 'peaklistplugin');
            NIXNETDevicePath = fullfile(toolboxdir(fullfile('shared','testmeaslib','hwutils','vnt')), 'private', arch, 'nixnetlistplugin');
            SocketCANDevicePath = fullfile(toolboxdir(fullfile('shared','testmeaslib','hwutils','vnt')), 'private', arch, 'socketcanlistplugin');

            % Create and add AddOnData.
            vntAddOn = matlab.hwmgr.internal.data.DataFactory.createAddOnData( ...
                obj.VNTBaseCode, ... Vendor Base Code
                getString(message("hwmanagerapp:clientappdata:vntexplorerdata:ToolboxName"))); ... Toolbox Name
                obj.addAddOnData(vntAddOn);

            kvaserAddOn = matlab.hwmgr.internal.data.DataFactory.createAddOnData( ...
                obj.KvaserBaseCode, ... Vendor Base Code
                getString(message("hwmanagerapp:clientappdata:vntexplorerdata:ToolboxName")), ... Toolbox Name
                obj.VNTBaseCode, ... Dependency on VNT Toolbox
                "AsyncioDevicePlugin", KvaserDevicePath, ... Device plugin location
                "ClientEnumeratorAddOnSwitch", "VN"); ... Enable device enumeration using Asyncio plugin
                obj.addAddOnData(kvaserAddOn);

            peakAddOn = matlab.hwmgr.internal.data.DataFactory.createAddOnData( ...
                obj.PEAKSystemBaseCode, ... Vendor Base Code
                getString(message("hwmanagerapp:clientappdata:vntexplorerdata:ToolboxName")), ... Toolbox Name
                obj.VNTBaseCode, ... Dependency on VNT Toolbox
                "AsyncioDevicePlugin", PeakSystemDevicePath, ... Device plugin location
                "ClientEnumeratorAddOnSwitch", "VN"); ... Enable device enumeration using Asyncio plugin
                obj.addAddOnData(peakAddOn);

            % Vendor support for Vector and NI is only for Windows platform.
            if ispc
                vectorAddOn = matlab.hwmgr.internal.data.DataFactory.createAddOnData( ...
                    obj.VectorBaseCode, ... Vendor Base Code
                    getString(message("hwmanagerapp:clientappdata:vntexplorerdata:ToolboxName")), ... Toolbox Name
                    obj.VNTBaseCode, ... Dependency on VNT Toolbox
                    "AsyncioDevicePlugin", VectorDevicePath, ... Device plugin location
                    "ClientEnumeratorAddOnSwitch", "VN"); ... Enable device enumeration using Asyncio plugin
                    obj.addAddOnData(vectorAddOn);

                nixnetAddOn = matlab.hwmgr.internal.data.DataFactory.createAddOnData( ...
                    obj.NIXNETBaseCode, ... Vendor Base Code
                    getString(message("hwmanagerapp:clientappdata:vntexplorerdata:ToolboxName")), ... Toolbox Name
                    obj.VNTBaseCode, ... Dependency on VNT Toolbox
                    "AsyncioDevicePlugin", NIXNETDevicePath, ... Device plugin location
                    "ClientEnumeratorAddOnSwitch", "VN"); ... Enable device enumeration using Asyncio plugin
                    obj.addAddOnData(nixnetAddOn);
            end

            % Vendor support for SocketCAN only for Linux platform.
            if isunix
                socketCANAddOn = matlab.hwmgr.internal.data.DataFactory.createAddOnData( ...
                    obj.SocketCANBaseCode, ... Vendor Base Code
                    getString(message("hwmanagerapp:clientappdata:vntexplorerdata:ToolboxName")), ... Toolbox Name
                    obj.VNTBaseCode, ... Dependency on VNT Toolbox
                    "AsyncioDevicePlugin", SocketCANDevicePath, ... Device plugin location
                    "ClientEnumeratorAddOnSwitch", "VN"); ... Enable device enumeration using Asyncio plugin
                    obj.addAddOnData(socketCANAddOn);
            end

            %% HardwareKeywordData
            % Create and add HardwareKeywordData.
            if ispc
                keywordData = matlab.hwmgr.internal.data.DataFactory.createHardwareKeywordData( ...
                    obj.VNTExplorerHardwareKeyword, ... Keyword
                    getString(message("hwmanagerapp:clientappdata:vntexplorerdata:VNTExplorerHardwareDescriptionWindows")), ... Description
                    obj.VNTExplorerHardwareTooltip, ... Tooltip
                    "InterfaceAndProtocol", ... Keyword Category
                    KeywordRelatedBaseCodes = obj.VNTBaseCode);
            else
                keywordData = matlab.hwmgr.internal.data.DataFactory.createHardwareKeywordData( ...
                    obj.VNTExplorerHardwareKeyword, ... Keyword
                    getString(message("hwmanagerapp:clientappdata:vntexplorerdata:VNTExplorerHardwareDescriptionUnix")), ... Description
                    obj.VNTExplorerHardwareTooltip, ... Tooltip
                    "InterfaceAndProtocol", ... Keyword Category
                    KeywordRelatedBaseCodes = obj.VNTBaseCode);
            end
            obj.addHardwareKeywordData(keywordData);
        end
    end
end
