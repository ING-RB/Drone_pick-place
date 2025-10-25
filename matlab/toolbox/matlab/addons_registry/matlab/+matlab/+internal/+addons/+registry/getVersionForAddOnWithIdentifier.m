function addOnVersion = getVersionForAddOnWithIdentifier(addOnIdentifier)
%   GETVERSIONFORADDONWITHIDENTIFIER(IDENTIFIER Get version of the Add-On
%   with given identifier.  If there are multiple versions installed, the
%   api returns version of enabled add-on. In case when there are no
%   enabled versions, version of most recently installed add-on is returned
%   Make sure an Add-On with identifier
%   exists in registry before invoking the API

% Copyright 2021-2023 The MathWorks, Inc.

allInstalledAddOns = matlab.addons.installedAddons;
versionOfAddOn = allInstalledAddOns.Version(lower(allInstalledAddOns.Identifier) == lower(string(addOnIdentifier)),:);

% If there are multiple versions installed, return the version of
% enabled/most recently installed version
if (length(versionOfAddOn) > 1)
    registrationRoot = matlab.internal.addons.registry.getRegistrationRootForEnabledOrMostRecentlyInstalledVersion(addOnIdentifier);
    addOnVersion = getAddOnVersion(registrationRoot);
else
    addOnVersion = versionOfAddOn;
end

end

function versionOfAddOn = getAddOnVersion(registrationRoot)
    
    addOnMetadatas = matlab.internal.addons.registry.getInstalledAddOnsMetadata;
    
    for i = 1:size(addOnMetadatas,1)
       if strcmpi(registrationRoot, addOnMetadatas(i).registrationRoot) 
        addOnMetadata = addOnMetadatas(i);
       end
    end

    if ~exist('addOnMetadata','var')
        error(message('matlab_addons:enableDisableManagement:invalidIdentifier'));
    end

    versionOfAddOn = addOnMetadata.version;

end

