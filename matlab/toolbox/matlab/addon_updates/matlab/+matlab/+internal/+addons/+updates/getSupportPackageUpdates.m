function supportPackageUpdates = getSupportPackageUpdates()
% An internal function that returns the metadata for available support
% package updates.

% Copyright 2018 The MathWorks, Inc.

import com.mathworks.addon_updates.SupportPackageUpdateMetadata;

numUpdates = 0;
try 
    hardwareSupportPackageUpdates = matlabshared.supportpkg.internal.toolstrip.util.getSpPkgUpdateData('hardware');
    featureUpdates = matlabshared.supportpkg.internal.toolstrip.util.getSpPkgUpdateData('software');
    numUpdates = length(hardwareSupportPackageUpdates) + length(featureUpdates);
catch ex
    if strcmp(ex.identifier,'supportpkgservices:matlabshared:ManifestDownload')
        % This exception occurs when there fetching information support package information from mathworks.com.
        % Return 0 updates in case of this exception
        numUpdates = 0;
    end
end

if numUpdates == 0
    supportPackageUpdates = repmat( ...
        javaArray('com.mathworks.addon_updates.SupportPackageUpdateMetadata', 1), ... % javaArray cannot utilize Java imports
        0, 0);
    return
end

supportPackageUpdates = ...
    javaArray('com.mathworks.addon_updates.SupportPackageUpdateMetadata', ... % javaArray cannot utilize Java imports
    numUpdates);

count = 1;
if ~isempty(hardwareSupportPackageUpdates)
    for i = 1:length(hardwareSupportPackageUpdates)
        supportPackageUpdates(count) = SupportPackageUpdateMetadata(hardwareSupportPackageUpdates(i).BaseCode, hardwareSupportPackageUpdates(i).InstalledVersion, hardwareSupportPackageUpdates(i).LatestVersion, ...
            hardwareSupportPackageUpdates(i).Name, com.mathworks.addons_common.UpdateType.HARDWARE_SUPPORT);
        count = count + 1;
    end
end

if ~isempty(featureUpdates)
    for j = 1:length(featureUpdates)
        supportPackageUpdates(count) = SupportPackageUpdateMetadata(featureUpdates(j).BaseCode, featureUpdates(j).InstalledVersion, featureUpdates(j).LatestVersion, ...
            featureUpdates(j).Name, com.mathworks.addons_common.UpdateType.FEATURE);
        count = count + 1;
    end
end
end

