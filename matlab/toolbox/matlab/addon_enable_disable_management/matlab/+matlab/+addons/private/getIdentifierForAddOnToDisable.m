function [identifier] = getIdentifierForAddOnToDisable(addOnNameOrIdentifier)
%
% This is a private function and is not meant to be called directly.
% Copyright 2019 The MathWorks, Inc.

% This returns identifier value corresponding to an add-on name,
% Throws error if more than one version of add-on is installed with
% specified name.

allInstalledAddOns = matlab.addons.installedAddons;
identifier = addOnNameOrIdentifier;
% Get all the enabled add-on with add-on name
enabledIdentifierFromName = allInstalledAddOns.Identifier(lower(allInstalledAddOns.Name) == lower(string(addOnNameOrIdentifier)) & allInstalledAddOns.Enabled == 1,:);
% Get all the installed add-on with add-on name
identifierFromName = allInstalledAddOns.Identifier(lower(allInstalledAddOns.Name) == lower(string(addOnNameOrIdentifier)),:);

if (length(enabledIdentifierFromName)>1)
    error(message('matlab_addons:enableDisableManagement:multipleVersionsInstalledSpecifyIdentifier'));
end
if ~isempty(enabledIdentifierFromName)
    identifier = enabledIdentifierFromName;
elseif ~isempty(identifierFromName) % No addon is enabled, But add-ons exist with specified add-on name
    identifier = [];
end
end