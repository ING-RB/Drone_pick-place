function hasInstalledVersion = hasAnyVersionInstalled(identifier)

% Copyright 2018 The MathWorks, Inc.

hasInstalledVersion = false;
addons = matlab.addons.installedAddons;
if ~isempty(addons)
    otherAddonVersions = (string(addons.Identifier) == string(identifier));
    if sum(otherAddonVersions(:)) > 0
        hasInstalledVersion = true;
    end
end
end