function hasAddOn = hasAddOnWithIdentifierAndVersion(identifierOfAddOn,versionOfAddOn)
    %   HASADDONWITHIDENTIFIERANDVERSION(IDENTIFIER, VERSION): Returns a boolean
    %   indicating if an add-on with given identifier and version is registed with
    %   Add-Ons Registry
    
    %   Copyright 2021 The MathWorks, Inc.
    installedAddOnsTable = matlab.addons.installedAddons;
    if height(installedAddOnsTable) == 0
        hasAddOn = false;
    else
        rows = (installedAddOnsTable.Identifier == string(identifierOfAddOn)) & (installedAddOnsTable.Version == string(versionOfAddOn));
        hasAddOn = ismember(true, rows);
    end
end

