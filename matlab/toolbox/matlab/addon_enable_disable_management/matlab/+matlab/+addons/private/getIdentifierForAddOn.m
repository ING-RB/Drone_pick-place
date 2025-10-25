function [identifier] = getIdentifierForAddOn(addOnNameOrIdentifier)
%
% This is a private function and is not meant to be called directly.
% Copyright 2019 The MathWorks, Inc.

% This returns identifier value corresponding to an add-on name,
% Throws error if more than one version of add-on is installed with
% specified name.

allInstalledAddOns = matlab.addons.installedAddons;
identifier = addOnNameOrIdentifier;
identifierFromName = allInstalledAddOns.Identifier(lower(allInstalledAddOns.Name) == lower(string(addOnNameOrIdentifier)),:);

if (length(identifierFromName)>1)
    error(message('matlab_addons:enableDisableManagement:multipleVersionsInstalledSpecifyIdentifier'));
end
if ~isempty(identifierFromName)
    identifier = identifierFromName;
end
end