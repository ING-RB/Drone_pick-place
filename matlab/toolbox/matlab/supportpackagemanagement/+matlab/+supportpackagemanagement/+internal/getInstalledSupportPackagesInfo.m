function installedSupportPackages = getInstalledSupportPackagesInfo()
% matlab.supportpackagemanagement.internal.getInstalledSupportPackagesInfo
% - An internal function that returns the metadata for installed support
% packages.
%
% This function is called by Add-Ons in product layer to respond to the
% 'getInstalledAddOns' request from the Add-Ons gallery

% Copyright 2015-2022 The MathWorks, Inc.

% Call internal utility function to get installed support package data
packages = matlab.supportpackagemanagement.internal.util.getInstalledSpPkgProducts();

if isempty(packages)
    installedSupportPackages = repmat( ...
        javaArray('com.mathworks.hwsmanagement.InstalledSupportPackage', 1), ... % javaArray cannot utilize Java imports
        0, 0);
    return
end

numPackages = length(packages);
installedSupportPackages = ...
    javaArray('com.mathworks.hwsmanagement.InstalledSupportPackage', ... % javaArray cannot utilize Java imports
    numPackages);

import com.mathworks.hwsmanagement.InstalledSupportPackage
for i = 1:numPackages
    % Determine whether the support package should be labeled "Hardware
    % Support Package" or "Optional Feature"
    jResource = 'com.mathworks.hwsmanagement.resources.RES_AddOns_SupportPackage';
    locale = java.util.Locale.getDefault;
    classLoader = java.lang.ClassLoader.getSystemClassLoader;
    %g2829911
    resourceBundle = javaMethodEDT('getBundle','java.util.ResourceBundle',jResource,locale,classLoader);
    if (strcmp(packages(i).SupportCategory, 'hardware') == 1)
        displayType = resourceBundle.getString('displayType.HardwareSupportPackage');
    else
        displayType = resourceBundle.getString('displayType.Feature');
    end
    % The isHwSetupAvailable will indicate whether this support package
    % should have the "Setup" button to launch hardware setup
    isHwSetupAvailalable = ~isempty(matlabshared.supportpkg.internal.ssi.getBaseCodesHavingHwSetup({packages(i).BaseCode}));
    % Construct the installed support package bean object via the Builder
    builder = InstalledSupportPackage.getBuilder();
    builder = builder.baseCode(packages(i).BaseCode);
    builder = builder.version(packages(i).Version);
    builder = builder.fullName(packages(i).FullName);
    builder = builder.installedDate(java.util.Date(double(packages(i).InstalledDate)));
    builder = builder.isVisible(packages(i).Visible);
    builder = builder.displayType(displayType);
    builder = builder.hasHwSetup(isHwSetupAvailalable);
    installedSupportPackages(i) = builder.createInstalledSupportPackage();
    
end

end

