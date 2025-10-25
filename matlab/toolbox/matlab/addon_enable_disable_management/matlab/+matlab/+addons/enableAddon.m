function enableAddon (NameOrIdentifier, Version)

    % enableAddon Enable an add-on
    %
    %   matlab.addons.enableAddon(NAME) enables
    %   the add-on with the specified add-on NAME.
    %
    %   matlab.addons.enableAddon(NAME, VERSION) enables
    %   the add-on with the specified NAME and VERSION.
    %
    %   matlab.addons.enableAddon(IDENTIFIER) enables
    %   the add-on with the specified IDENTIFIER.
    %
    %   IDENTIFIER is the unique identifier of the add-on to be enabled,
    %   specified as a string or character vector. To determine the
    %   unique identifier of an add-on, use the
    %   matlab.addons.installedAddons function.
    %
    %   matlab.addons.enableAddon(IDENTIFIER, VERSION) enables
    %   the add-on with the specified IDENTIFIER and VERSION.
    %
    %   Example: Get list of installed add-ons and enable the
    %   first add-on in list
    %
    %   addons = matlab.addons.installedAddons;
    %
    %   matlab.addons.enableAddon(addons.Identifier(1))
    %
    %   See also: matlab.addons.disableAddon,
    %   matlab.addons.installedAddons,
    %   matlab.addons.isAddonEnabled
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
        narginchk(1,2);
        if nargin < 2
            validateArgs("matlab.addons.enableAddon", NameOrIdentifier);
        else
            validateArgs("matlab.addons.enableAddon", NameOrIdentifier, Version);
        end

        if usejava('jvm')
            if (nargin < 2)
                enableAddonWithNameOrIdentifierAndVersion(NameOrIdentifier);
            else
                enableAddonWithNameOrIdentifierAndVersion(NameOrIdentifier, Version);
            end
            return;
        end

        NameOrIdentifier = convertStringsToChars(NameOrIdentifier);
    
        try
            installedAddOns = matlab.internal.addons.registry.getInstalledAddOnsMetadata;
            if (nargin < 2)
                % If the First argument is add-on name, then get Identifier
                % corresponding to add-on name
                addOnIdentifier = getIdentifierForAddOn(NameOrIdentifier);
                if hasMultipleVersionsInstalled(addOnIdentifier)
                    error(message('matlab_addons:enableDisableManagement:multipleVersionsInstalledSpecifyVersionToEnable'));
                end
                for addOnIndex = 1:length(installedAddOns)
                    if strcmp(installedAddOns(addOnIndex).identifier, addOnIdentifier) 
                        installedAddOn = installedAddOns(addOnIndex);
                        break;
                    end
                end
                if ~exist('installedAddOn','var')
                    error(message('matlab_addons:enableDisableManagement:invalidIdentifier'));
                end
            else
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
            end

            matlab.internal.addons.registry.enableAddOn(string(installedAddOn.identifier), string(installedAddOn.version));
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
    