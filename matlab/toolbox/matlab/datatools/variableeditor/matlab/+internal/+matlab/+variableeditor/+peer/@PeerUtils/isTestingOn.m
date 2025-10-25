% Returns true if this is a testing environment or not

% Copyright 2014-2023 The MathWorks, Inc.

function feature = isTestingOn()
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    feature = utilsInstance.IsTestingEnvironment;
end
