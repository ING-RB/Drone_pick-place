% returns true is the current debugging level includes INFO

% Copyright 2014-2023 The MathWorks, Inc.

function info = isInfo()
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    info = bitand(utilsInstance.Debuglevel, internal.matlab.variableeditor.peer.PeerUtils.INFO);
end