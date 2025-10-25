function addonDataArray = getAddonInstallations()
%GETADDONINSTALLATIONS Returns basic information about installed AddOns.
%   GETADDONINSTALLATIONS returns an array of ADDONDATA structs.  Each
%   ADDONDATA struct has the following fields:
%
%   ADDONDATA.Name = Display name string of the AddOn.
%   ADDONDATA.Identifier = Unique identifier string for the AddOn.
%   ADDONDATA.Version = Version string for the AddOn.
%   ADDONDATA.Type = Type string of AddOn, one of "Toolbox", "App" or "Zip".
%   ADDONDATA.InstallationFolder = Install location string of the AddOn.
%   ADDONDATA.Enabled = (true|false) Current enabled state of the AddOn.

%   Copyright 2020-2025 MathWorks, Inc.

    installedAddOns = matlab.internal.addons.registry.getInstalledAddOnsMetadata;

    if isempty(installedAddOns)
        addonDataArray = createEmptyStructArray();
        
    else
        addonDataArray = createEmptyStructArray();
        for z=length(installedAddOns): -1: 1
            nextAddOn = installedAddOns(z);

            addonDataArray(z).Name = string(nextAddOn.name);
            addonDataArray(z).Identifier = string(nextAddOn.identifier);
            addonDataArray(z).Version = string(nextAddOn.version);
            addonDataArray(z).Type = string(nextAddOn.addOnType);
            addonDataArray(z).InstallationFolder = ...
                string(nextAddOn.installationRoot);
            addonDataArray(z).Enabled = ...
                nextAddOn.enabled;
        end
        
        % This function must return only community AddOn types.
        addonTypes = lower([addonDataArray.Type]);
        communityAddonTypes = ["app", "toolbox", "zip"];
        addonDataArray = addonDataArray(ismember(addonTypes,communityAddonTypes));
    end
end

function emptyArray = createEmptyStructArray()
    emptyArray = struct('Name', {}, ...
                        'Identifier', {}, ...
                        'Version', {}, ...
                        'Type', {}, ...
                        'InstallationFolder', {}, ...
                        'Enabled', false );
end