function showInstallerInManager(entryPointIdentifier, installerUrl)
%   SHOWINSTALLERINMANAGER This is a temporary helper function to open add-on
%   installer in Add-on Manager
%   Today, toolbox installer URL is constructed using connector.getUrl() API
%   which contains localhost as the base URL. This does not work  with
%   worker infrastructure (MATLAB Online). We are working with MATLAB
%   Online team to figure out a better way of constructing this URL so that
%   it contains the correct host name and needs no correction. Until we have the correct API, this
%   function is responsible for converting the installer URL to replace
%   localhost with correct host name before invoking the launcher API.

%   Copyright 2019-2024 The MathWorks, Inc.

    installerUrl = string(installerUrl);
    entryPointIdentifier = string(entryPointIdentifier);
    if feature('webui') || matlab.internal.addons.Configuration.isClientRemote
        % Open installer in a dialog
        messageToClient = struct('type', 'resolveInstallerUrlAndOpenInstaller', 'body', installerUrl);
        % Create a communicator which can be used to send/receive
        % messages to/from client
        message.publish("/matlab/addons/serverToClient", messageToClient);
    else
        matlab.internal.addons.launchers.showManager(entryPointIdentifier, 'openUrl', installerUrl);
    end
end

