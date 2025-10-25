function removeFromJavaInfrastructure(addOnIdentifier, addOnVersion)
% removeFromJavaInfrastructure(addOnIdentifier, addOnVersion): Private
% function to remove an add-on from Java Add-Ons infrastructure

% Copyright 2021 The MathWorks, Inc.

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

