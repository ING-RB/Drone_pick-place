classdef IMAQDataPlugin < matlab.hwmgr.internal.data.plugins.PluginBase
    %IMAQDATAPLUGIN Data plugin class for IMAQ HWMgr Apps.

    % Copyright 2022-2023 The MathWorks, Inc.
    
    properties
        DataFactory = matlab.hwmgr.internal.data.DataFactory
    end

    properties(Constant, Access = private)
        % App Data
        IMAQExplorerAppletStruct = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAppletStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:AppName")), ... Display Name
            "imageAcquisitionExplorerApp", ... Icon ID
            "imaqapplet.applet.IMAQApplet", ... Applet Class
            "matlab.hwmgr.plugins.IMAQPlugin", ... Plugin Class
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:AppDescription")), ... Description
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:AppLearnMoreLinkTitle")), ... LearnMore Link Title
            "www.mathworks.com/help/imaq/imageacquisitionexplorer-app.html") ... LearnMore Link URL
            % @TODO g2587385 Check the link above once doc is ready

        % Troubleshooting
        TroubleshootingData = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeLinkDataStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:IMAQTroubleshootingLinkTitle")), ... Title
            "https://www.mathworks.com/help/imaq/troubleshooting-1.html") ... URL
            % @TODO g2587385 Reconsider this link once app doc is
            % completed. There may be a more app-specific troubleshooting
            % doc page.

        % AddOn Data
        IMAQAddOn = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:IMAQAddOnName")), ... Name
            "IA", ... Base Code
            "RequiresIMAQ", false)

        OSVidAddOn = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:OSGenericSpkgName")), ... Name
            "OSVIDEO", ... Base Code
            "Adaptor", getString(message("hwmanagerapp:clientappdata:imaqexplorer:OSGenericAdaptorName"))) ... Adaptor Name

        DCAMAddOn = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:DCAMSpkgName")), ... Name
            "DCAM", ... Base Code
            "Adaptor", getString(message("hwmanagerapp:clientappdata:imaqexplorer:DCAMAdaptorName"))) ... Adaptor Name

        GenTLAddOn = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:GenTLSpkgName")), ... Name
            "GENICAM", ... Base Code
            "Adaptor", getString(message("hwmanagerapp:clientappdata:imaqexplorer:GenTLAdaptorName")), ... Adaptor Name
            "PlatformSupported", ~ismac() ) ... Check if platform is supported for add on

        GigEAddOn = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:GigESpkgName")), ... Name
            "GIGEVISION", ... Base Code
            "Adaptor", getString(message("hwmanagerapp:clientappdata:imaqexplorer:GigEAdaptorName"))) ... Adaptor Name

        % Kinect
        KinectAddOn = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:KinectSpkgName")), ... Name
            "KINECT", ... Base Code
            "Adaptor", getString(message("hwmanagerapp:clientappdata:imaqexplorer:KinectAdaptorName")), ... Adaptor Name
            "PlatformSupported", ispc() ) ... Check if platform is supported for add on

        % Matrox
        MatroxAddOn = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:MatroxSpkgName")), ... Name
            "MATROX", ... Base Code
            "Adaptor", getString(message("hwmanagerapp:clientappdata:imaqexplorer:MatroxAdaptorName")), ... Adaptor Name
            "PlatformSupported", ispc() ) ... Check if platform is supported for add on

        % NI
        NIAddOn = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:NISpkgName")), ... Name
            "NIFRAME", ... Base Code
            "Adaptor", getString(message("hwmanagerapp:clientappdata:imaqexplorer:NIAdaptorName")), ... Adaptor Name
            "PlatformSupported", ispc() ) ... Check if platform is supported for add on

        % Pointgrey
        PointgreyAddOn = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:PointgreySpkgName")), ... Name
            "POINTGREY", ... Base Code
            "Adaptor", getString(message("hwmanagerapp:clientappdata:imaqexplorer:PointgreyAdaptorName")), ... Adaptor Name
            "PlatformSupported", ispc() ) ... Check if platform is supported for add on

        % DALSA
        DALSAAddOn = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeAddOnStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:DALSASpkgName")), ... Name
            "DALSASAP", ... Base Code
            "Adaptor", getString(message("hwmanagerapp:clientappdata:imaqexplorer:DALSAAdaptorName")), ... Adaptor Name
            "PlatformSupported", ispc() ) ... Check if platform is supported for add on

        % Keyword Data
        KeywordData = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeKeywordStruct( ...
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:Keyword")), ... Keyword
            matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.getKeywordDescriptionString(), ... Description
            getString(message("hwmanagerapp:clientappdata:imaqexplorer:KeywordTooltip"))) ... Tooltip
    
        % Binary file names for device plugins
        DevicePluginData = struct("osvideo_win64","DShowCameraDetector",...
            "osvideo_glnxa64", "libmwGSTCameraDetector",...
            "osvideo_maci64","libmwAVFCameraDetector",...
            "osvideo_maca64","libmwAVFCameraDetector")
    end

    properties(Access = private)
        SupportedAddOns = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.getSupportedAddOns()
    end
    
    methods
        function obj = IMAQDataPlugin()
            %APPLET DATA
            imaqExplAppletData = obj.createAppletData(obj.IMAQExplorerAppletStruct);
            obj.addAppletData(imaqExplAppletData);

            % ADDON DATA
            imaqAddOnData = obj.createAddOnData(obj.IMAQAddOn);
            obj.addAddOnData(imaqAddOnData);
            
            % OS Generic Video
            osvideoAddOn = obj.createAddOnDataWithClientEnum(obj.OSVidAddOn);
            obj.addAddOnData(osvideoAddOn);

            % DCAM
            dcamAddOn = obj.createAddOnData(obj.DCAMAddOn);
            obj.addAddOnData(dcamAddOn);

            % GenTL
            gentlAddOn = obj.createAddOnData(obj.GenTLAddOn);
            obj.addAddOnData(gentlAddOn);

            % GigE
            gigeAddOn = obj.createAddOnData(obj.GigEAddOn);
            obj.addAddOnData(gigeAddOn);

            % Kinect
            kinectAddOn = obj.createAddOnData(obj.KinectAddOn);
            obj.addAddOnData(kinectAddOn);

            % Matrox
            matroxAddOn = obj.createAddOnData(obj.MatroxAddOn);
            obj.addAddOnData(matroxAddOn);

            % NI
            niAddOn = obj.createAddOnData(obj.NIAddOn);
            obj.addAddOnData(niAddOn);

            % Pointgrey
            pointgreyAddOn = obj.createAddOnData(obj.PointgreyAddOn);
            obj.addAddOnData(pointgreyAddOn);

            % Dalsa
            dalsaAddOn = obj.createAddOnData(obj.DALSAAddOn);
            obj.addAddOnData(dalsaAddOn);

            % HARDWARE KEYWORD DATA
            keywordData = obj.createHardwareKeywordData(obj.KeywordData);
            obj.addHardwareKeywordData(keywordData);

        end
    end

    methods(Access = private)
        function linkData = createLinkData(obj, linkStruct)
            linkData = obj.DataFactory.createLinkData(linkStruct.Title, linkStruct.Link);
        end

        function hwKeyData = createHardwareKeywordData(obj, keywordStruct)
            % Create map of manufacturer basecodes
            basecodeMap = containers.Map([obj.SupportedAddOns.Manufacturer], {obj.SupportedAddOns.BaseCode});
            
            % Construct HardwareKeywordData object
            hwKeyData = obj.DataFactory.createHardwareKeywordData( ...
                keywordStruct.Keyword, keywordStruct.Description, ...
                keywordStruct.Tooltip, ...
                "HardwareType", ...
                "Manufacturers", basecodeMap);
        end

        function appData = createAppletData(obj, appStruct)
            % Construct "Learn More" link object from app data struct
            appLearnMoreLink = obj.createLinkData(appStruct.LearnMoreLink);
            
            % Construct Troubleshooting LinkData
            troubleshootingLink = obj.createLinkData(obj.TroubleshootingData);

            % Get BaseCodes for App
            spkgBaseCodes = obj.getSpkgBaseCodes(appStruct.AppletClass);

            % Construct AppletData object
            appData = obj.DataFactory.createAppletData(...
                appStruct.DisplayName, appStruct.AppletClass, ...
                appStruct.PluginClass, appStruct.Description, ...
                appStruct.IconID, appLearnMoreLink, troubleshootingLink, ...
                "ToolboxBaseCodes", obj.IMAQAddOn.BaseCode, ...
                "SupportPackageBaseCodes", spkgBaseCodes);
        end

        function addOnData = createAddOnDataWithClientEnum(obj, addOnStruct)
            if ~addOnStruct.PlatformSupported
                addOnData = [];
                return
            end

            % Get the right dev plugin struct field name from basecode and platform, 
            % as defined in const properties block above
            fieldName = strcat(lower(addOnStruct.BaseCode),"_", computer('arch'));

            imaqConPlugin = fullfile(matlabroot, "toolbox", "shared", "hwmanager", "hwmanagerapp", "clientenumerator", "bin", computer('arch'), "hwmgr_converter");
            imaqDevPlugin = fullfile(matlabroot, "toolbox", "shared", "testmeaslib", "hwutils", "shared_camera_util", "bin", computer('arch'), obj.DevicePluginData.(fieldName));

            addOnData = obj.DataFactory.createAddOnData(...
                addOnStruct.BaseCode, addOnStruct.Name,...
                "AsyncioDevicePlugin", imaqDevPlugin, "AsyncioConverterPlugin", imaqConPlugin, "ClientEnumeratorAddOnSwitch", "OSVIDEO");
        end

        function addOnData = createAddOnData(obj, addOnStruct)
            if ~addOnStruct.PlatformSupported
                addOnData = [];
                return
            end

            if isfield(addOnStruct, "RequiredBaseCode")
                % Construct AddOnData object for AddOns with dependencies
                addOnData = obj.DataFactory.createAddOnData( ...
                    addOnStruct.BaseCode, addOnStruct.Name, addOnStruct.RequiredBaseCode);
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
                case obj.IMAQExplorerAppletStruct.AppletClass
                    baseCodes = [obj.SupportedAddOns.BaseCode];
                otherwise
                    baseCodes = [];
            end
        end

    end

    methods(Static, Access = private)
        % MAKEAPPLETSTRUCT - Helper method for encapsulating Applet Data
        % within standardized struct.
        function appDataStruct = makeAppletStruct(displayName, iconID, appletClass,...
                pluginClass, description, troubleshootingTitle, troubleshootingLink)

            % Create LinkData struct for relevent troubleshooting link
            troubleshootLinkStruct = matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.makeLinkDataStruct( ...
                troubleshootingTitle, troubleshootingLink);

            % Create AppData struct
            appDataStruct = struct(...
                "DisplayName", displayName, "IconID", iconID, ...
                "AppletClass", appletClass, "PluginClass", pluginClass, ...
                "Description", description, ...
                "LearnMoreLink", troubleshootLinkStruct);
        end

        % MAKELINKDATA - Helper method for encapsulating Link Data
        % within standardized struct.
        function linkDataStruct = makeLinkDataStruct(title, link)
            linkDataStruct = struct( ...
                "Title", string(title), ...
                "Link", link);
        end

        % MAKEADDONSTRUCT - Helper method for encapsulating AddOn Data
        % within standardized struct.
        function addOnStruct = makeAddOnStruct(name, baseCode, nameValueArgs)
            arguments
                name
                baseCode
                nameValueArgs.Adaptor = string.empty()
                nameValueArgs.RequiresIMAQ = true
                nameValueArgs.PlatformSupported = true
            end

            addOnStruct = struct("Name", string(name), "BaseCode", string(baseCode));

            % Add Manufacturer name for support packages
            if ~isempty(nameValueArgs.Adaptor)
                addOnStruct.Manufacturer = string(nameValueArgs.Adaptor);
            end

            % Add IMAQ as a RequiredBaseCode for support packages
            if nameValueArgs.RequiresIMAQ
                addOnStruct.RequiredBaseCode = string(matlab.hwmgr.internal.data.plugins.IMAQDataPlugin.IMAQAddOn.BaseCode);
            end

            addOnStruct.PlatformSupported = nameValueArgs.PlatformSupported;
        end

        % MAKEADDONSTRUCT - Helper method for encapsulating Keyword Data
        % within standardized struct.
        function keywordDataStruct = makeKeywordStruct(keyword, description, tooltip)
            keywordDataStruct = struct( ...
                "Keyword", keyword, ...
                "Description", description, ...
                "Tooltip", tooltip);
        end

        % GETSUPPORTEDADDONS Check all AddOns for platform support,
        % returning a vector of AddOns that are supported on the current
        % platform.
        function supportedAddOns = getSupportedAddOns()
            import matlab.hwmgr.internal.data.plugins.IMAQDataPlugin

            allAddOns = [ ...
                        IMAQDataPlugin.OSVidAddOn, ...
                        IMAQDataPlugin.DCAMAddOn, ...
                        IMAQDataPlugin.GenTLAddOn, ...
                        IMAQDataPlugin.GigEAddOn, ...
                        IMAQDataPlugin.KinectAddOn, ...
                        IMAQDataPlugin.MatroxAddOn, ...
                        IMAQDataPlugin.NIAddOn, ...
                        IMAQDataPlugin.PointgreyAddOn, ...
                        IMAQDataPlugin.DALSAAddOn, ...
                        ];

            supportedAddOns = allAddOns([allAddOns.PlatformSupported]);
        end

        function keywordDescriptionString = getKeywordDescriptionString()
            if ispc
                keywordDescriptionString = getString(message("hwmanagerapp:clientappdata:imaqexplorer:KeywordDescriptionWindows"));
            elseif ismac
                keywordDescriptionString = getString(message("hwmanagerapp:clientappdata:imaqexplorer:KeywordDescriptionMac"));
            else
                keywordDescriptionString = getString(message("hwmanagerapp:clientappdata:imaqexplorer:KeywordDescriptionLinux"));
            end
        end
    end
end

