% Sets this as a prototype instance

% Copyright 2014-2023 The MathWorks, Inc.

function setPrototype(isPrototype)
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    utilsInstance.IsPrototype = isPrototype;
end