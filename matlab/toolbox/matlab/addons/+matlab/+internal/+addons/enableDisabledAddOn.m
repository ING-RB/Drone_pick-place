function enableDisabledAddOn(addonUIDandVersion, addonNameAndVersion)
    % ENABLEDISABLEDADDON Enables a previously disabled add-on.
    % This function allows users to enable functions from a disabled add-on.
    % It is intended to be triggered as part of disabled function tripwire workflows.
    %
    % Expected behavior:
    % - If MATLAB is launched in no desktop mode: The add-on is enabled directly when the tripwire is clicked.
    % - If MATLAB is launched with the desktop: Clicking the tripwire brings up a confirmation dialog to enable the add-on.
    %
    % Inputs:
    % - addonUIDandVersion: A string containing the add-on's unique identifier and version, separated by a comma.
    % - addonNameAndVersion: A string containing the add-on's name and version, separated by string 'version'.
    %
    %% Expects inputs in the following formats
    %  addonUIDandVersion: '<uid>,<version>'
    %  addonNameAndVersion: '<name> version <version>'
    % Example:
    % enableDisabledAddOn('12345,1.0', 'Sample Add-On version 1.0')

    % Copyright 2024 The MathWorks, Inc.
    
    % Derive Add-On identifier, version and name
    connectingWordForNameAndVersion = [' ' getString(message('matlab_addons:enableDisableManagement:connectionForDisabledAddonRegistrationLinkText')) ' '];
    uidAndVersionList = split(addonUIDandVersion, ',');
    nameAndVersionList = split(addonNameAndVersion, connectingWordForNameAndVersion);
    addOnIdentifier =  uidAndVersionList{1};
    addOnVersion = uidAndVersionList{2};
    addOnName = nameAndVersionList{1};

    % Enable the add-on 
    if ~usejava('desktop')
        matlab.internal.addons.enableAddon(addOnIdentifier, addOnVersion, addOnName);
    end

    if feature('webui')
        % Bring up a confirmation dialog which lets user enable the add-on
        % Publish a message to UI to show confirmation dialog
        enableConfirmationDialogMsg = struct('identifier', addOnIdentifier, 'version', addOnVersion, 'name', addOnName);
        messageToClient = struct('type', 'showEnableConfirmationDialog', 'body', enableConfirmationDialogMsg);
        message.publish("/matlab/addons/serverToClient", messageToClient);
    else 
        matlab.internal.addons.openManagerForAddon(addonUIDandVersion, addonNameAndVersion);
    end
end