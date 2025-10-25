classdef DAQDataPlugin < matlab.hwmgr.internal.data.plugins.PluginBase
    %DAQDATAPLUGIN Data plugin class for DAQ HWMgr Apps.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties
        DataFactory = matlab.hwmgr.internal.data.DataFactory
    end

    properties(Constant, Access = private)
        ProductShortName = "daq"     
        
        NIDevicePath = fullfile(matlabroot, "toolbox", "shared", "testmeaslib", "hwutils", "daq", ...
            "private", "win64", "niplugin");

        TroubleshootingData = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.makeLinkDataStruct( ...
             getString(message("hwmanagerapp:clientappdata:daqappdata:DATTroubleshootLinkTitle")), ... Title
             "https://www.mathworks.com/help/daq/troubleshooting-in-data-acquisition-toolbox.html", ... URL
             matlab.hwmgr.internal.data.plugins.DAQDataPlugin.ProductShortName, ... Doc ProductName
             "daq_troubleshooting_category") ... Doc Topic ID

        % AIR App Data
        AIRAppData = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.makeAppletStruct(...
            getString(message("hwmanagerapp:clientappdata:daqappdata:AIRAppName")), ... Display Name
            "analogInputRecorderApp", ... Icon ID
            "daqaiapplet.applet.DAQAIApplet", ... Applet Class
            "matlab.hwmgr.plugins.DAQPlugin", ... Plugin Class
            getString(message("hwmanagerapp:clientappdata:daqappdata:AIRAppDescription")), ... Description
            getString(message("hwmanagerapp:clientappdata:daqappdata:AIRTroubleshootLinkTitle")), ... Troubleshooting Link Title
            "https://www.mathworks.com/help/daq/acquire-data-with-the-analog-input-recorder.html", ... URL
            "daq_using_air") ... Doc Topic ID

        % AOG App Data
        AOGAppData = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.makeAppletStruct(...
            getString(message("hwmanagerapp:clientappdata:daqappdata:AOGAppName")), ... Display Name
            "analogOutputGeneratorApp", ... Icon ID
            "daqaoapplet.applet.DAQAOApplet", ... Applet Class
            "matlab.hwmgr.plugins.DAQPlugin", ... Plugin Class
            getString(message("hwmanagerapp:clientappdata:daqappdata:AOGAppDescription")), ... Description
            getString(message("hwmanagerapp:clientappdata:daqappdata:AOGTroubleshootLinkTitle")), ... Troubleshooting Link Title
            "https://www.mathworks.com/help/daq/generate-signals-with-the-analog-output-generator.html", ... URL
            "daq_using_aog") ... Doc Topic ID

        % AddOn Data
        DATAddOn = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:daqappdata:DATAddOnName")), ... Name
            "DA", ... Base Code
            "RequiresDAT", false)

        NIAddOn = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:daqappdata:NIAddOnName")), ... Name
            "NIDAQMX", ... Base Code
            "Manufacturer", getString(message("hwmanagerapp:clientappdata:daqappdata:NIManufacturerName")), ... Manufacturer Name
            "AsyncioDevicePlugin", matlab.hwmgr.internal.data.plugins.DAQDataPlugin.NIDevicePath, ... Device plugin location
            "ClientEnumeratorAddOnSwitch", "DA")  ...Enable device enumeration using Asyncio plugin. DA decides if client enumerator or device provider should be enabled.

        SoundCardAddOn = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:daqappdata:SoundCardAddOnName")), ... Name
            "SOUNDCARDS", ... Base Code
            "Manufacturer", getString(message("hwmanagerapp:clientappdata:daqappdata:WoundCardManufacturerName"))) ... Manufacturer Name

        ADIAddOn = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:daqappdata:ADIAddOnName")), ... Name
            "DAT_ANALOG_DEV_ADALM1000", ... Base Code
            "Manufacturer", getString(message("hwmanagerapp:clientappdata:daqappdata:ADIManufacturerName"))) ... Manufacturer Name

        MCCAddOn = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:daqappdata:MCCAddOnName")), ... Name
            "MEAS_COMPUTING", ... Base Code
            "Manufacturer", getString(message("hwmanagerapp:clientappdata:daqappdata:MCCManufacturerName"))) ... Manufacturer Name

        % Keyword Data
        KeywordData = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.makeKeywordStruct(...
            getString(message("hwmanagerapp:clientappdata:daqappdata:Keyword")), ... Keyword
            getString(message("hwmanagerapp:clientappdata:daqappdata:KeywordDescription")), ... Description
            getString(message("hwmanagerapp:clientappdata:daqappdata:KeywordTooltip"))) ... Tooltip

    end

    methods
        function obj = DAQDataPlugin()
            if ~strcmpi(computer, 'pcwin64')
                % DAQ only supported on Windows 64. On all other platforms,
                % do not provide data.
                return
            end

            % APPLET DATA
            airAppletData = obj.createAppletData(obj.AIRAppData);
            obj.addAppletData(airAppletData);

            aogAppletData = obj.createAppletData(obj.AOGAppData);
            obj.addAppletData(aogAppletData);

            % ADDON DATA
            daqAddOnData = obj.createAddOnData(obj.DATAddOn);
            obj.addAddOnData(daqAddOnData);

            % National Instruments				
            nimaxAddOnData = obj.createAddOnData(obj.NIAddOn);
            obj.addAddOnData(nimaxAddOnData);
 
            % Windows Sound Cards
            soundcardAddOnData = obj.createAddOnData(obj.SoundCardAddOn);
            obj.addAddOnData(soundcardAddOnData);

            % Analog Devices
            adiAddOnData = obj.createAddOnData(obj.ADIAddOn);
            obj.addAddOnData(adiAddOnData);

            % Measurement Computing
            mccAddOnData = obj.createAddOnData(obj.MCCAddOn);
            obj.addAddOnData(mccAddOnData);

            % HARDWARE KEYWORD DATA
            keywordData = obj.createHardwareKeywordData(obj.KeywordData);
            obj.addHardwareKeywordData(keywordData); 
        end
    end

    methods(Access = private)
        function linkData = createLinkData(obj, linkStruct)
            linkData = obj.DataFactory.createDocLinkData(linkStruct.ProductShortName, linkStruct.TopicID, linkStruct.Title, linkStruct.Link);
        end

        function hwKeyData = createHardwareKeywordData(obj, keywordStruct)
            % Create map of manufacturer basecodes
            basecodeMap = containers.Map(...
                [obj.NIAddOn.Manufacturer, obj.SoundCardAddOn.Manufacturer, obj.ADIAddOn.Manufacturer, obj.MCCAddOn.Manufacturer], ...
                {obj.NIAddOn.BaseCode, obj.SoundCardAddOn.BaseCode, obj.ADIAddOn.BaseCode, obj.MCCAddOn.BaseCode});
            
            % Construct HardwareKeywordData object
            hwKeyData = obj.DataFactory.createHardwareKeywordData( ...
                keywordStruct.Keyword, keywordStruct.Description, ...
                keywordStruct.Tooltip, ...
                "HardwareType", ...
                "Manufacturers", basecodeMap);
        end

        function appData = createAppletData(obj, appStruct)
            % Construct "Learn More" link object from app data struct
            appLearnMoreLink = obj.createLinkData(appStruct.TroubleshootingLink);
            
            % Construct Troubleshooting LinkData
            troubleshootingLink = obj.createLinkData(obj.TroubleshootingData);

            % Get BaseCodes for App
            spkgBaseCodes = obj.getSpkgBaseCodes(appStruct.AppletClass);

            % Construct AppletData object
            appData = obj.DataFactory.createAppletData(...
                appStruct.DisplayName, appStruct.AppletClass, ...
                appStruct.PluginClass, appStruct.Description, ...
                appStruct.IconID, appLearnMoreLink, troubleshootingLink, ...
                "ToolboxBaseCodes", obj.DATAddOn.BaseCode, ...
                "SupportPackageBaseCodes", spkgBaseCodes);
        end

        function addOnData = createAddOnData(obj, addOnStruct)
            if isfield(addOnStruct, "RequiredBaseCode")
                % Construct AddOnData object for AddOns with dependencies
                addOnData = obj.DataFactory.createAddOnData( ...
                    addOnStruct.BaseCode, addOnStruct.Name, addOnStruct.RequiredBaseCode);
            elseif isfield(addOnStruct, "ClientEnumeratorAddOnSwitch") && isfield(addOnStruct, "AsyncioDevicePlugin")
                % Construct AddOnData object for Client Enumerators.
                addOnData = obj.DataFactory.createAddOnData( ...
                    addOnStruct.BaseCode, addOnStruct.Name,...
                    "AsyncioDevicePlugin", addOnStruct.AsyncioDevicePlugin, ... Device plugin location
                    "ClientEnumeratorAddOnSwitch", addOnStruct.ClientEnumeratorAddOnSwitch); ... Enable device enumeration using Asyncio plugin
            else
                % Construct AddOnData object for AddOns with no
                % dependencies
                addOnData = obj.DataFactory.createAddOnData( ...
                    addOnStruct.BaseCode, addOnStruct.Name);
            end            
        end

        function baseCodes = getSpkgBaseCodes(obj, appletClass)
            % Get relevant support package base codes for the given applet
            switch appletClass
                case obj.AIRAppData.AppletClass
                    baseCodes = [obj.NIAddOn.BaseCode, obj.SoundCardAddOn.BaseCode, obj.ADIAddOn.BaseCode, obj.MCCAddOn.BaseCode];
                case obj.AOGAppData.AppletClass
                    % AOG does not support ADI
                    baseCodes = [obj.NIAddOn.BaseCode, obj.SoundCardAddOn.BaseCode, obj.MCCAddOn.BaseCode];
            end
        end
    end

    methods(Static, Access = private)
        % MAKEAPPLETSTRUCT - Helper method for encapsulating Applet Data
        % within standardized struct.
        function appDataStruct = makeAppletStruct(displayName, iconID, appletClass,...
                pluginClass, description, troubleshootingTitle, troubleshootingLink, ...
                troubleshootingTopicID)

            % Create LinkData struct for relevent troubleshooting link
            troubleshootLinkStruct = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.makeLinkDataStruct( ...
                troubleshootingTitle, troubleshootingLink, ...
                matlab.hwmgr.internal.data.plugins.DAQDataPlugin.ProductShortName, ...
                troubleshootingTopicID);

            % Create AppData struct
            appDataStruct = struct(...
                "DisplayName", displayName, "IconID", iconID, ...
                "AppletClass", appletClass, "PluginClass", pluginClass, ...
                "Description", description, ...
                "TroubleshootingLink", troubleshootLinkStruct);
        end

        % MAKELINKDATA - Helper method for encapsulating Link Data
        % within standardized struct.
        function linkDataStruct = makeLinkDataStruct(title, link, prodShortName, topicID)
            linkDataStruct = struct( ...
                    "Title", title, ...
                    "Link", link, ...
                    "ProductShortName", prodShortName, ...
                    "TopicID", topicID);
        end

        % MAKEADDONSTRUCT - Helper method for encapsulating AddOn Data
        % within standardized struct.
        function addOnStruct = makeAddOnStruct(name, baseCode, nameValueArgs)
            arguments
                name
                baseCode
                nameValueArgs.Manufacturer = string.empty()
                nameValueArgs.AsyncioDevicePlugin = string.empty()
                nameValueArgs.ClientEnumeratorAddOnSwitch = string.empty()
                nameValueArgs.RequiresDAT = true
            end

            addOnStruct = struct("Name", string(name), "BaseCode", string(baseCode));

            if ~isempty(nameValueArgs.Manufacturer)
                addOnStruct.Manufacturer = string(nameValueArgs.Manufacturer);
            end
            if ~isempty(nameValueArgs.AsyncioDevicePlugin)
                addOnStruct.AsyncioDevicePlugin = string(nameValueArgs.AsyncioDevicePlugin);
            end
            if ~isempty(nameValueArgs.ClientEnumeratorAddOnSwitch)
                addOnStruct.ClientEnumeratorAddOnSwitch = string(nameValueArgs.ClientEnumeratorAddOnSwitch);
            end

            % Add DAT as a RequiredBaseCode for support packages
            if nameValueArgs.RequiresDAT
                addOnStruct.RequredBaseCode = matlab.hwmgr.internal.data.plugins.DAQDataPlugin.DATAddOn.BaseCode;
            end            
        end

        % MAKEADDONSTRUCT - Helper method for encapsulating Keyword Data
        % within standardized struct.
        function keywordDataStruct = makeKeywordStruct(keyword, description, tooltip)
            keywordDataStruct = struct( ...
                "Keyword", keyword, ...
                "Description", description, ...
                "Tooltip", tooltip);
        end
    end
end

