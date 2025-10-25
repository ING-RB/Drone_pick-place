function multipleVersionsInstalled = hasMultipleVersionsInstalled(identifier)

% Copyright 2018 The MathWorks, Inc.

multipleVersionsInstalled = false;
addons = matlab.addons.installedAddons;

if ~isempty(addons)
    otherAddonVersions = (string(addons.Identifier) == string(identifier));
    if sum(otherAddonVersions(:)) > 1
        multipleVersionsInstalled = true;
    end
end
end