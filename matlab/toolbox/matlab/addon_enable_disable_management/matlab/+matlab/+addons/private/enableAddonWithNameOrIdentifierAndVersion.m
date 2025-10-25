function enableAddonWithNameOrIdentifierAndVersion (NameOrIdentifier, Version)

% enableAddonWithNameOrIdentifierAndVersion enables an add-on in Java Desktop
%
%   enableAddonWithNameOrIdentifierAndVersion(NAME) enables
%   the add-on with the specified add-on NAME.
%
%   enableAddonWithNameOrIdentifierAndVersion(NAME, VERSION) enables
%   the add-on with the specified NAME and VERSION.
%
%   enableAddonWithNameOrIdentifierAndVersion(IDENTIFIER) enables
%   the add-on with the specified IDENTIFIER.
%
%   IDENTIFIER is the unique identifier of the add-on to be enabled,
%   specified as a string or character vector. To determine the
%   unique identifier of an add-on, use the
%   matlab.addons.installedAddons function.
%
%   enableAddonWithNameOrIdentifierAndVersion(IDENTIFIER, VERSION) enables
%   the add-on with the specified IDENTIFIER and VERSION.
%

% Copyright 2021-2023 The MathWorks, Inc.

    import com.mathworks.addons_common.notificationframework.InstalledAddOnsCache;
    import com.mathworks.addon_enable_disable_management.AddonEnableDisableManager;

    NameOrIdentifier = convertStringsToChars(NameOrIdentifier);

    % TODO: Wrap this logic inside RegistrationManagement.m
    try
        installedAddonsCache = InstalledAddOnsCache.getInstance;

        if (nargin < 2)
            % If the First argument is add-on name, then get Identifier
            % corresponding to add-on name
            NameOrIdentifier = getIdentifierForAddOn(NameOrIdentifier);
            if hasMultipleVersionsInstalled(NameOrIdentifier)
                error(message('matlab_addons:enableDisableManagement:multipleVersionsInstalledSpecifyVersionToEnable'));
            end
            installedAddon = installedAddonsCache.retrieveAddOnWithIdentifier(NameOrIdentifier);
        else
            Version = convertStringsToChars(Version);
            % If the First argument is add-on name, then get Identifier
            % corresponding to add-on name and version
            NameOrIdentifier = getIdentifierForAddOnWithVersion(NameOrIdentifier, Version);
            installedAddon = installedAddonsCache.retrieveAddOnWithIdentifierAndVersion(NameOrIdentifier, Version);
        end

        if ~installedAddon.isEnableDisableSupported()
            error(message('matlab_addons:enableDisableManagement:notSupported'));
        end

        % disable currently enabled version if exists
        if installedAddonsCache.hasEnabledVersion(NameOrIdentifier)
            enabledAddon = installedAddonsCache.retrieveEnabledAddOnVersion(NameOrIdentifier);
            if strcmpi(enabledAddon.getVersion, installedAddon.getVersion) == 0
                matlab.addons.disableAddon(enabledAddon.getIdentifier, enabledAddon.getVersion);
            end
        end

        matlabPathEntries = retrieveCustomMetadataWithName(installedAddon, 'matlabPathEntries');

        for matlabPathIndex = 1:length(matlabPathEntries)
            matlabPathEntry = char(matlabPathEntries(matlabPathIndex));
            addpath(matlabPathEntry, '-end');
            matlab.internal.path.ExcludedPathStore.addToCurrentExcludeList(matlabPathEntry);
        end

        installedAddon.setEnabled(true);
        installedAddonsCache.updateAddonState(installedAddon, true);

        javaClassPathEntries = retrieveCustomMetadataWithName(installedAddon, 'javaClassPathEntriesConverted');
        
        addJavaClassPathEntries(javaClassPathEntries);

        AddonEnableDisableManager.registerServices(installedAddon);

        relatedAddOnIdentifiers = installedAddon.getRelatedAddOnIdentifiers();
        for relatedIdentifierIndex = 1: length(relatedAddOnIdentifiers)
            relatedAddonIdentifier = relatedAddOnIdentifiers(relatedIdentifierIndex);
            if installedAddonsCache.hasAddonWithIdentifier(relatedAddonIdentifier)
                relatedAddon = installedAddonsCache.retrieveAddOnWithIdentifier(relatedAddonIdentifier);
                AddonEnableDisableManager.registerServices(relatedAddon);
            end
        end
        matlab.internal.addons.registry.enableAddOn(string(installedAddon.getIdentifier), string(installedAddon.getVersion));
    catch ex
        if isprop(ex, 'ExceptionObject') && ...
                ~isempty(strfind(ex.ExceptionObject.getClass, 'IdentifierNotFoundException'))
            error(message('matlab_addons:enableDisableManagement:invalidIdentifier'));
        elseif isprop(ex, 'ExceptionObject') && ...
                ~isempty(strfind(ex.ExceptionObject.getClass, 'AddOnNotFoundException'))
            error(message('matlab_addons:enableDisableManagement:invalidIdentifierAndVersion'));
        else
            error(ex.identifier, ex.message);
        end
    end
    
    % The java classpath entries added here are not required by the product
    % itself but is required only to support Mock Add-On infrastructure.
    % Remove as part of https://jira.mathworks.com/browse/FILESYSUI-5116
    function addJavaClassPathEntries(javaClassPathEntries)
        % Ignore warning if not found in path
        w = warning('off', 'MATLAB:javaclasspath:invalidFile');
        clean = onCleanup(@()warning(w));

        for jcpIndex = 1:length(javaClassPathEntries)
            jcpEntry = char(javaClassPathEntries(jcpIndex));
            javaaddpath(jcpEntry, '-end');
        end

    end
end
