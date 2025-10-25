function isEnabled = isAddonEnabled(NameOrIdentifier, Version)

% isAddonEnabled Return the enabled state of an add-on
%
%   ISENABLED = matlab.addons.isAddonEnabled(NAME) returns true 
%   if the add-on with specified NAME is enabled and false otherwise.
%
%   ISENABLED = matlab.addons.isAddonEnabled(NAME, VERSION) returns true 
%   if the add-on with specified NAME and VERSION is enabled and false otherwise.
%
%   ISENABLED = matlab.addons.isAddonEnabled(IDENTIFIER) returns true 
%   if the specified add-on is enabled and false otherwise.
%
%   IDENTIFIER is the unique identifier of the add-on to be enabled, 
%   specified as a string or character vector. To determine the 
%   unique identifier of an add-on, use the 
%   matlab.addons.installedAddons function.
%
%   ISENABLED is a logical value indicating the 
%   enabled state of the add-on.
%
%   ISENABLED = matlab.addons.isAddonEnabled(IDENTIFIER, VERSION) returns true 
%   if the add-on with specified IDENTIFIER and VERSION is enabled and false otherwise.
%
%   Example: Get list of installed add-ons and get the state 
%   for the first add-on
%
%   addons = matlab.addons.installedAddons;
%
%   isEnabled = matlab.addons.isAddonEnabled(addons.Identifier(1))
%
%   isEnabled =
%
%       logical
%
%       0
%
%   See also: matlab.addons.disableAddon,
%   matlab.addons.enableAddon,
%   matlab.addons.installedAddons

% Copyright 2017-2021 The MathWorks Inc.


narginchk(1,2);
if nargin < 2
    validateArgs("matlab.addons.isAddonEnabled", NameOrIdentifier);
else
    validateArgs("matlab.addons.isAddonEnabled", NameOrIdentifier, Version);
end

try
    
    installedAddons = matlab.addons.installedAddons;
    installedAddons = table2struct(installedAddons);
    
    if (nargin < 2)
        % If the First argument is add-on name, then get Identifier 
        % corresponding to add-on name
        for addonIndex = 1:length(installedAddons)
            if (strcmpi(installedAddons(addonIndex).Identifier, NameOrIdentifier)) | (strcmpi(installedAddons(addonIndex).Name, NameOrIdentifier))
                % An add-on with the identifier is found
                installedAddon = installedAddons(addonIndex);
                % if current version is enabled, return true. Otherwise keep finding if there is an enabled version.
                if installedAddon.Enabled
                    isEnabled = true;
                    return;
                end
            end
        end
        if ~exist('installedAddon','var')
            error(message('matlab_addons:enableDisableManagement:invalidIdentifier'));
        end
    else
        Version = convertStringsToChars(Version);
        % If the First argument is add-on name, then get Identifier
        % corresponding to add-on name and version
        addonIdentifier = getIdentifierForAddOnWithVersionFromRegistry(NameOrIdentifier, Version);
        for addonIndex = 1:length(installedAddons)
            if (strcmp(installedAddons(addonIndex).Identifier, addonIdentifier) & strcmp(installedAddons(addonIndex).Version, Version))
                installedAddon = installedAddons(addonIndex);
                break;
            end
        end
        if ~exist('installedAddon','var')
            error(message('matlab_addons:enableDisableManagement:invalidIdentifierAndVersion'));
        end
    end
    
    isEnabled = installedAddon.Enabled;
    
catch ex
    if isprop(ex, 'ExceptionObject') && ...
            ~isempty(strfind(ex.ExceptionObject.getClass, 'IdentifierNotFoundException'))
        error(message('matlab_addons:enableDisableManagement:invalidIdentifier'));
    elseif isprop(ex, 'ExceptionObject') && ...
            ~isempty(strfind(ex.ExceptionObject.getClass, 'AddOnNotFoundException'))
        error(message('matlab_addons:enableDisableManagement:invalidIdentifierAndVersion'));
    else
        error(ex.identifier, ex.message);
    end
end

end