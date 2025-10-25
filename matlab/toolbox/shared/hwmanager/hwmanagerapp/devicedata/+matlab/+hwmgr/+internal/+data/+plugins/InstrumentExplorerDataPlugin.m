classdef InstrumentExplorerDataPlugin < matlab.hwmgr.internal.data.plugins.PluginBase
    %InstrumentExplorerDataPlugin is the data plugin class for the Instrument Explorer app

    % Copyright 2023 The MathWorks, Inc.

    properties
        DataFactory = matlab.hwmgr.internal.data.DataFactory
    end

    properties(Constant)
        %% AppletData Constants
        AppName (1, 1) string = ...
            message("hwmanagerapp:clientappdata:instrumentexplorer:AppName").string

        AppDescription (1, 1) string = ...
            message("hwmanagerapp:clientappdata:instrumentexplorer:ToolTipText").string

        AppIcon (1, 1) string = ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.getAppIcon()

        % Learn More Link
        LearnMoreText (1, 1) string = ...
            message("hwmanagerapp:clientappdata:instrumentexplorer:AppName").string

        % Troubleshooting Link
        TroubleshootingText (1, 1) string = ...
            message("hwmanagerapp:clientappdata:instrumentexplorer:TroubleshootHeading").string

        % ProductShortName and Doc Topic Ids
        ProductShortName (1, 1) string = "instrument"
        DocTopicId (1, 1) string = "instrumentExplorer"
        TroubleshootTopicId (1, 1) string = "ividevTroubleshooting"

        AppletClass (1, 1) string = "ividevapp.IvidevApp"
        PluginClass (1, 1) string = "matlab.hwmgr.plugins.IvidevPlugin"

        %% Hardware Keyword Constants
        HardwareKeyword (1, 1) string = ...
            message("hwmanagerapp:clientappdata:instrumentexplorer:Keyword").string

        HardwareDescription (1, 1) string = ...
            message("hwmanagerapp:clientappdata:instrumentexplorer:KeywordDescription").string

        HardwareTooltip (1, 1) string = ...
            message("hwmanagerapp:clientappdata:instrumentexplorer:ToolTipText").string

        HardwareCategory (1, 1) matlab.hwmgr.internal.data.HardwareKeywordCategory = ...
            matlab.hwmgr.internal.data.HardwareKeywordCategory.HardwareType

        %% Add-On Constants
        % Toolbox and Support package base code names
        ProductCode (1, 1) string = "IC"
        NIVISABasedCode (1, 1) string = "ICT_NI_VISA_ICP_INTERFACES"

        % Add-On Names
        ICTAddOnName (1, 1) string = message("hwmanagerapp:clientappdata:instrumentexplorer:ICTAddOnName").string
        NIVISAAddOnName (1, 1) string = message("hwmanagerapp:clientappdata:instrumentexplorer:NIVISAAddOnName").string
    end

    properties(Constant, Hidden)
        % App Data
        IVIDEVExplorerAppletStruct = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.makeAppletStruct( ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.AppName, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.AppIcon, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.AppletClass, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.PluginClass, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.AppDescription)

        % Learn more Data
        LearnMoreData = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.makeDocLinkDataStruct( ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.ProductShortName, matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.DocTopicId, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.LearnMoreText)

        % Troubleshooting Data
        TroubleshootingData = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.makeDocLinkDataStruct( ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.ProductShortName, matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.TroubleshootTopicId, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.TroubleshootingText)

        % AddOn Data
        ICTAddOn = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.makeAddOnStruct( ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.ICTAddOnName, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.ProductCode, ...
            "RequiresICT", false)

        NIVISAAddOn = makeAddOnStructHelper(...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.NIVISAAddOnName, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.NIVISABasedCode, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.DevicePath, ... Device plugin location
            ispc)

        % Keyword Data
        KeywordData = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.makeKeywordStruct( ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.HardwareKeyword, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.HardwareDescription, ...
            matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.HardwareTooltip)

        % Client Enumerator Device Plugin (used by all Windows plugins)
        DevicePath = fullfile(toolboxdir("shared"), "testmeaslib", "hwutils", "instrument", "private", computer("arch"), "libmwshared_testmeaslib_hwutils_instrument")

        % Used for finding the correct Icon
        HasIconPathProp (1, 1) logical = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.hasIconPathProp()
    end

    properties(Access = private)
        SupportedAddOns = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.getSupportedAddOns()
    end

    methods
        function obj = InstrumentExplorerDataPlugin()
            if ~ispc
                return
            end
            %% Applet Data
            ividevaExplorerAppData = obj.createAppletData(obj.IVIDEVExplorerAppletStruct);
            obj.addAppletData(ividevaExplorerAppData);

            %% Addon Data
            ictAddOnData = obj.createAddOnData(obj.ICTAddOn);
            obj.addAddOnData(ictAddOnData);

            % NI
            nivisaAddOn = obj.createAddOnData(obj.NIVISAAddOn);
            obj.addAddOnData(nivisaAddOn);

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
            [iconFieldName, ~] = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.getIconDetails("DeviceCardOrAppletDataIcon");

            appData = obj.DataFactory.createAppletData(...
                appStruct.DisplayName, appStruct.AppletClass, ...
                appStruct.PluginClass, appStruct.Description, ...
                appStruct.(iconFieldName), appLearnMoreDocLink, troubleshootingDocLink, ...
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

            % Construct HardwareKeywordData object
            hwKeyData = obj.DataFactory.createHardwareKeywordData( ...
                keywordStruct.Keyword, keywordStruct.Description, ...
                keywordStruct.Tooltip, ...
                obj.HardwareCategory, ...
                "KeywordRelatedBaseCodes", {obj.SupportedAddOns.BaseCode});
        end

        function baseCodes = getSpkgBaseCodes(obj, appletClass)
            % Get relevant support package base codes for the given applet
            switch appletClass
                case obj.IVIDEVExplorerAppletStruct.AppletClass
                    baseCodes = [obj.SupportedAddOns.BaseCode];
                otherwise
                    baseCodes = [];
            end
        end
    end

    %% Struct creation Helper methods
    methods (Static, Access = private)
        % MAKEAPPLETSTRUCT - Helper method for encapsulating Applet Data
        % within standardized struct.
        function appDataStruct = makeAppletStruct(displayName, icon, appletClass, ...
                pluginClass, description)
            arguments
                displayName (1, 1) string
                icon (1, 1) string
                appletClass (1, 1) string
                pluginClass (1, 1) string
                description (1, 1) string
            end

            [iconFieldName, ~] = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.getIconDetails("DeviceCardOrAppletDataIcon");

            % Create AppData struct
            appDataStruct = struct(...
                "DisplayName", displayName, iconFieldName, icon, ...
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
                addOnStruct.RequiredBaseCode = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.ICTAddOn.BaseCode;
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
            import matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin
            allAddOns = InstrumentExplorerDataPlugin.NIVISAAddOn;
            supportedAddOns = allAddOns([allAddOns.PlatformSupported]);
        end

        function icon = getAppIcon()
            % Returns app icon by id or path.
            [~, icon] = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.getIconDetails("AppIcon");
        end
    end

    methods (Static)
        function flag = hasIconPathProp()
            flag = any(string(properties("matlab.hwmgr.internal.Device"))' == "IconPath");
        end

        function [iconFieldName, icon] = getIconDetails(iconType, icon)
            % Returns the iconFieldName -"IconPath" or "IconID" and also
            % returns the icon by id or by path.
            arguments
                iconType (1, 1) string
                icon = []
            end

            iconFieldName = string.empty;
            if iconType == "ToolstripIcon"
                if matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.HasIconPathProp
                    icon = matlab.ui.internal.toolstrip.Icon(icon);
                end
            elseif iconType == "DeviceCardOrAppletDataIcon"
                iconFieldName = "IconID";
                if matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.HasIconPathProp
                    iconFieldName = "IconPath";
                end
            elseif iconType == "AppIcon"
                % Returns app icon by id or path.
                icon = "instrumentExplorerApp";
                if matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.HasIconPathProp
                    icon = fullfile("toolbox", "shared", "hwmanager", "hwmanagerapp", "devicedata", "icons", "instrumentExplorerApp.svg");
                end
            end
        end
    end
end

function s = makeAddOnStructHelper(addOnName, baseCode, devicePath, platformSupported)
% For the client enumerator add on switch is a base code of the add-on...
% "whose installation status is used as a switch to decide if client
% enumerator or device provider should be enabled"
productCode = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.ProductCode;
s = matlab.hwmgr.internal.data.plugins.InstrumentExplorerDataPlugin.makeAddOnStruct( ...
    addOnName, ...
    baseCode, ...
    "AsyncioDevicePlugin", devicePath, ... Device plugin location
    "ClientEnumeratorAddOnSwitch", productCode, ...
    "PlatformSupported", platformSupported);
end