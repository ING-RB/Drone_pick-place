function addOnManagementMetadata = getAddOnManagementMetadataForAddOn(identifier, addOnVersion)

    % Returns addOnManagement metadata for an Add-On with given Identifier and Version
    
    % Copyright 2022-2023 The MathWorks, Inc.
    
    addOnManagementMetadata = struct([]);   % Create an empty struct

    addOnSpecification = matlab.internal.regfwk.ResourceSpecification;
    addOnSpecification.ResourceName = 'addons_core';
    addOnSpecification.ResourceType = matlab.internal.regfwk.ResourceType.XML;
    
    addOnMetadatas = matlab.internal.regfwk.getResourceList(addOnSpecification, 'all');
    
    for i = 1:size(addOnMetadatas,1)
        addOnCoreMetadata = addOnMetadatas(i).resourcesFileContents.addOnsCore;
        if strcmpi(addOnCoreMetadata.identifier, identifier) && strcmpi(addOnCoreMetadata.version, addOnVersion)
            addOnManagementMetadata = addOnMetadatas(i).resourcesFileContents;
            return;
        end
    end
    end