function addons = getInstalledAddOns()
% getInstalledAddOns -  Returns a table with the list of installed
% Add-Ons

% Copyright 2021 The MathWorks Inc.
import com.mathworks.addons_common.notificationframework.InstalledAddOnsCache;

addons = table(string.empty(0,1),string.empty(0,1),logical.empty(0,1),string.empty(0,1),...
        'VariableNames',{'Name','Version','Enabled','Identifier'}); 

addonsStruct = struct([]);

try
    
    installedAddonsCache = InstalledAddOnsCache.getInstance;
    installedAddonsAsArray = installedAddonsCache.getInstalledAddonsAsArray();
    
    for addonIndex = 1:length(installedAddonsAsArray)
        installedAddon = installedAddonsAsArray(addonIndex);
        addonsStruct(addonIndex).Name = string(installedAddon.getName());
        addonsStruct(addonIndex).Version = string(installedAddon.getVersion());
        addonsStruct(addonIndex).Enabled = logical(installedAddon.isEnabled());
        addonsStruct(addonIndex).Identifier = string(installedAddon.getIdentifier());
    end
    
    if size(addonsStruct) > 0
        addons = struct2table(addonsStruct);
    end
    
catch ex
    error(ex.identifier, ex.message);
end
end

