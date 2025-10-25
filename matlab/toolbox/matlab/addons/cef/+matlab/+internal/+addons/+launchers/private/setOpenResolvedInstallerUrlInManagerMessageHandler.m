function setOpenResolvedInstallerUrlInManagerMessageHandler()

    % setOpenUrlMessageHandler: Registers a handler for
    % "openResolvedInstallerUrlInManager" from the client
    
    % This is a temporary workaround until we have an API that generates
    % the correct URL in worker environment
    
    %   Copyright: 2019-2021 The MathWorks, Inc.
    mlock;
    persistent subscriptionId;

    if (isempty(subscriptionId))
        % ToDo: Create a communicator to send and receive messages to/from
        % client
        subscriptionId = message.subscribe("/matlab/addons/clientToServer", @(msg) clientMessageHandler(msg));
    end

    function clientMessageHandler(msg)
        if strcmp(msg.type,'openResolvedInstallerUrlInManager') == 1
            matlab.internal.addons.launchers.showManager('installer', 'openUrl', msg.url);
        end
    end
end

