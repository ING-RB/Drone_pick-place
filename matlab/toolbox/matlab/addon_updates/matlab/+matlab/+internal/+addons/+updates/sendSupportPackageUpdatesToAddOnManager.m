function sendSupportPackageUpdatesToAddOnManager()
    % sendSupportPackageUpdatesToAddOnManager: An internal function that sends the list of support package updates to Add-On Manager
    
    % Copyright 2022 The MathWorks, Inc.

    UPDATE_TYPE_HARDWARE_SUPPORT = 'hardware_support';
    UPDATE_TYPE_FEATURE = 'feature';
        
    numUpdates = 0;
    try 
        % Fetch Hardware Support Package Updates
        hardwareSupportPackageUpdates = matlabshared.supportpkg.internal.toolstrip.util.getSpPkgUpdateData('hardware');

        % Fetch Feature Updates
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
        return;
    end
    
    % Send each update to Add-On Manager one at a time
    if ~isempty(hardwareSupportPackageUpdates)
        for i = 1:length(hardwareSupportPackageUpdates)
            addUpdateMsg = getAddUpdateMessage(hardwareSupportPackageUpdates(i).BaseCode, hardwareSupportPackageUpdates(i).LatestVersion, hardwareSupportPackageUpdates(i).Name, UPDATE_TYPE_HARDWARE_SUPPORT);
            matlab.internal.addons.updates.publishUpdateToAddOnManager(addUpdateMsg);
        end
    end
    
    if ~isempty(featureUpdates)
        for j = 1:length(featureUpdates)
            addUpdateMsg = getAddUpdateMessage(featureUpdates(j).BaseCode, featureUpdates(j).LatestVersion, featureUpdates(j).Name, UPDATE_TYPE_FEATURE);
            matlab.internal.addons.updates.publishUpdateToAddOnManager(addUpdateMsg);
        end
    end
    end
    
    