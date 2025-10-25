function [identifier] = getIdentifierForAddOnWithVersion(addOnNameOrIdentifier, addOnVersion)
%
% This is a private function and is not meant to be called directly.
% Copyright 2019 - 2021 The MathWorks, Inc.

% This returns identifier value corresponding to an add-on name and version,
% Throws error if more than one identifier found for specified name and version.

if feature('webui')
    identifier = getIdentifierForAddOnWithVersionFromRegistry(addOnNameOrIdentifier, addOnVersion);
    return;
end

allInstalledAddOns = matlab.addons.installedAddons;
identifier = addOnNameOrIdentifier;
uninstallAllOption = 'All';

if strcmpi(addOnVersion, uninstallAllOption) == 1
    identifierFromNameAndVersion = allInstalledAddOns.Identifier(lower(allInstalledAddOns.Name) == lower(string(addOnNameOrIdentifier)),:);
    for count=1:length(identifierFromNameAndVersion)
        if ~isempty(identifierFromNameAndVersion(count))
            installedAddonsCache = com.mathworks.addons_common.notificationframework.InstalledAddOnsCache.getInstance;
            installedAddon = installedAddonsCache.retrieveAddOnWithIdentifier(identifierFromNameAndVersion(count));
            addonType = string(installedAddon.getType);
            if strcmpi(addonType, "Toolbox") 
                identifier = identifierFromNameAndVersion(count);
                return;
            end
        end
    end
else
    identifierFromNameAndVersion = allInstalledAddOns.Identifier(lower(allInstalledAddOns.Name) == lower(string(addOnNameOrIdentifier)) & allInstalledAddOns.Version == string(addOnVersion),:);

    if (length(identifierFromNameAndVersion)>1)
        error(message('matlab_addons:enableDisableManagement:multipleVersionsInstalledSpecifyIdentifierAndVersion'));
    end
    if ~isempty(identifierFromNameAndVersion)
        identifier = identifierFromNameAndVersion;
    end
end
end