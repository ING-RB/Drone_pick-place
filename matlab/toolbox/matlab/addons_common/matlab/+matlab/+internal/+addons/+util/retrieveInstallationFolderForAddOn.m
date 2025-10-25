function addOnsInstallationFolder = retrieveInstallationFolderForAddOn(addOnIdentifier, addOnVersion)
%
% Function to retrieve the location where an add-on with given ADDONIDENTIFIER and ADDONVERSION is installed

% Copyright 2020-2022 The MathWorks, Inc.

  narginchk(2,2);

  addOnIdentifier = convertStringsToChars(addOnIdentifier);
  addOnVersion = convertStringsToChars(addOnVersion);

  if (nargin ~= 2)
    validateArgs("matlab.internal.addons.util.retrieveInstallationFolderForAddOn", addOnIdentifier, addOnVersion);
  end

  installedAddOns = matlab.internal.addons.registry.getInstalledAddOnsMetadata;
  for addOnIndex = 1:length(installedAddOns)
    if (strcmp(installedAddOns(addOnIndex).identifier, addOnIdentifier)) && (strcmp(installedAddOns(addOnIndex).version, addOnVersion))
        installedAddOn = installedAddOns(addOnIndex);
        addOnsInstallationFolder = string(installedAddOn.installationRoot);
        break;
    end
  end
  if ~exist('installedAddOn','var')
    error(message('matlab_addons:enableDisableManagement:invalidIdentifierAndVersion'));
  end

end
