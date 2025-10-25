function addUpdateMsg = getAddUpdateMessage(baseCode, latestVersion, name, updateType)
    % An internal function that returns updateMetadata struct given the following information  
    % baseCode of Support Package
    % latestVersion of the Support Package available
    % name of the Support Package
    % updateType ('hardware' or 'feature')
    % The returned addUpdateMsg contains the following fields.
    % struct(type: addUpdate, body: struct(identifier, version, name, addOnType, previewImages, updateType))
    
    % Copyright 2022-2023 The MathWorks, Inc.
    
    ADD_ON_TYPE_SUPPORT_PACKAGE = "support_package";

    updateMetadata = struct('identifier', baseCode, 'version', latestVersion, 'name', name, 'addOnType', ADD_ON_TYPE_SUPPORT_PACKAGE, 'previewImages', getImageForAddOn(baseCode), 'updateType', updateType);
    addUpdateMsg = struct('type', 'addUpdate', 'body', updateMetadata);

    function image = getImageForAddOn(identifier)
        % Use Extension framework to fetch list of installed Add-Ons with
        % metadata
        addonSpecification = matlab.internal.regfwk.ResourceSpecification;
        addonSpecification.ResourceName = 'addons_core';
        addonSpecification.ResourceType = matlab.internal.regfwk.ResourceType.XML;

        installedAddons = matlab.internal.regfwk.getResourceList(addonSpecification, 'all');

        for i = 1:size(installedAddons,1)
            addOnCoreMetadata = installedAddons(i).resourcesFileContents.addOnsCore;

            if strcmpi(addOnCoreMetadata.identifier,identifier)
                image = addOnCoreMetadata.previewImages;
                return;
            end
        end
        
    end
end
