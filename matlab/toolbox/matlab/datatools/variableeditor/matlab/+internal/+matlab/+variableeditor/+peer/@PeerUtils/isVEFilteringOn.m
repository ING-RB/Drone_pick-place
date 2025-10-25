% Returns true if filtering is on in the Variable Editor

% Copyright 2014-2023 The MathWorks, Inc.

function feature = isVEFilteringOn()
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    feature = utilsInstance.FilteringInVEOn;
end
