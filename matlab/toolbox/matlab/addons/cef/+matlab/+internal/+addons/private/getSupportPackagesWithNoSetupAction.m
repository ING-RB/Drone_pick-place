function supportPackages = getSupportPackagesWithNoSetupAction()
    %   GETSUPPORTPACKAGESWITHNOSETUPACTION Returns a struct array with
    %   (identifier, version) of Support Packages with no setup action
    
    % Copyright: 2022-2024 The MathWorks, Inc.

    % Fetch All Add-On Metadata
    addonSpecification = matlab.internal.regfwk.ResourceSpecification;
    addonSpecification.ResourceName = 'addons_core';
    addonSpecification.ResourceType = matlab.internal.regfwk.ResourceType.XML;

    addOnResources = matlab.internal.regfwk.getResourceList(addonSpecification);

    % Get support packages that does not have setup
    % Initialize supportPackages struct given that we only need identifier
    % and version
    supportPackages = struct('identifier', {}, 'version', {});

    for i = 1:numel(addOnResources)
        metadata = addOnResources(i).resourcesFileContents;
        if isfield(metadata.addOnsCore, 'addOnType') && strcmpi(metadata.addOnsCore.addOnType, 'support_package')
            if isfield(metadata, 'actions') && ~isempty(metadata.actions)
                actionIds = {metadata.actions.id};
                if ~ismember('setup', actionIds)
                    spkg = struct('identifier', metadata.addOnsCore.identifier, 'version', metadata.addOnsCore.version);
                    supportPackages = [supportPackages, spkg];
                end
            else
                spkg = struct('identifier', metadata.addOnsCore.identifier, 'version', metadata.addOnsCore.version);
                supportPackages = [supportPackages, spkg];
            end
        end
    end
    end
