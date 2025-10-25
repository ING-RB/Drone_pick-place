function downloadAndInstall(installMetadata) 
    % installAddOnFromSidePanel: Install add-ons from Side Panel
    % INSTALLMETADATA: A struct with the following fields
        
    % Copyright: 2023 The MathWorks, Inc.

   if (strcmpi(installMetadata.addOnType, 'product') == 1)
        ENTRY_POINT_IDENTIFIER = "AO_SIDEPANEL";
        
        if isfield(installMetadata, 'version') && ~isempty(installMetadata.version)
            matlab.internal.addons.launchers.showExplorer(ENTRY_POINT_IDENTIFIER, "identifier", installMetadata.identifier, "version", installMetadata.version);
        else
            matlab.internal.addons.launchers.showExplorer(ENTRY_POINT_IDENTIFIER, "identifier", installMetadata.identifier);
        end
    end
    % ToDo: Add code to install mock add-ons used for testing
    end