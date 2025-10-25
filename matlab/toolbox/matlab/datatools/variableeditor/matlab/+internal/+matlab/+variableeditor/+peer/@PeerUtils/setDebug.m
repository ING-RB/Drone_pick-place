% adds/removes DEBUG to the existing debug level based on the value passed in

% Copyright 2014-2023 The MathWorks, Inc.

function setDebug(value)
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    newLevel = utilsInstance.Debuglevel;

    % if setDebug is called with true or no arguments then, we turn on the debug
    % flag and the existing log level logic - existinglevel || debug
    if isempty(value) || value
        newLevel = internal.matlab.variableeditor.peer.PeerUtils.addLogLevel(internal.matlab.variableeditor.peer.PeerUtils.DEBUG);
    else
        % if setDebug is called with false, then we turn off debugging if it is
        % true
        if internal.matlab.variableeditor.peer.PeerUtils.isDebug()
            newLevel = internal.matlab.variableeditor.peer.PeerUtils.removeLogLevel(internal.matlab.variableeditor.peer.PeerUtils.DEBUG);
        end
    end

    internal.matlab.variableeditor.peer.PeerUtils.setLogLevel(newLevel);
end