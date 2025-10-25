function addOnsInstallationFolder = retrieveAddOnsInstallationFolder
%
% Function to retrieve add-ons installation folder

% Copyright 2015 - 2022 The MathWorks, Inc.
    if feature('webui')
        addOnsInstallationFolder = string(matlab.internal.addons.registry.installLocation.getFolderToInstall);
    else
        addOnsInstallationFolder = string(com.mathworks.addons_common.util.settings.InstallationFolderUtils.getInstallationFolder.toString);
    end
end
