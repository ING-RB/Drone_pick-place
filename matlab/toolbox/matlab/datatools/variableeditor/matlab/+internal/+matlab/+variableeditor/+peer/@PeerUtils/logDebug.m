% Log a debug message

% Copyright 2014-2023 The MathWorks, Inc.

function logDebug(peerNode, class, method, message, varargin)
    internal.matlab.variableeditor.peer.PeerUtils.logMessage(...
        peerNode, class, method, message, ...
        internal.matlab.variableeditor.peer.PeerUtils.DEBUG, ...
        varargin{:});
end