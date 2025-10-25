function uninstall(nameOrIdentifier, addOnVersion)

    %  UNINSTALL uninstall add-on
    %
    %   MATLAB.ADDONS.UNINSTALL(NAME) uninstalls the add-on
    %   with the specified NAME
    %
    %   MATLAB.ADDONS.UNINSTALL(NAME,VERSION) uninstalls the add-on
    %   with the specified NAME and VERSION
    %   
    %   MATLAB.ADDONS.UNINSTALL(NAME,'All') uninstalls all installed versions of the
    %   specified add-on if multiple versions are installed.
    %
    %   MATLAB.ADDONS.UNINSTALL(IDENTIFIER) uninstalls the add-on
    %   with the specified IDENTIFIER
    %
    %   MATLAB.ADDONS.UNINSTALL(IDENTIFIER,VERSION) uninstalls the add-on
    %   with the specified IDENTIFIER and VERSION
    %   
    %   MATLAB.ADDONS.UNINSTALL(IDENTIFIER,'All') uninstalls all installed versions of the
    %   specified add-on if multiple versions are installed.
    %
    %   Note: UNINSTALL only supports uninstalling Community Add-Ons 
    %   Example
    %   addons = matlab.addons.installedAddons
    %
    %   addons =
    %
    %   1x4 table
    %
    %             Name             Version    Enabled                  Identifier              
    %    ______________________    _______    _______    ______________________________________
    %
    %    "My cool toolbox_v4.0"     "4.0"      true      "6de8682e-9c3c-407e-bad7-aa103d738d08"
    %
    %   matlab.addons.uninstall(addons.Identifier(1), addons.Version(1));
    %
    %   See also: matlab.addons.install,
    %   matlab.addons.installedAddons
    
    % Copyright 2018-2022 The MathWorks Inc.
    
    narginchk(1,2);
    
    uninstallAllOption = 'All';
    if nargin < 2
        validateArgs("matlab.addons.uninstall", nameOrIdentifier);
    else
        validateArgs("matlab.addons.uninstall", nameOrIdentifier, addOnVersion);
    end
    nameOrIdentifier = convertStringsToChars(nameOrIdentifier);
    
    try
        
        % Start: Handle error conditions
        if (nargin < 2)
            % Check if first argument is add-on name before checking for identifier
            nameOrIdentifier = getIdentifierForUninstall(nameOrIdentifier);
            
            if ~hasAnyVersionInstalled(nameOrIdentifier)
                error(message('matlab_addons:enableDisableManagement:invalidIdentifier'));
            elseif hasMultipleVersionsInstalled(nameOrIdentifier)
                error(message('matlab_addons:uninstall:multipleVersionsInstalled'));
            end
        else
            % Check if first argument is add-on name before checking for identifier
            addOnVersion = convertStringsToChars(addOnVersion);
            
            if strcmpi(addOnVersion, uninstallAllOption) == 1
                nameOrIdentifier = getIdentifierForUninstall(nameOrIdentifier);
                if ~hasAnyVersionInstalled(nameOrIdentifier)
                    error(message('matlab_addons:enableDisableManagement:invalidIdentifier'));
                end
            else
                nameOrIdentifier = getIdentifierForAddOnWithVersion(nameOrIdentifier, addOnVersion);
                if ~hasAddOnWithIdentifierAndVersion(nameOrIdentifier, addOnVersion)
                    error(message('matlab_addons:enableDisableManagement:invalidIdentifierAndVersion'));
                end
            end
        end
        
        % End: Handle error conditions
        
        if (nargin < 2)
            addOnVersion = matlab.internal.addons.registry.getVersionForAddOnWithIdentifier(nameOrIdentifier);
            uninstallAddon(nameOrIdentifier, addOnVersion);
        else
            addOnVersion = convertStringsToChars(addOnVersion);
            if (strcmpi(addOnVersion, uninstallAllOption) == 1)
                % Uninstall all versions of the add-on
                addons = matlab.addons.installedAddons;
                addonrows = (string(addons.Identifier) == string(nameOrIdentifier));
                for count=1:length(addonrows)
                    if addonrows(count)
                        % ToDo: Continue looping if uninstalling an add-on
                        % fails
                        uninstallAddon(addons.Identifier(count), addons.Version(count));
                    end
                end
            else
                % Uninstall specific version
                uninstallAddon(nameOrIdentifier, addOnVersion);
            end
        end
    catch ex
        error(ex.identifier, ex.message);
    end
    
        function uninstallAddon(addOnIdentifier, addOnVersion)
            addOnManagementMetadata = matlab.internal.addons.registry.getMetadata(string(addOnIdentifier), string(addOnVersion));
            addOnTypesServiced = ["toolbox", "app", "zip"];
            addonType = addOnManagementMetadata.addOnType;
            if ~any(strcmpi(addOnTypesServiced, addonType))
                error(message('matlab_addons:uninstall:invalidAddonType'));
            end
    
            try
                addOnName = addOnManagementMetadata.name;
                installationRoot = string(addOnManagementMetadata.installationRoot);
                registrationRoot = string(addOnManagementMetadata.registrationRoot);
                % Retrieve the installedFolders for included apps
                includedAppIds = addOnManagementMetadata.includedAppIds;
                includedAppFolders = string.empty;
                
                for index=1:length(includedAppIds)
                    try
                        includedAppFolders(index) = matlab.internal.addons.registry.getInstallationRootForEnabledOrMostRecentlyInstalledVersion(string(includedAppIds(index)));
                    catch ex
                        % No-Op. Proceed to the next one
                    end
                end
                
                % Disable and unregister Add-On along with included apps
                matlab.addons.disableAddon(string(addOnIdentifier), string(addOnVersion));
                matlab.internal.addons.registry.removeAddOn(string(addOnIdentifier), string(addOnVersion));
                
                % Unregister Add-On from Java infrastructure
                if usejava('jvm')
                    removeFromJavaInfrastructure(string(addOnIdentifier), string(addOnVersion));
                end
                
                % Delete included App folders
                try
                    for index = 1: length(includedAppFolders)
                        if exist(string(includedAppFolders(index)), 'dir')
                            rmdir(string(includedAppFolders(index)), 's'); 
                        end
                    end
                catch ex
                    % No-Op since the App is already unregistered
                end
    
    
                % Delete the Add-On folder
                if exist(installationRoot, 'dir')
                    rmdir(installationRoot, 's');
                end
    
            catch ex
                if ~hasAddOnWithIdentifierAndVersion(string(addOnIdentifier), string(addOnVersion))
                    if (isFolderOnJavaclasspath(registrationRoot))
                        warning(message('matlab_addons:uninstall:deleteFailedLockedJar', registrationRoot));
                    else
                        warning (message('matlab_addons:uninstall:deleteFailed', addOnName, registrationRoot));
                    end
                else
                    error(message('matlab_addons:uninstall:uninstallfailed', addOnName));
                end
            end
        end
    
        function containsFolderOnPath = isFolderOnJavaclasspath (installedFolder)
            staticJcpEntries = javaclasspath('-static');
            containsFolderOnJcp= contains(staticJcpEntries, string(installedFolder));
            containsFolderOnPath = any(containsFolderOnJcp(:));
        end
    end