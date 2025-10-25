function installToolbox(fileName)
% This function performs the following given a mltbx file
%   1. Extract contents to toolbox root
%   2. Create resources folder
%   3. Installs related Apps
%   4. Notifies Add-on Management
%   5. Issues warnings

% Copyright 2018-2022 The MathWorks, Inc.

javaFileObject = java.io.File(fileName);
toolboxInstallationFolder = '';

% Retrieve metadata
addonProperties = mlAddonGetProperties(fileName);
identifier = addonProperties.GUID;
addonName = addonProperties.name;

try
    % Extract files
    addOnsInstallationFolder = java.io.File(matlab.internal.addons.util.retrieveAddOnsInstallationFolder).toPath;
    if isempty(char(addOnsInstallationFolder.toString))
        addOnsInstallationFolder =  setAddOnsInstallationFolderToDefault;
    end

    toolboxesHome = com.mathworks.toolboxmanagement.util.ManagerUtils.getToolboxesHome(addOnsInstallationFolder);
    toolboxInstallationFolder = com.mathworks.addons_common.util.FolderNameUtils.createNormalizedDestinationFolder(toolboxesHome, addonName);
    installView = com.mathworks.addons_common.installation_folder.InstallationFolderViewFactory.getDefaultView(toolboxInstallationFolder);
    codeFolder = installView.getCodeFolder;
    metadataFolder = installView.getMetadataFolder();
    createFolderIfNotExists(codeFolder);
    createFolderIfNotExists(metadataFolder);
    extractFiles(codeFolder);
    installedAddon = com.mathworks.toolboxmanagement.InstalledAddonConverter.convert(toolboxInstallationFolder, javaFileObject);
    metadataCreated = com.mathworks.addons_common.util.InstalledAddonMetadataUtils.installedAddonToMetadataFolder(codeFolder.toFile, installedAddon);
    if metadataCreated
        % Notify toolbox installed
        matlab.internal.addons.registry.addAddOn(string(installedAddon.getIdentifier()), string(installedAddon.getVersion()), true, string(toolboxInstallationFolder.toString));
        com.mathworks.addons_common.notificationframework.AddonManagement.addFolderFromMatlabApi(toolboxInstallationFolder, installedAddon);
        % Install Apps
        installContainedApps(toolboxInstallationFolder);

        %compatibility check
        toolboxPackage = com.mathworks.mladdonpackaging.AddonPackage(javaFileObject);
        systemReqs = toolboxPackage.getSystemRequirements();
        isCompatible = com.mathworks.toolboxmanagement.util.CompatibilityUtils.isCompatible(systemReqs);
        if (~isCompatible)
            warning(message('toolboxmanagement_matlab_api:installToolbox:incompatibleToolbox', char(addonName)));
        end

        %if had additional SW dependencies, warn they're not installed
        hasAdditionalSoftware = toolboxPackage.requiresAdditionalSoftware();
        if hasAdditionalSoftware
            warning(message('matlab_addons:install:noAdditionalSoftwareInstall', char(addonName)));
        end
    else
        abortInstallation();
        error(message('matlab_addons:install:invalidToolboxFile'));
    end
catch ex
    abortInstallation();
    rethrow(ex);
    % Determine if 'Not writable' message needs to be displayed
%     if isprop(ex, 'ExceptionObject') && ...
%             (~isempty(strfind(ex.ExceptionObject.getMessage, 'AccessDeniedException')) || ...
%             ~isempty(strfind(ex.ExceptionObject.getMessage, 'IOException')))
%         error(message('toolboxmanagement_matlab_api:installToolbox:accessDeniedInstallationPath'));
%     elseif isprop(ex, 'ExceptionObject') && ...
%             ~isempty(strfind(ex.ExceptionObject.getClass, 'AddonPackageIOException'))
%         error(message('toolboxmanagement_matlab_api:installToolbox:invalidToolboxFile'));
%     else
%         error(ex.message);
%     end
end

    function extractFiles(destinationFolder)
        toolboxPackage = com.mathworks.mladdonpackaging.AddonPackage(javaFileObject);
        com.mathworks.toolboxmanagement.util.ToolboxInstallerUtils.extractFiles(destinationFolder, toolboxPackage);
    end

    function abortInstallation
        if ~isempty(toolboxInstallationFolder)
            rmdir(toolboxInstallationFolder.toString, 's');
        end
    end

    function installContainedApps(toolboxInstallationFolder)
        appsToInstall = mlAddonGetAppInstallList(fileName);
        for appInstallCounter = 1: size(appsToInstall,1)
            appToInstall = appsToInstall(appInstallCounter);
            appRelativePath = appToInstall.relativePath;
            codeFolder = char(toolboxInstallationFolder.toString);
            appFileLocation = fullfile(codeFolder, char(appRelativePath));
            com.mathworks.appmanagement.actions.AppInstaller.install(java.io.File(appFileLocation));
        end
    end

    function createFolderIfNotExists(folderToCreate)
        com.mathworks.toolboxmanagement.util.ToolboxInstallerUtils.createFolderIfNotExists(folderToCreate);
    end
end
