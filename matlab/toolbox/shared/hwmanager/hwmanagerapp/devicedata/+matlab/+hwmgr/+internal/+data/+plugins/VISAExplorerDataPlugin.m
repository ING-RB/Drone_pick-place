classdef VISAExplorerDataPlugin < matlab.hwmgr.internal.data.plugins.PluginBase
    %VISAEXPLORERDATAPLUGIN is the data plugin class for the VISA Explorer app

    % Copyright 2022-2024 The MathWorks, Inc.
 
    properties
        DataFactory = matlab.hwmgr.internal.data.DataFactory
    end

    properties(Constant)
        %% AppletData Constants
        AppName (1, 1) string = ...
            getString(message("hwmanagerapp:clientappdata:visaexplorer:AppName"))

        AppDescription (1, 1) string = ...
            getString(message("hwmanagerapp:clientappdata:visaexplorer:ToolTipText"))

        AppIcon (1, 1) string = ...
            "visaExplorerApp"

        % Learn More Link
        LearnMoreText (1, 1) string = ...
            getString(message("hwmanagerapp:clientappdata:visaexplorer:AppName"))

        % Troubleshooting Link
        TroubleshootingText (1, 1) string = ...
            getString(message("hwmanagerapp:clientappdata:visaexplorer:TroubleshootHeading"))

        % ProductShortName and Doc Topic Ids
        ProductShortName (1, 1) string = "instrument"
        DocTopicId (1, 1) string = "visaExplorer"
        TroubleshootTopicId (1, 1) string = "visaTroubleshooting"

        AppletClass (1, 1) string = "transportapp.visadev.internal.VisadevApp"
        PluginClass (1, 1) string = "matlab.hwmgr.plugins.VisadevPlugin"

        %% Hardware Keyword Constants
        HardwareKeyword (1, 1) string = ...
            getString(message("hwmanagerapp:clientappdata:visaexplorer:Keyword"))

        HardwareDescription (1, 1) string = ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.getKeywordDescriptionString()

        HardwareTooltip (1, 1) string = ...
            getString(message("hwmanagerapp:clientappdata:visaexplorer:ToolTipText"))

        HardwareCategory (1, 1) matlab.hwmgr.internal.data.HardwareKeywordCategory = ...
            matlab.hwmgr.internal.data.HardwareKeywordCategory.InterfaceAndProtocol

        ManufacturerPlaceholder (1, 1) string = getString(message("hwmanagerapp:clientappdata:visaexplorer:ManufacturerPlaceholder"))

        %% Add-On Constants
        % Toolbox and Support package base code names
        ProductCode (1, 1) string = "IC"
        NIVISABasedCode (1, 1) string = "ICT_NI_VISA_ICP_INTERFACES"
        RSVISABasedCode (1, 1) string = "ICT_RS_VISA_INTERFACE"
        KeysightVISABasedCode (1, 1) string = "ICT_KEYSIGHT_VISA"

        % Manufacturer names
        NIVISAManufacturerName (1, 1) string = getString(message("hwmanagerapp:clientappdata:visaexplorer:NIVISAManufacturerName"))
        KeysightVISAManufacturerName (1, 1) string = getString(message("hwmanagerapp:clientappdata:visaexplorer:KeysightVISAManufacturerName"))
        RSVISAManufacturerName (1, 1) string = getString(message("hwmanagerapp:clientappdata:visaexplorer:RSVISAManufacturerName"))

        ICTAddOnName (1, 1) string = getString(message("hwmanagerapp:clientappdata:visaexplorer:ICTAddOnName"))
        NIVISAAddOnName (1, 1) string = getString(message("hwmanagerapp:clientappdata:visaexplorer:NIVISAAddOnName"))
        RSVISAAddOnName (1, 1) string = getString(message("hwmanagerapp:clientappdata:visaexplorer:RSVISAAddOnName"))
        KeysightVISAAddOnName (1, 1) string = getString(message("hwmanagerapp:clientappdata:visaexplorer:KeysightVISAAddOnName"))
    end

    properties(Constant, Hidden)
        % App Data
        VISAExplorerAppletStruct = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.makeAppletStruct( ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.AppName, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.AppIcon, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.AppletClass, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.PluginClass, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.AppDescription)

        % Learn more Data
        LearnMoreData = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.makeDocLinkDataStruct( ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.ProductShortName, matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.DocTopicId, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.LearnMoreText)

        % Troubleshooting Data
        TroubleshootingData = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.makeDocLinkDataStruct( ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.ProductShortName, matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.TroubleshootTopicId, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.TroubleshootingText)

        % AddOn Data
        ICTAddOn = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.makeAddOnStruct( ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.ICTAddOnName, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.ProductCode, ...
            "RequiresICT", false)

        NIVISAAddOn = makeAddOnStructHelper(...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.NIVISAAddOnName, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.NIVISABasedCode, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.NIVISAManufacturerName, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.DevicePath, ... Device plugin location
            ispc || ismac)

        RSVISAAddOn = makeAddOnStructHelper(...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.RSVISAAddOnName, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.RSVISABasedCode, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.RSVISAManufacturerName, ...
            getRSVISADevicePath, ... Device plugin location
            ispc || ismac)        

        KeysightVISAAddOn = makeAddOnStructHelper(...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.KeysightVISAAddOnName, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.KeysightVISABasedCode, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.KeysightVISAManufacturerName, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.DevicePath, ... Device plugin location
            ispc)

        % Keyword Data
        KeywordData = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.makeKeywordStruct( ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.HardwareKeyword, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.HardwareDescription, ...
            matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.HardwareTooltip)

        % Client Enumerator Device Plugin (used by all Windows plugins;
        % also used for NI on the Mac)
        DevicePath = fullfile(toolboxdir("shared"), "testmeaslib", "hwutils", "instrument", "private", computer("arch"), "libmwshared_testmeaslib_hwutils_instrument")
        % Client Enumerator Device Plugin (RS on the Mac only)
        RSDevicePath = fullfile(toolboxdir("shared"), "testmeaslib", "hwutils", "instrument", "private", computer("arch"), "libmwshared_testmeaslib_hwutils_instrument_rs")
    end

    properties(Access = private)
        SupportedAddOns = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.getSupportedAddOns()
    end

    methods
        function obj = VISAExplorerDataPlugin()
            if ~(ispc || ismac)
                return
            end
            %% Applet Data
            visaExplorerAppData = obj.createAppletData(obj.VISAExplorerAppletStruct);
            obj.addAppletData(visaExplorerAppData);

            %% Addon Data
            ictAddOnData = obj.createAddOnData(obj.ICTAddOn);
            obj.addAddOnData(ictAddOnData);

            % NI
            nivisaAddOn = obj.createAddOnData(obj.NIVISAAddOn);
            obj.addAddOnData(nivisaAddOn);

            % RS
            rsvisaAddOn = obj.createAddOnData(obj.RSVISAAddOn);
            obj.addAddOnData(rsvisaAddOn);

            % Keysight
            keysightvisaAddOn = obj.createAddOnData(obj.KeysightVISAAddOn);
            obj.addAddOnData(keysightvisaAddOn);

            %% Hardware Keyword Data
            keywordData = obj.createHardwareKeywordData(obj.KeywordData);
            obj.addHardwareKeywordData(keywordData);
        end
    end

     %% Hwmgr DataFactory Helper methods
     methods(Hidden)
        function doclinkData = createDocLinkData(obj, linkStruct)
            doclinkData = obj.DataFactory.createDocLinkData(linkStruct.ShortName, linkStruct.TopicId, linkStruct.Title);
        end

        function appData = createAppletData(obj, appStruct)
            % Construct Learn More DocLinkData object
            appLearnMoreDocLink = obj.createDocLinkData(obj.LearnMoreData);
            
            % Construct Troubleshooting DocLinkData object
            troubleshootingDocLink = obj.createDocLinkData(obj.TroubleshootingData);

            % Get BaseCodes for App
            spkgBaseCodes = obj.getSpkgBaseCodes(appStruct.AppletClass);

            % Construct AppletData object
            appData = obj.DataFactory.createAppletData(...
                appStruct.DisplayName, appStruct.AppletClass, ...
                appStruct.PluginClass, appStruct.Description, ...
                appStruct.IconID, appLearnMoreDocLink, troubleshootingDocLink, ...
                "ToolboxBaseCodes", obj.ICTAddOn.BaseCode, ...
                "SupportPackageBaseCodes", spkgBaseCodes);
        end

        function addOnData = createAddOnData(obj, addOnStruct)
            if ~addOnStruct.PlatformSupported
                addOnData = [];
                return
            end

            % If user has not specified a dependency, explicitly initialize
            % its corresponding field using a default value.

            dependenciesToCheck = ["RequiredBaseCode", ...
                                   "AsyncioDevicePlugin", ...
                                   "AsyncioConverterPlugin", ...
                                   "ClientEnumeratorAddOnSwitch"];

            for dependency = dependenciesToCheck
                addOnStruct = initUnspecifiedDependency(addOnStruct, dependency);
            end

            addOnData = obj.DataFactory.createAddOnData( ...
                    addOnStruct.BaseCode, ...
                    addOnStruct.Name,...
                    addOnStruct.RequiredBaseCode,...
                    "AsyncioDevicePlugin", addOnStruct.AsyncioDevicePlugin, ... Device plugin location
                    "AsyncioConverterPlugin", addOnStruct.AsyncioConverterPlugin, ... Converter plugin location
                    "ClientEnumeratorAddOnSwitch", addOnStruct.ClientEnumeratorAddOnSwitch ... Enable device enumeration using Asyncio plugin
                    );

            function addOnConfig = initUnspecifiedDependency(addOnConfig, dependency)
                % Explicitly initialize unspecified fields to empty,
                % indicating there is no dependency
                if ~isfield(addOnConfig, dependency)
                    addOnConfig.(dependency) = string.empty();
                end
            end
        end

        function hwKeyData = createHardwareKeywordData(obj, keywordStruct)
            % Create map of manufacturer basecodes
            basecodeMap = containers.Map([obj.SupportedAddOns.Manufacturer], {obj.SupportedAddOns.BaseCode});
            
            % Construct HardwareKeywordData object
            hwKeyData = obj.DataFactory.createHardwareKeywordData( ...
                keywordStruct.Keyword, keywordStruct.Description, ...
                keywordStruct.Tooltip, ...
                obj.HardwareCategory, ...
                "Manufacturers", basecodeMap, ...
                "ManufacturerPlaceholder", obj.ManufacturerPlaceholder);
        end

        function baseCodes = getSpkgBaseCodes(obj, appletClass)
            % Get relevant support package base codes for the given applet
            switch appletClass
                case obj.VISAExplorerAppletStruct.AppletClass
                    baseCodes = [obj.SupportedAddOns.BaseCode];
                otherwise
                    baseCodes = [];
            end
        end
     end

    %% Struct creation Helper methods
    methods(Static, Access = private)
        % MAKEAPPLETSTRUCT - Helper method for encapsulating Applet Data
        % within standardized struct.
        function appDataStruct = makeAppletStruct(displayName, iconID, appletClass, ...
                pluginClass, description)
            arguments
                displayName (1, 1) string
                iconID (1, 1) string
                appletClass (1, 1) string
                pluginClass (1, 1) string
                description (1, 1) string
            end

            % Create AppData struct
            appDataStruct = struct(...
                "DisplayName", displayName, "IconID", iconID, ...
                "AppletClass", appletClass, "PluginClass", pluginClass, ...
                "Description", description);
        end

        % MAKEDOCLINKDATA - Helper method for encapsulating DocLink Data
        % within standardized struct.
        function docLinkDataStruct = makeDocLinkDataStruct(productShortName, docTopicId, title)
            arguments
                productShortName (1, 1) string
                docTopicId (1, 1) string
                title (1, 1) string
            end

            docLinkDataStruct = struct( ...
                "ShortName", productShortName, ...
                "TopicId", docTopicId, ...
                "Title", title);
        end

        % MAKEADDONSTRUCT - Helper method for encapsulating AddOn Data
        % within standardized struct.
        function addOnStruct = makeAddOnStruct(name, baseCode, nameValueArgs)
            arguments
                name (1, 1) string
                baseCode (1, 1) string
                nameValueArgs.Manufacturer string = string.empty()
                nameValueArgs.RequiresICT (1, 1) logical = true
                nameValueArgs.AsyncioDevicePlugin = string.empty()
                nameValueArgs.ClientEnumeratorAddOnSwitch = string.empty()
                nameValueArgs.PlatformSupported (1, 1) logical = true
            end

            addOnStruct = struct("Name", name, "BaseCode", baseCode);

            % Add Manufacturer name for support packages
            if ~isempty(nameValueArgs.Manufacturer)
                addOnStruct.Manufacturer = nameValueArgs.Manufacturer;
            end

            % Add ICT as a RequiredBaseCode for support packages
            if nameValueArgs.RequiresICT
                addOnStruct.RequiredBaseCode = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.ICTAddOn.BaseCode;
            end

            if ~isempty(nameValueArgs.AsyncioDevicePlugin)
                addOnStruct.AsyncioDevicePlugin = string(nameValueArgs.AsyncioDevicePlugin);
            end
            
            if ~isempty(nameValueArgs.ClientEnumeratorAddOnSwitch)
                addOnStruct.ClientEnumeratorAddOnSwitch = string(nameValueArgs.ClientEnumeratorAddOnSwitch);
            end            

            addOnStruct.PlatformSupported = nameValueArgs.PlatformSupported;
        end

        % MAKEKEYWORDSTRUCT - Helper method for encapsulating Keyword Data
        % within standardized struct.
        function keywordDataStruct = makeKeywordStruct(keyword, description, tooltip)
            arguments
                keyword (1, 1) string
                description (1, 1) string
                tooltip (1, 1) string
            end

            keywordDataStruct = struct( ...
                "Keyword", keyword, ...
                "Description", description, ...
                "Tooltip", tooltip);
        end

        % GETSUPPORTEDADDONS Check all AddOns for platform support,
        % returning a vector of AddOns that are supported on the current
        % platform.
        function supportedAddOns = getSupportedAddOns()
            import matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin

            allAddOns = [ ...
                        VISAExplorerDataPlugin.NIVISAAddOn, ...
                        VISAExplorerDataPlugin.RSVISAAddOn, ...
                        VISAExplorerDataPlugin.KeysightVISAAddOn, ...
                        ];

            supportedAddOns = allAddOns([allAddOns.PlatformSupported]);
        end

        function keywordDescriptionString = getKeywordDescriptionString()
            if ispc
                keywordDescriptionString = getString(message("hwmanagerapp:clientappdata:visaexplorer:KeywordDescriptionWindows"));
            elseif ismac
                keywordDescriptionString = getString(message("hwmanagerapp:clientappdata:visaexplorer:KeywordDescriptionMac"));
            else
                % Not supported on Linux
                keywordDescriptionString = "";
            end
        end
    end
end

function s = makeAddOnStructHelper(addOnName, baseCode, manufacturer, devicePath, platformSupported)
% For the client enumerator add on switch is a base code of the add-on...
% "whose installation status is used as a switch to decide if client
% enumerator or device provider should be enabled"
productCode = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.ProductCode;
s = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.makeAddOnStruct( ...
            addOnName, ...
            baseCode, ...
            "Manufacturer", manufacturer, ...
            "AsyncioDevicePlugin", devicePath, ... Device plugin location
            "ClientEnumeratorAddOnSwitch", productCode, ...see g2922925 
            "PlatformSupported", platformSupported);
end

function devicePath = getRSVISADevicePath
if ispc
    devicePath = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.DevicePath;
elseif ismac
    devicePath = matlab.hwmgr.internal.data.plugins.VISAExplorerDataPlugin.RSDevicePath;
else
    % Not supported on Linux
    devicePath = "";
end
end