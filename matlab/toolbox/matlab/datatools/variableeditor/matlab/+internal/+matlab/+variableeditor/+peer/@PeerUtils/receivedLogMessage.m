% Updates the debug level

% Copyright 2014-2023 The MathWorks, Inc.

function receivedLogMessage(msg)
    if strcmp(msg.eventType,'setLogFlagFromClient')
        utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
        utilsInstance.Debuglevel = msg.LogLevel;
    end
end
