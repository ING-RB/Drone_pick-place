function supportPackages = getSupportPackagesToAddDocumentation()
    %   GETSUPPORTPACKAGESTOADDDOCUMENTATION Returns an array Support Package baseCodes for which open documentation
    %   action needs to be added
    
    % Copyright: 2023-2024 The MathWorks, Inc.

    % Fetch All Add-On Metadata
    addonSpecification = matlab.internal.regfwk.ResourceSpecification;
    addonSpecification.ResourceName = 'addons_core';
    addonSpecification.ResourceType = matlab.internal.regfwk.ResourceType.XML;

    addOnResources = matlab.internal.regfwk.getResourceList(addonSpecification);

    % Get support packages that does not have open doc action but have examples
    supportPackages = {};
    for i = 1:numel(addOnResources)
        metadata = addOnResources(i).resourcesFileContents;
        if isfield(metadata, 'addOnsCore') && ...
           isfield(metadata.addOnsCore, 'addOnType') && ...
           strcmpi(metadata.addOnsCore.addOnType, 'support_package')
       
            if isfield(metadata, 'hasDocumentation') && ~metadata.hasDocumentation
                sproot = matlabshared.supportpkg.getSupportPackageRoot();
                currentBaseCode = metadata.addOnsCore.identifier;
                
                % Check if the support package has examples
                openExamplesFcn = matlabshared.supportpkg.internal.ssi.util.getExamplesFcnAndArgsForBaseCode(currentBaseCode, sproot);
                
                if ~isempty(openExamplesFcn)
                    % Add support package to the array since it has featured examples
                    supportPackages{end+1} = currentBaseCode;
                end
            end
        end
    end
    end
