function [identifier] = getIdentifierForUninstall(addOnNameOrIdentifier)
%
% This is a private function and is not meant to be called directly.
% Copyright 2021 The MathWorks, Inc.

% This returns identifier for the Add-On to be uninstalled identified by its name,
% Throws error if more than one add-on is installed with
% specified name.

allInstalledAddOns = matlab.addons.installedAddons;
identifier = addOnNameOrIdentifier;
identifierFromName = allInstalledAddOns.Identifier(lower(allInstalledAddOns.Name) == lower(string(addOnNameOrIdentifier)),:);

if (length(identifierFromName)>1)
    % If all the identifiers associated with the name are the same, then
    % return the identifier associated
    if all(identifierFromName == identifierFromName(1))
        identifier = identifierFromName(1);
        return;
    end
    
    error(message('matlab_addons:enableDisableManagement:multipleVersionsInstalledSpecifyIdentifier'));
end
if ~isempty(identifierFromName)
    identifier = identifierFromName;
end
end