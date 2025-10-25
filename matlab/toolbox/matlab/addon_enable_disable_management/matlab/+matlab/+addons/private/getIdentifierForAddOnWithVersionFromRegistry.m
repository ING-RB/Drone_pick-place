function [identifier] = getIdentifierForAddOnWithVersionFromRegistry(addOnNameOrIdentifier, addOnVersion)
%
% This is a private function and is not meant to be called directly.
% Copyright 2021 The MathWorks, Inc.

% This returns identifier value corresponding to an add-on name,
% Throws error if more than one version of add-on is installed with
% specified name.
allInstalledAddOns = matlab.addons.installedAddons;
identifier = addOnNameOrIdentifier;
identifierFromNameAndVersion = allInstalledAddOns.Identifier(lower(allInstalledAddOns.Name) == lower(string(addOnNameOrIdentifier)) & allInstalledAddOns.Version == string(addOnVersion),:);
if (length(identifierFromNameAndVersion) > 1)
    error(message('matlab_addons:enableDisableManagement:multipleVersionsInstalledSpecifyIdentifierAndVersion'));
end
if ~isempty(identifierFromNameAndVersion)
    identifier = identifierFromNameAndVersion;
end
end