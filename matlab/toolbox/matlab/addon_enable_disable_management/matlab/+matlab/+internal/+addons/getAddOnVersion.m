function [versions] = getAddOnVersion(addOnName)
% Tab Completion function to get version information for add-on
% Get all the versions installed for add-on with specified name

% Copyright 2019 The MathWorks Inc.
allInstalledAddOns = matlab.addons.installedAddons;
versions = allInstalledAddOns.Version(lower(allInstalledAddOns.Name) == lower(string(addOnName)),:);
end