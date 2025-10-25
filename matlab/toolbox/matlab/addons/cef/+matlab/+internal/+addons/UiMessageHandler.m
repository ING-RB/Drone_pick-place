classdef(Sealed = true, Hidden = true) UiMessageHandler < handle
    % UIMESSAGEHANDLER Contains callbacks that respond to messages received
    % from Add-on Explorer & Add-on Manager

    %   Copyright 2019-2025 The MathWorks, Inc.

    properties (Constant)
        EXPLORER_ENTRY_POINT_IDENTIFIER_FOR_GET_ADDONS_LINK = "AddOns"
    end
    properties (Access = private)
        % This struct contains handlers to callback functions to respond to
        % messages from Add-on Explorer/Manager
        messageHandlers = struct()

        uiMessageChannel
        permanentNames = {}
        temporaryHandle = 0;
        identifierToPermanentHandle = containers.Map();
    end

    methods (Access = {?matlab.internal.addons.Manager, ?matlab.internal.addons.Explorer, ?matlab.internal.addons.Sidepanel})
        function this = UiMessageHandler(channelToSendMsgToUi)
            this.uiMessageChannel = channelToSendMsgToUi;
            this.messageHandlers.(lower("openFolder")) = @matlab.internal.addons.UiMessageHandler.openFolder;
            this.messageHandlers.(lower("openGetAddons")) = @matlab.internal.addons.UiMessageHandler.openGetAddOns;
            this.messageHandlers.(lower("openFileExchange")) = @matlab.internal.addons.UiMessageHandler.openFileExchange;
            this.messageHandlers.(lower("getAvailableFeatures")) = @this.handleGetAvailableFeatures;
            this.messageHandlers.(lower("openAddOnManager")) = @this.handleOpenAddOnManager;
            this.messageHandlers.(lower("openSystemBrowser")) = @this.handleOpenSystemBrowser;
            this.messageHandlers.(lower("enable")) = @this.handleEnable;
            this.messageHandlers.(lower("disable")) = @this.handleDisable;
            this.messageHandlers.(lower("openGalleryDetailPage")) = @this.handleOpenGalleryDetailPage;
            this.messageHandlers.(lower("downloadAddOn")) = @this.handleDownloadAddOn;
            this.messageHandlers.(lower("openDocumentationPage")) = @this.handleOpenDocumentationPage;
            this.messageHandlers.(lower("viewDetailPage")) = @this.handleViewDetailPage;
            this.messageHandlers.(lower("uninstallAddOnForSidePanel")) = @this.handleUninstallAddOn;
            if feature('webui')
                    this.messageHandlers.(lower("performAdditionalAction")) = @this.handlePerformAdditionalAction;
            end
            this.messageHandlers.(lower("getAvailableUpdates")) = @this.handleGetAvailableUpdates;
            this.messageHandlers.(lower("addSetupAndOpenDocToSupportPackages")) = @this.handleAddSetupAndOpenDocToSupportPackages;
            this.messageHandlers.(lower("installAddOnFromSidePanel")) = @this.handleInstallAddOnFromSidePanel;
            this.messageHandlers.(lower("openViewFilteredBySourceInExplorer")) = @this.handleOpenViewFilteredBySourceInExplorer;
            this.messageHandlers.(lower("openAddOnSearchResultsViewInExplorer")) = @this.handleOpenAddOnSearchResultsViewInExplorer;
            this.messageHandlers.(lower("openAddOnRecommendedViewInExplorer")) = @this.handleOpenAddOnRecommendedViewInExplorer;
            this.messageHandlers.(lower("openManageAddOnsFromExplorer")) = @this.handleOpenManageAddOnsFromExplorer;
        end

        function handleMessage(this, msg)
            try
                this.messageHandlers.(lower(msg.type))(msg);
            catch ME
                if strcmpi('MATLAB:nonExistentField', ME.identifier)
                    % Do not display error until all the UI messages are
                    % handled in MATLAB
                end
            end
        end
    end

    methods (Access = public)
        function openedState = checkIfPermanentPageOpened(this, msg)
            if ~ismember({msg.identifier}, this.permanentNames)
                openedState = false;
            else
                if isprop(this.identifierToPermanentHandle(msg.identifier), 'Input')
                    openedState = true;
                else
                    openedState = false;
                end
            end
        end
        function handleViewDetailPage(this, msg)
            identifier = msg.identifier;
            addOnVersion = msg.version;
            connector.ensureServiceOn;
            connector.newNonce;
            urlString = sprintf('toolbox/matlab/addons_detail/index-debug.html?navigateTo={"identifier":"%s","version":"%s"}', identifier, addOnVersion);
            url = connector.getUrl(urlString);
            if msg.singleClick
                % check if it's already opened (no matter temporary or permanent)
                try
                    titleValue = this.temporaryHandle.Title;
                catch
                    this.temporaryHandle = 1;
                end
                if (isprop(this.temporaryHandle, 'Input') && isprop(this.temporaryHandle, 'Title') && strcmp(this.temporaryHandle.Title, msg.name)) || this.checkIfPermanentPageOpened(msg)
                    % do nothing
                else
                    if isprop(this.temporaryHandle, 'Input')
                        % If a temporary page is already opened
                        this.temporaryHandle.Input = url;
                        this.temporaryHandle.Title = msg.name;
                    else
                        this.temporaryHandle = htmlviewer(url,"ShowToolbar",false,"NewTab",true);
                        this.temporaryHandle.Title = msg.name;
                    end
                    msg.temporary = true;
                    updateDetailPageMsg = struct('type', 'updateDetailPageHTMLTab', 'body', msg);
                    message.publish(this.uiMessageChannel, updateDetailPageMsg);
                end
            else
                if this.checkIfPermanentPageOpened(msg)
                    % If the documentis already opened as a permanent tab
                    % do nothing
                else
                    newPermanentHandle = htmlviewer(url,"ShowToolbar",false,"NewTab",true);
                    newPermanentHandle.Title = msg.name;
                    if ~ismember({msg.identifier}, this.permanentNames)
                         this.permanentNames
                         this.permanentNames = [this.permanentNames {msg.identifier}];
                    end
                    this.identifierToPermanentHandle(msg.identifier) = newPermanentHandle;
                end
            end
        end
    end

    methods (Static, Access = public)
        % ToDo: Add test point when
        % com.mathworks.addons_common.util.settings.InstallLocation class
        % is ported to MATLAB by providing a utility to update matlab
        % platform to ml_online for testing.(g2105327)
        function openFolder(msgBody)

            % ToDo: Always use c++ back-end when installation root and registration root locations are unified
            if feature('webui')
                openFolderAction(msgBody);
                return;
            end

            if isfield(msgBody, "version")
                addOnVersion = msgBody.version;
            else
                addOnVersion = matlab.internal.addons.util.getEnabledOrMostRecentlyInstalledVersionUsingJavaApi(msgBody.identifier);
            end
            installedAddOn = com.mathworks.addons_common.notificationframework.InstalledAddOnsCache.getInstance.retrieveAddOnWithIdentifierAndVersion(msgBody.identifier, addOnVersion);
            folderToCd = com.mathworks.addons_common.util.settings.InstallationFolderUtils.replaceWritableInstallLocationWithReadOnlyInstallLocation(installedAddOn.getInstalledFolder);
            cd(string(folderToCd.toString));
            com.mathworks.addons_common.util.MatlabDesktopUtils.bringMatlabToFront();
        end

        function openGetAddOns(~)
            matlab.internal.addons.launchers.showExplorer(matlab.internal.addons.UiMessageHandler.EXPLORER_ENTRY_POINT_IDENTIFIER_FOR_GET_ADDONS_LINK);
        end

        function openFileExchange(~)
            % ToDo: Request for a WS end point for File Exchange so that it can point to the correct integ-env
            fileExchangeUrl = "https://www.mathworks.com/matlabcentral/fileexchange";
            web(fileExchangeUrl, "-browser");
        end

        function handleGetAvailableFeatures(~)
            matlab.internal.addons.explorer.sendAvailabeFeatures();
        end

        function handleGetAvailableUpdates(~)
            % ToDo: Uncomment the line below after Java Transitioning community add-on updates infrastructure
            % matlab.internal.addons.manager.sendAvailabeUpdates();
            % matlab.internal.addons.updates.sendSupportPackageUpdatesToAddOnManager();
        end

        function handleOpenAddOnManager(msg)
            if isfield(msg, "identifier") && ~isempty(msg.identifier)
                if isfield(msg, "version") && ~isempty(msg.version)
                    matlab.internal.addons.launchers.showManager("aoe", "identifier", msg.identifier, "version", msg.version);
                else
                    matlab.internal.addons.launchers.showManager("aoe", "identifier", msg.identifier);
                end
            else
                matlab.internal.addons.launchers.showManager("aoe");
            end
        end

        function handleOpenSystemBrowser(msg)
            if ~isempty(msg.url)
                web(msg.url, "-browser");
            end
        end

        function handleEnable(msg)
            if ~isempty(msg.identifier)
                if isfield(msg, 'version') && ~isempty(msg.version)
                    matlab.addons.enableAddon(msg.identifier, msg.version);
                else
                    matlab.addons.enableAddon(msg.identifier);
                end
            end
        end

        function handleDisable(msg)
            if ~isempty(msg.identifier)
                if isfield(msg, 'version') && ~isempty(msg.version)
                    matlab.addons.disableAddon(msg.identifier, msg.version);
                else
                    matlab.addons.disableAddon(msg.identifier);
                end
            end
        end

        function handleOpenGalleryDetailPage(msg)
            EXPLORER_ENTRY_POINT_IDENTIFIER_FOR_ADDONS_MANAGER = "AddOns";
            if ~isempty(msg.version)
                matlab.internal.addons.launchers.showExplorer(EXPLORER_ENTRY_POINT_IDENTIFIER_FOR_ADDONS_MANAGER, "identifier", msg.identifier, "version", msg.version);
            else
                matlab.internal.addons.launchers.showExplorer(EXPLORER_ENTRY_POINT_IDENTIFIER_FOR_ADDONS_MANAGER, "identifier", msg.identifier);
            end
        end

        function handleDownloadAddOn(msg)
            if strcmpi(msg.addOnType, 'support_package')
                % This is handled by Java layer
                % ToDo: Provide MATLAB API to trigger download using Add-On
                % Manager (g2636062)
                return;
            end

            if isempty(msg.url)
                return;
            end

            metadataFileUrl = msg.url;

            if isLocalClient
                defaultDownloadLocation = pwd;
                matlab.internal.addons.util.explorer.sendOpenSaveAsDialog(metadataFileUrl, defaultDownloadLocation);
            else
                matlab.internal.addons.util.explorer.sendShowSaveToMatlabDriveDialog(metadataFileUrl);
            end
        end

        function handleUninstallAddOn(msg)
            if isfield(msg,'packageSpecifier')
                evalc("mpmuninstall(msg.packageSpecifier,'Prompt',false)");
                return;
            end

            addOnType = msg.addOnType;
            identifier = msg.identifier;
            addOnVersion = msg.version;
            
            % Java uninstaller does not support uninstalling support
            % packages. UI invokes support package uninstaller using a
            % different route.            
            if strcmp('support_package', addOnType) == 1
                return;
            end
            if ~any(strcmp({'support_package', 'product', 'mock'}, addOnType))
                matlab.internal.addons.registry.uninstallAsynchronously(identifier, addOnVersion);
                % Unregister Add-On from Java infrastructure
                if usejava('jvm')
                    matlab.internal.addons.UiMessageHandler.removeFromJavaInfrastructure(string(identifier), string(addOnVersion));
                end
            else
                if usejava('jvm')
                    com.mathworks.addons_common.notificationframework.AddonManagement.uninstall(identifier, addOnVersion);
                end
            end
        end

        function handlePerformAdditionalAction(msg)
            actionId = msg.actionId;
            identifier = msg.identifier;
            addOnVersion = msg.version;

            addOnManagementMetadata = getAddOnManagementMetadataForAddOn(identifier, addOnVersion);

            if ~isfield(addOnManagementMetadata, 'actions')
                return;
            end
            additionalActions = addOnManagementMetadata.actions;
            for i = 1:size(additionalActions,1)
                if isfield(additionalActions(i), 'id') && strcmpi(additionalActions(i).id, actionId)
                    eval(additionalActions(i).callback);
                    return;
                end
            end
        end

        function handleOpenDocumentationPage(msg)
            actionId = 'openDocumentation';
            identifier = msg.identifier;

            if strcmpi(identifier, 'ML')
                doc('ML');
                return;
            end

            % Explorer does not include addOnType in the message. So, check for the existance of the field
            % Manager has Open Documentation for Support Packages (which are not part of c++ infrastructure yet)
            % So special case it.
            if isfield(msg, 'addOnType') && strcmpi(msg.addOnType, 'support_package')
                matlab.supportpackagemanagement.internal.util.openDocumentationForSupportPackage(identifier);
                return;
            end

            % Explorer does not include version of the add-on in the
            % message. So fetch it using registry
            if ~isfield(msg, 'version')
                addOnVersion = matlab.internal.addons.registry.getVersionForAddOnWithIdentifier(identifier);
            else
                addOnVersion = msg.version;
            end

            addOnManagementMetadata = getAddOnManagementMetadataForAddOn(identifier, addOnVersion);

            if ~isfield(addOnManagementMetadata, 'actions')
                return;
            end

            additionalActions = addOnManagementMetadata.actions;
            for i = 1:size(additionalActions,1)
                if isfield(additionalActions(i), 'id') && strcmpi(additionalActions(i).id, actionId)
                    eval(additionalActions(i).callback);
                    return;
                end
            end
        end

        % This is a temporary workaround to allow adding Setup action to Support Packages
        % until spkgs start writing resources folder with extension metadata
        function handleAddSetupAndOpenDocToSupportPackages(~)
            supportPackagesWithNoSetup = matlab.internal.addons.UiMessageHandler.getSupportPackagesWithNoSetup();
            supportPackageIds = {supportPackagesWithNoSetup.identifier};

            spkgsWithSetup = matlabshared.supportpkg.internal.ssi.getBaseCodesHavingHwSetup(supportPackageIds);

            spkgWithExamples = getSupportPackagesToAddDocumentation();
            matlab.internal.addons.registry.updateSupportPackagesToIncludeSetupAndDocumentation(convertCharsToStrings(spkgsWithSetup), ...
             convertCharsToStrings(spkgWithExamples));
        end

        function handleInstallAddOnFromSidePanel(msg)
            if isfield(msg, 'packageSpecifier')
                evalc("mpminstall(msg.packageSpecifier,'Prompt',false)");
                return;
            end
            if (isfield(msg, 'path'))
                open(msg.path);
                return;
            end
            matlab.internal.addons.installer.downloadAndInstall(msg);
        end

        function handleOpenAddOnSearchResultsViewInExplorer(msg)
            matlab.internal.addons.launchers.showExplorer(msg.entryPointId, 'keyword', msg.keyword);
        end

        function handleOpenViewFilteredBySourceInExplorer(msg)
            matlab.internal.addons.launchers.showExplorer(msg.entryPointId, 'source', msg.source);
        end

        function handleOpenAddOnRecommendedViewInExplorer(msg)
            matlab.internal.addons.launchers.showExplorer(msg.entryPointId, 'recommended', true);
        end

        function handleOpenManageAddOnsFromExplorer(msg)
        
            if feature('webui')
                matlab.internal.addons.sidepanel.show(msg.entryPoint, "view", msg.view);
            else
                matlab.internal.addons.UiMessageHandler.handleOpenAddOnManager(msg);
            end
        end
        
        % ToDo: Remove when all the support packages implement extension
        % metadata for add-ons
        function supportPackagesWithNoSetup = getSupportPackagesWithNoSetup (~)
            supportPackagesWithNoSetup = getSupportPackagesWithNoSetupAction();
        end

        function removeFromJavaInfrastructure(addOnIdentifier, addOnVersion)
            import com.mathworks.addons_common.notificationframework.InstalledAddOnsCache;
            installedAddOnsCache = InstalledAddOnsCache.getInstance;
            addOnToUninstall = installedAddOnsCache.retrieveAddOnWithIdentifierAndVersion(addOnIdentifier, addOnVersion);
            relatedAddOnIdentifiers = addOnToUninstall.getRelatedAddOnIdentifiers;
            % Unregister the included apps
            for i=1: length(relatedAddOnIdentifiers)
                try
                    relatedAddOn = installedAddOnsCache.retrieveAddOnWithIdentifier(relatedAddOnIdentifiers(i));
                    com.mathworks.addons_common.notificationframework.AddonManagement.removeFolder(relatedAddOn.getInstalledFolder, relatedAddOn);
                catch ex
                    % No logging required since the exception happens only if the
                    % included app is not in registry
                end
            end
            com.mathworks.addons_common.notificationframework.AddonManagement.removeFolder(addOnToUninstall.getInstalledFolder, addOnToUninstall);
        end
    end
end
