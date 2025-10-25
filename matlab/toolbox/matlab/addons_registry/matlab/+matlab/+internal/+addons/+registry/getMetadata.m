function metadata = getMetadata(Identifier,AddOnVersion)
% getMetadata Returns a struct with metadata for an add-on
%
%   matlab.internal.addons.registry.getMetadata(IDENTIFIER,
%   VERSION) Returns a struct with metadata of an add-on with the specified IDENTIFIER, VERSION.
%
%
%   IDENTIFIER is the unique identifier of the add-on,
%   specified as a string
%
%   AddOnVersion: Version of the add-on provided as a string
%   Example: Get metadata for an add-on
%   matlab.internal.addons.registry.getMetadata("b443a7d0-3a0b-4f52-ad0c-8facef8a00f7","1.0")
%
%   See also: matlab.internal.addons.registry.addAddOn,
%   matlab.internal.addons.registry.enableAddOn,
%   matlab.internal.addons.registry.disableAddOn
%   matlab.internal.addons.registry.isAddOnEnabled

% Copyright 2021-2022 The MathWorks, Inc.
installedAddOns = matlab.internal.addons.registry.getInstalledAddOnsMetadata;
for addOnIndex = 1:length(installedAddOns)
    if (strcmp(installedAddOns(addOnIndex).identifier, Identifier)) && (strcmp(installedAddOns(addOnIndex).version, AddOnVersion))
        metadata = installedAddOns(addOnIndex);
        return;
    end
end

% Add-on with given id and version was not found. Throw an error.
error(message('matlab_addons:enableDisableManagement:invalidIdentifierAndVersion'));



