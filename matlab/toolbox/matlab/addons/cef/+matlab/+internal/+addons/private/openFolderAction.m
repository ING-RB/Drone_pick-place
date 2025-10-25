function openFolderAction(addOnInfo)
    % OPENFOLDERACTION Change current directory to the install location for an
    %   Add-On
    %   
    %   OpenFolderAction(ADDONINFO) Changes current directory to the install
    %   location of Add-On specified by ADDONINFO struct, which must have a
    %   field 'identifier' and my have fields 'version' and 'installedFolder'
    %
    %   ADDONINFO.addOnIdentifier is required and specifies the Add-On.
    %   ADDONINFO.addOnVersion is optional and specifies the version of the Add-On.

    % Copyright 2021-2024 The MathWorks, Inc.

    % Validate input struct
    addOnIdentifier = convertStringsToChars(addOnInfo.identifier);

    if isfield(addOnInfo, 'version') && ~isfield(addOnInfo, 'installedFolder') 
        addOnVersion = convertStringsToChars(addOnInfo.version);
        addOnMetadata = matlab.internal.addons.registry.getMetadata(addOnIdentifier, addOnVersion);
        registrationRoot = addOnMetadata.registrationRoot;
    elseif isfield(addOnInfo, 'installedFolder')
        registrationRoot = addOnInfo.installedFolder;
    else
        registrationRoot = matlab.internal.addons.registry.getRegistrationRootForEnabledOrMostRecentlyInstalledVersion(addOnIdentifier);
    end

    cd(registrationRoot);
    % The following API is expected to focus cfb and also bring it to front (Ref:g2735937)
    filebrowser;
    end