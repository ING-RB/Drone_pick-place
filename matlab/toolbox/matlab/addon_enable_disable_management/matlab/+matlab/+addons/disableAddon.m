function disableAddon (NameOrIdentifier, Version)

% disableAddon Disable an add-on
%
%   matlab.addons.disableAddon(NAME) disables
%   the add-on with the specified add-on NAME.
%
%   matlab.addons.disableAddon(NAME, VERSION) disables
%   the add-on with the specified NAME and VERSION.
%
%   matlab.addons.disableAddon(IDENTIFIER) disables
%   the add-on with the specified IDENTIFIER.
%
%   IDENTIFIER is the unique identifier of the add-on to be disabled,
%   specified as a string or character vector. To determine the
%   unique identifier of an add-on, use the
%   matlab.addons.installedAddons function.
%
%   matlab.addons.disableAddon(IDENTIFIER, VERSION) disables
%   the add-on with the specified IDENTIFIER and VERSION.
%
%   Example: Get list of installed add-ons and disable the
%   first add-on in list
%
%   addons = matlab.addons.installedAddons;
%
%   matlab.addons.disableAddon(addons.Identifier(1))
%
%   See also: matlab.addons.enableAddon,
%   matlab.addons.installedAddons,
%   matlab.addons.isAddonEnabled

% Copyright 2017-2021 The MathWorks, Inc.

    narginchk(1,2);
    if nargin < 2
        validateArgs("matlab.addons.disableAddon", NameOrIdentifier);
    else
        validateArgs("matlab.addons.disableAddon", NameOrIdentifier, Version);
    end

    NameOrIdentifier = convertStringsToChars(NameOrIdentifier);

    if usejava('jvm')
        if (nargin < 2)
            disableAddonWithNameOrIdentifierAndVersion(NameOrIdentifier);
        else
            disableAddonWithNameOrIdentifierAndVersion(NameOrIdentifier, Version);
        end
        return;
    end

    try
        installedAddOns = matlab.internal.addons.registry.getInstalledAddOnsMetadata;

        % Begin: Return if there is not enabled add-on version
        if (nargin > 1)
            Version = convertStringsToChars(Version);
            % If the First argument is add-on name, then get Identifier
            % corresponding to add-on name and version
            addOnIdentifier = getIdentifierForAddOnWithVersionFromRegistry(NameOrIdentifier, Version);
            
            for addOnIndex = 1:length(installedAddOns)
                if (strcmp(installedAddOns(addOnIndex).identifier, addOnIdentifier)) && (strcmp(installedAddOns(addOnIndex).version, Version))
                    installedAddOn = installedAddOns(addOnIndex);
                    break;
                end
            end
            if ~exist('installedAddOn','var')
                error(message('matlab_addons:enableDisableManagement:invalidIdentifierAndVersion'));
            end
        else
            % If the First argument is add-on name, then get Identifier
            % corresponding to add-on name to disable
            addOnIdentifier = getIdentifierForAddOnToDisable(NameOrIdentifier);
            % If no add-on with add-on name is enabled.
            if isempty(addOnIdentifier)
                return;
            end
            for addOnIndex = 1:length(installedAddOns)
                if strcmp(installedAddOns(addOnIndex).identifier, addOnIdentifier) & installedAddOns(addOnIndex).enabled == 1
                    installedAddOn = installedAddOns(addOnIndex);
                    break;
                end
            end
            if ~exist('installedAddOn','var')
                error(message('matlab_addons:enableDisableManagement:invalidIdentifier'));
            end
        end

        % Disable enabled version
        if ~installedAddOn.isEnableDisableSupported
            error(message('matlab_addons:enableDisableManagement:notSupported'));
        end

        if ~matlab.internal.addons.registry.isAddOnEnabled(string(installedAddOn.identifier), string(installedAddOn.version))
            return;
        end

        matlab.internal.addons.registry.disableAddOn(string(installedAddOn.identifier), string(installedAddOn.version));
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
