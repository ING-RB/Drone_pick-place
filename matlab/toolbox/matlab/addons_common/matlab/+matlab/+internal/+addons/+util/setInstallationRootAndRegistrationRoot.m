function addOnsInstallationFolder = setInstallationRootAndRegistrationRoot(locationToInstall, locationToRegister)
% setInstallationRootAndRegistrationRoot: Function to set Location to Install and Location to Register Add-Ons

% Copyright 2021 The MathWorks, Inc.

  narginchk(2,2);

  locationToInstall = convertStringsToChars(locationToInstall);
  locationToRegister = convertStringsToChars(locationToRegister);

  if usejava('jvm')
    com.mathworks.addons_common.util.settings.InstallationFolderUtils.initializeWritableAndReadOnlyInstallLocation(java.lang.String(locationToInstall), java.lang.String(locationToRegister));
  end
  matlab.internal.addons.registry.installLocation.setFolderToInstallAndRegister(locationToInstall, locationToRegister);

end
