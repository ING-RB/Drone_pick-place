classdef DontSeeDeviceDialog < handle
    % DontSeeDeviceDialog - Back-end hardware manager utility class that serves
    % as the model for the "I don't see my device" dialog. This class
    % provides the data to be shown on the dialog and provided callback
    % implementations of the dialog buttons. This class is primarily used
    % by the Start Page module.
    
    % Copyright 2021-2024 The MathWorks, Inc.

    properties
        % DATASTORE - handle to the DataStore object that provides the
        % addon and troubleshooting links data for the applet
        DataStore

        % APPLETCLASS - The class name of the applet that is showing the
        % dialog. Used to retrieve data for the applet from the store
        AppletClass

        % ServiceLauncher - The class that launches the different links,
        % Add Ons Explorer and SSI window.
        ServiceLauncher
    end

    methods
        function obj = DontSeeDeviceDialog(appletClass)
            obj.AppletClass = appletClass;
            dataStoreHelper = matlab.hwmgr.internal.DataStoreHelper();
            obj.DataStore = dataStoreHelper.getDataStore();
            obj.ServiceLauncher = matlab.hwmgr.internal.ServiceLauncher();
        end

        % ---------BEGIN----Server messages to front end---------------------------%

        function pageData = getPageData(obj)

            % Initialize page data
            pageData = [];

            appletData = obj.DataStore.getLaunchableData(string(obj.AppletClass));

            if isempty(appletData)
                return;
            end

            pageData = obj.convertDataForFrontEnd(appletData);
        end

        function out = convertDataForFrontEnd(obj, appletData)
            % This method takes applet data from the data store and
            % converts it into a struct array of data that can be sent to
            % the front end over the connector channel. 

            out = struct('RequiredAddons', '', 'TroubleshootingLinks', '');

            % Required Addons - get the related addons for the app by
            % getting the basecode, full name to be displayed and whether
            % the addon is installed

            spkgBaseCodes = appletData.SupportPackageBaseCodes;

            if iscolumn(spkgBaseCodes)
                spkgBaseCodes = spkgBaseCodes';
            end

            toolboxBaseCodes = appletData.ToolboxBaseCodes;

            if iscolumn(toolboxBaseCodes)
                toolboxBaseCodes = toolboxBaseCodes';
            end

            baseCodes = [spkgBaseCodes toolboxBaseCodes];

            requiredAddons = [];
            for i = 1:numel(baseCodes)
                addonViewData = struct();
                addonData = obj.DataStore.getAddOnsByBaseCodes(baseCodes(i));
                addonViewData.name = addonData.FullName;
                addonViewData.basecode = addonData.BaseCode;
                try
                    addonViewData.installed = matlab.hwmgr.internal.util.isInstalled(char(addonData.BaseCode));
                catch
                    addonViewData.installed = false;
                end
                
                requiredAddons = [requiredAddons; addonViewData];
            end

            % If there is only one requiredAddon, wrap it in a cell array for
            % always sending an array over to the front end
            if numel(requiredAddons) == 1
                requiredAddons = {requiredAddons};
            end

            out.RequiredAddons = requiredAddons;

            % Troubleshooting links - each troubleshooting link has a url,
            % a text label for the link
            tsLinks = [appletData.TroubleshootingLinks];
            % TopicId is unique to DocLinkData, use it to determine the
            % link data format
            if isprop(tsLinks, 'TopicId')
                tsLinksData = struct('ShortName', {tsLinks.ShortName}, 'TopicId', {tsLinks.TopicId}, 'Title', {tsLinks.Title}, 'Url', {tsLinks.Url});
            else
                tsLinksData = struct('Title', {tsLinks.Title}, 'Url', {tsLinks.Url});
            end

            % If there is only one troubleshooting link, wrap it in a cell
            % array for always sending an array over to the front end
            if numel(tsLinksData) == 1
                tsLinksData = {tsLinksData};
            end

            % If there are no troubleshooting links, assign the
            % TroubleShootingLinks struct field to an empty cell array so
            % it appears empty to the front end. Otherwise send the
            % TroubleshootingLinks array
            if isempty(tsLinksData)
                out.TroubleshootingLinks = {};
            else
                out.TroubleshootingLinks = tsLinksData;
            end

            out = [out];
        end

        % ---------END------Server messages to front end---------------------------%


        % ---------BEGIN----Client side callbacks----------------------------------%

        function clientOpenHwmgrApp(obj,msg)
            matlab.hwmgr.internal.launchHardwareManager;
        end

        function clientOpenTsLink(obj, linkData)
            if isfield(linkData, "TopicId")
                obj.ServiceLauncher.openWithHelpView(linkData.ShortName, linkData.TopicId);
            else
                obj.ServiceLauncher.openUrlInBrowser(linkData.Url);
            end
        end

        function clientInstallAddon(obj, basecode, ssiCloseFcn)
            arguments
                obj
                basecode string
                ssiCloseFcn function_handle = function_handle.empty
            end
            obj.ServiceLauncher.installAddOn(basecode, ssiCloseFcn);
        end
        % ---------END------Client side callbacks----------------------------------%
    end

end
