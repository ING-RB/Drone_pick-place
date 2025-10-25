% addLogLevel

% Copyright 2014-2023 The MathWorks, Inc.

function newLevel = addLogLevel(logLevel)
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    newLevel = bitor(utilsInstance.Debuglevel,logLevel);
end