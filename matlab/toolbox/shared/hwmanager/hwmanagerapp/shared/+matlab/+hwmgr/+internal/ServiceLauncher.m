classdef ServiceLauncher < handle
    %SERVICELAUNCHER This class has all the utility functions to launch
    %services for Hardware Manager.

    % Copyright 2021 The MathWorks, Inc.

    methods
        function openUrlInBrowser(~,url)
            web(url, '-browser');
        end

        function openWithHelpView(~,shortName, topicId)
            helpview(shortName, topicId);
        end

        function installerLaunched = installAddOn(obj,baseCode, ssiCloseFcn)
            arguments
                obj
                baseCode string
                ssiCloseFcn function_handle = function_handle.empty
            end
            installerLaunched = matlab.hwmgr.internal.ServiceLauncher.getInstallerTypeForBaseCode(baseCode);
            switch installerLaunched
                case "SSI"
                    % Open SSI for support package
                    matlab.hwmgr.internal.util.launchSSIForBaseCode(baseCode, ssiCloseFcn);
                case "AddOnExplorerDetail"
                    % Open AddOn Explorer installation page for support
                    % package or toolbox
                    matlab.hwmgr.internal.util.installAddOn("Hardware Manager", "identifier", baseCode);
                case "AddOnExplorer"
                    % Open AddOn Explorer landing page if base code not found
                    obj.openAddOnExplorer();
            end
        end

        function openAddOnExplorer(~)
            matlab.internal.addons.launchers.showExplorer('Hardware Manager');
        end
    end

    methods (Static, Hidden)
        function installerType = getInstallerTypeForBaseCode(baseCode)
            dataStore = matlab.hwmgr.internal.DataStoreHelper.getDataStore();

            if isfield(dataStore.SupportPackageGeneralData, baseCode)
                % Check if spkg requires any toolbox that is not installed
                requiredProductBaseCode = dataStore.getSpkgRequiredProduct(baseCode);
                if isempty(requiredProductBaseCode) || requiredProductBaseCode == "ML" || matlab.hwmgr.internal.util.isInstalled(requiredProductBaseCode)
                    installerType = "SSI";
                else
                    installerType = "AddOnExplorerDetail";
                end
            elseif isfield(dataStore.ToolboxGeneralData, baseCode)
                installerType = "AddOnExplorerDetail";
            else
                installerType = "AddOnExplorer";
            end
        end
    end
end