% Sets the log level

% Copyright 2014-2023 The MathWorks, Inc.

function setLogLevel(logLevel)
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    utilsInstance.Debuglevel = uint64(logLevel);
    publishData = struct('eventType','setLogFlagFromServer');
    publishData.flag = logLevel;
    message.publish('/VELogChannel',publishData);
end
