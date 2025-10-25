classdef (Sealed = true) Sidepanel < handle
    % Sidepanel: This class manages the Add-Ons Sidepanel

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (Constant)
        SERVER_TO_CLIENT_CHANNEL = "/mw/addons/sidepanel/serverToClient";

        CLIENT_TO_SERVER_CHANNEL = "/mw/addons/sidepanel/clientToServer";

        MO_SERVER_TO_CLIENT_CHANNEL = "/matlab/addons/serverToClient";

        WINDOW_TITLE = message('matlab_addons:sidepanel:installerDialogTitle').getString;
    end

    methods (Access = private)
        function this = Sidepanel()
            % Subscribe to clientToServer channel
            connector.ensureServiceOn;

            uiMessageHandler = matlab.internal.addons.UiMessageHandler(matlab.internal.addons.Sidepanel.SERVER_TO_CLIENT_CHANNEL);
            message.subscribe(matlab.internal.addons.Sidepanel.CLIENT_TO_SERVER_CHANNEL, @(msg) uiMessageHandler.handleMessage(msg));
        end
    end

    methods (Static, Access = private)
        function manageSettings(enable)
            s = settings();
            if ~hasGroup(s.matlab.addons, 'sidepanel')
                addGroup(s.matlab.addons, 'sidepanel');
            end
            sidepanelGroup = s.matlab.addons.sidepanel;
            if ~hasSetting(sidepanelGroup, 'Enable')
                addSetting(sidepanelGroup, 'Enable');
            end
            % This is required to persist the visibility state of Side-panel across sessions
            if ~hasSetting(sidepanelGroup, 'State')
                addSetting(sidepanelGroup, 'State');
                sidepanelGroup.State.PersonalValue = '{"isVisible":"true"}';
            end
            sidepanelGroup.Enable.PersonalValue = enable;
        end

        function entitlementId = getEntitlementId()
            licenseMode = matlab.internal.licensing.getLicMode;
            entitlementId = licenseMode.entitlement_id;
        end

        function licenseMode = getLicenseMode()
            if matlab.internal.licensing.canAddonsAllowTrialsForLicense
                licenseMode = "FlexLicense";
            else
                licenseMode = "WebLicense";
            end
        end

        function matlabPlatform = getMatlabPlatform()
            import matlab.internal.capability.Capability
            isRemote = ~Capability.isSupported(Capability.LocalClient);

            if isRemote
                matlabPlatform = 'ml_online';
            else
                matlabPlatform = 'ml_desktop';
            end
        end
    end

    methods (Static, Access = public)
        % Persists Sidepanel state after next startup and opens Sidepanel
        % instead of Manager from toolstrip if argument is true
        function enableFeature
            matlab.internal.addons.Sidepanel.manageSettings(true);
        end

        function disableFeature
            matlab.internal.addons.Sidepanel.manageSettings(false);
        end

        function isEnabled = featureEnabled
            isEnabled = false;
            s = settings();
            if hasGroup(s.matlab.addons, 'sidepanel')
                sidepanelGroup = s.matlab.addons.sidepanel;
                if hasSetting(sidepanelGroup, 'Enable')
                    isEnabled = s.matlab.addons.sidepanel.Enable.ActiveValue;
                end
            end
        end

        function addPackagesFromCustomRepositoriesToPanel
            instance = matlab.internal.addons.Sidepanel.getInstance();
            instance.sendCustomRepositoriesMetadata();
        end

        function removeCustomRepositoryFromPanel(repositoryLocation)
            instance = matlab.internal.addons.Sidepanel.getInstance();
            instance.sendRemoveCustomRepository(repositoryLocation);
        end

        function obj = getInstance()
            mlock;
            persistent uniqueSidepanelInstance;
            if(isempty(uniqueSidepanelInstance))
                obj = matlab.internal.addons.Sidepanel();
                uniqueSidepanelInstance = obj;
            else
                obj = uniqueSidepanelInstance;
            end
        end

        function initialize()
            instance = matlab.internal.addons.Sidepanel.getInstance;
            if matlab.internal.feature("AddOnsCustomRepository")
                if ~matlab.internal.feature('mpm')
                    warning('Custom repositories in Add-Ons Side Panel is not supported when the mpm feature is not enabled. Start MATLAB with the -mpm command line switch.');
                    return;
                end
                instance.sendCustomRepositoriesMetadata();
            end
        end
    end

    methods (Access = public)
        % TODO: Use more NavigationData
        function show(obj, navigationData)
            % The only scenario where navidationData sent to side-panel contains 'loadApplicationUrl'
            % is when it is required to open the installer.
            % Open the installer url in a web-window for now

            messageToClient = struct('type', 'showAddOnsPanel');
            messageToClient.body = navigationData;
            obj.sendMessageToMOClient(messageToClient);
        end

        function hide(obj)
            messageToClient = struct('type', 'hideAddOnsPanel');
            obj.sendMessage(messageToClient);
        end

        function sendContextToUi(this)
            context = struct();
            context.arch = matlab.internal.addons.util.explorer.computerArch;
            context.entitlementId = matlab.internal.addons.Sidepanel.getEntitlementId;
            context.language = this.getLanguage();
            context.licensed = matlab.internal.addons.sidepanel.getLicensedAddOnsIdentifiers;
            context.licenseMode = matlab.internal.addons.Sidepanel.getLicenseMode;
            context.matlabPlatform = matlab.internal.addons.Sidepanel.getMatlabPlatform;
            context.release = this.getMATLABVersion;
            context.matlabUpdateLevel = matlabRelease.Update;
            context.endPointForUpgradeDownloadUrl = this.getEndPointForUpgradeDownloadUrl;
            messageToClient = struct('type', 'context', 'body', context);
            this.sendMessage(messageToClient);
		end

    end

    methods (Access = private)

        function language = getLanguage (~)
            s=settings; 
            language = s.matlab.datetime.DisplayLocale.ActiveValue;
        end

        function matlabVersion = getMATLABVersion (~)
            matlabVersion = ['R' version('-release')];

            if (strcmpi(version('-description'), 'Prerelease'))
                matlabVersion = [matlabVersion '_Prerelease'];
            end
        end

        function endPointForUpgradeDownloadUrl = getEndPointForUpgradeDownloadUrl (~)
            % Get end endPoint
            urlManager = matlab.internal.UrlManager;
            endPointForUpgradeDownloadUrl = urlManager.MATHWORKS_DOT_COM;

            % Get sandbox override if exists
            settingsAPI = settings;

            if settingsAPI.matlab.hasSetting('latestgr') && settingsAPI.matlab.latestgr.hasSetting('wsendpointoverride')
                endPointForUpgradeDownloadUrl = settingsAPI.matlab.latestgr.wsendpointoverride.ActiveValue;
            end
        end

        function sendMessage(~, msg)
            message.publish(matlab.internal.addons.Sidepanel.SERVER_TO_CLIENT_CHANNEL, msg);
        end

        function sendMessageToMOClient(~, msg)
            message.publish(matlab.internal.addons.Sidepanel.MO_SERVER_TO_CLIENT_CHANNEL, msg);
        end

        % TODO: Move this functionality to C++
        function sendRemoveCustomRepository(this, repositoryLocation)
            removeCustomRepositoryMessage = struct('type','removeCustomRepository','body',repositoryLocation);
            this.sendMessage(removeCustomRepositoryMessage);
        end

        function sendCustomRepositoriesMetadata(this)
            repositoriesList = mpmListRepositories();
            repositoriesData = struct('Name', [repositoriesList.Name], 'Location', [repositoriesList.Location]);
            addCustomRepositoriesListMessage = struct('type','addCustomRepositories','body', repositoriesData);
            this.sendMessage(addCustomRepositoriesListMessage);

            packagesMetadata = struct( ...
                'name',{}, ...
                'version',{}, ...
                'identifier',{}, ...
                'summary',{}, ...
                'description',{}, ...
                'repository',{}, ...
                'installer',{});

            mpmPackagesMetadata = matlab.mpm.internal.search();
            for i = 1:length(mpmPackagesMetadata)
                packagesMetadata(i).name = mpmPackagesMetadata(i).Package;
                packagesMetadata(i).version = mpmPackagesMetadata(i).Version;
                packagesMetadata(i).identifier = mpmPackagesMetadata(i).ID;
                packagesMetadata(i).summary = mpmPackagesMetadata(i).Summary;
                packagesMetadata(i).description = mpmPackagesMetadata(i).Description;
                packagesMetadata(i).repository = mpmPackagesMetadata(i).Repository;
                packagesMetadata(i).installer.packageSpecifier = join([mpmPackagesMetadata(i).Package mpmPackagesMetadata(i).Version packagesMetadata(i).identifier],'@');
            end
            % Remove this loop once mpm supports MLTBX files
            for i = 1:length(repositoriesList)
                repositoryFiles = dir(repositoriesList(i).Location);
                isMLTBX = endsWith({repositoryFiles.name},'.mltbx',IgnoreCase=true);
                isFile = ~[repositoryFiles.isdir];
                repositoryMLTBXFiles = repositoryFiles(isMLTBX & isFile);

                repositoryMLTBXFullyQualifiedPathStrings = string(append({repositoryMLTBXFiles.folder}, filesep, {repositoryMLTBXFiles.name}));
                for j = 1:length(repositoryMLTBXFullyQualifiedPathStrings)
                    mltbxMetadata = mlAddonGetProperties(repositoryMLTBXFullyQualifiedPathStrings{j});
                    mltbxPackageMetadata = struct;
                    mltbxPackageMetadata.version = mltbxMetadata.version;
                    mltbxPackageMetadata.name = mltbxMetadata.name;
                    mltbxPackageMetadata.identifier = mltbxMetadata.GUID;
                    mltbxPackageMetadata.summary = mltbxMetadata.summary;
                    mltbxPackageMetadata.description = mltbxMetadata.description;
                    mltbxPackageMetadata.repository = repositoriesList(i).Location;
                    mltbxPackageMetadata.installer.path = repositoryMLTBXFullyQualifiedPathStrings(j);
                    packagesMetadata(end + 1) = mltbxPackageMetadata;
                end
            end
            addMPMPackagesMessage = struct('type','addCustomAddOns','body',packagesMetadata);
            this.sendMessage(addMPMPackagesMessage);
        end
    end
end
