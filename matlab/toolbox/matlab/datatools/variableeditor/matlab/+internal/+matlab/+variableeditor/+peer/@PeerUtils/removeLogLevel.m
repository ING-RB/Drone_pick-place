% Removes the log level

% Copyright 2014-2023 The MathWorks, Inc.

function newLevel = removeLogLevel(logLevel)
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    if utilsInstance.Debuglevel >= logLevel
        newLevel = bitxor(utilsInstance.Debuglevel,logLevel);
    end
end