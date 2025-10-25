function disableAddonWithNameOrIdentifierAndVersion (NameOrIdentifier, Version)

% disableAddonWithNameOrIdentifierAndVersion disables an add-on in Java Desktop
%
% Copyright 2021-2022 The MathWorks, Inc.

import com.mathworks.addons_common.notificationframework.InstalledAddOnsCache;
import com.mathworks.addon_enable_disable_management.AddonEnableDisableManager;


try
    installedAddonsCache = InstalledAddOnsCache.getInstance;

    % Begin: Return if there is not enabled add-on version
    if (nargin > 1)
        Version = convertStringsToChars(Version);
        % If the First argument is add-on name, then get Identifier
        % corresponding to add-on name and version
        NameOrIdentifier = getIdentifierForAddOnWithVersion(NameOrIdentifier, Version);

        if ~matlab.addons.isAddonEnabled(NameOrIdentifier, Version)
            return;
        end
    else
        % If the First argument is add-on name, then get Identifier
        % corresponding to add-on name to disable
        NameOrIdentifier = getIdentifierForAddOnToDisable(NameOrIdentifier);
        % If no add-on with add-on name is enabled.
        if isempty(NameOrIdentifier)
            return
        end
    end

    if ~installedAddonsCache.hasAddonWithIdentifier(NameOrIdentifier)
        error(message('matlab_addons:enableDisableManagement:invalidIdentifier'));
    end

    if ~installedAddonsCache.hasEnabledVersion(NameOrIdentifier)
        return;
    end
    % End: Return if there is not enabled add-on version

    % Retrieve enabled version and disable
    installedAddon = installedAddonsCache.retrieveEnabledAddOnVersion(NameOrIdentifier);
    if ~installedAddon.isEnableDisableSupported()
        error(message('matlab_addons:enableDisableManagement:notSupported'));
    end

    matlabPathEntries = retrieveCustomMetadataWithName(installedAddon, 'matlabPathEntries');
    matlab.internal.addons.removeFromMatlabPath(matlabPathEntries);

    installedAddon.setEnabled(false);
    installedAddonsCache.updateAddonState(installedAddon, false);

    javaClassPathEntries = retrieveCustomMetadataWithName(installedAddon, 'javaClassPathEntriesConverted');
    for idx = 1: size(javaClassPathEntries,1)
        matlab.internal.addons.removeFromJavaClasspath(javaClassPathEntries(idx,:));
    end

    AddonEnableDisableManager.unregisterServices(installedAddon);

    relatedAddOnIdentifiers = installedAddon.getRelatedAddOnIdentifiers();
    for relatedIdentifierIndex = 1: length(relatedAddOnIdentifiers)
        relatedAddonIdentifier = relatedAddOnIdentifiers(relatedIdentifierIndex);
        if installedAddonsCache.hasAddonWithIdentifier(relatedAddonIdentifier)
            relatedAddon = installedAddonsCache.retrieveAddOnWithIdentifier(relatedAddonIdentifier);
            AddonEnableDisableManager.unregisterServices(relatedAddon);
        end
    end
    matlab.internal.addons.registry.disableAddOn(string(installedAddon.getIdentifier), string(installedAddon.getVersion));
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
end

