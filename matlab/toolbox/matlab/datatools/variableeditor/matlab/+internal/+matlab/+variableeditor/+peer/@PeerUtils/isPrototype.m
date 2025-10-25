% Returns true if this is a prototype instance

% Copyright 2014-2023 The MathWorks, Inc.

function prototype = isPrototype()
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    prototype = utilsInstance.IsPrototype;
end