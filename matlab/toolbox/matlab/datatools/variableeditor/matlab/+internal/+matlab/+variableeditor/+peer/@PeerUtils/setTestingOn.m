% Sets testing on

% Copyright 2014-2023 The MathWorks, Inc.

function setTestingOn(state)
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    utilsInstance.IsTestingEnvironment = state;
end
