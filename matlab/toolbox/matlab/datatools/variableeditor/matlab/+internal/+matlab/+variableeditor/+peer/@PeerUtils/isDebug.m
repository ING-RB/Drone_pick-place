% returns true if the current debugging level includes DEBUG

% Copyright 2014-2023 The MathWorks, Inc.

function debug = isDebug()
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    debug = bitand(utilsInstance.Debuglevel, internal.matlab.variableeditor.peer.PeerUtils.DEBUG);
end