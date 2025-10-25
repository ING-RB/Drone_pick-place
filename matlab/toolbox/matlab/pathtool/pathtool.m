function pathtool
%PATHTOOL Open Set Path dialog box to view and change search path
%   PATHTOOL opens the MATLAB Set Path tool, which allows you to view,
%   manipulate, and save the MATLAB search path.
%
%   See also PATH, ADDPATH, RMPATH, SAVEPATH.

%   Copyright 1984-2023 The MathWorks, Inc.

    % Launch JavaScript Path Tool Window
    import matlab.internal.capability.Capability;
    isLocal = Capability.isSupported(Capability.LocalClient);
    isDesktop = desktop('-inuse');
    isJavaDesktop = Capability.isSupported(Capability.LocalClient) && ~matlab.internal.feature('webui');
    if isJavaDesktop
        try
            % Launch Java Path Browser
            com.mathworks.pathtool.PathToolLauncher.invoke;
        catch
            error(message('MATLAB:pathtool:PathtoolFailed'));
        end
    else
        if (isLocal && ~isDesktop)
            error(message('MATLAB:desktop:desktopNotFoundCommandFailure'));
        else
            ChannelToPublish = '/pathtool/ServerToClient';
            ChannelToSubscribe = '/pathtool/ClientToServer';
            messageToClient = struct('type', 'showPathToolWindow');
            connector.ensureServiceOn;
            message.publish(ChannelToPublish, messageToClient);
        end
    end
end