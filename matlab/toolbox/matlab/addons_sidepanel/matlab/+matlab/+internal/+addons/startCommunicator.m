function startCommunicator()
%STARTCOMMUNICATOR Starts Java communication necessary for legacy Java
% add-on installers
%   This is a temporary function necessary to start Java communication
%   required for certain legacy add-on installers. This function could be
%   removed at any time.
    persistent hasRun;
    if isempty(hasRun)
        hasRun = true;
        addOnsCommunicator = com.mathworks.addons.sidepanel.Communicator(matlab.internal.addons.Sidepanel.SERVER_TO_CLIENT_CHANNEL, matlab.internal.addons.Sidepanel.CLIENT_TO_SERVER_CHANNEL);
        addOnsCommunicator.startMessageService;
    end
end