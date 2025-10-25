% Sets filtering in the Variable Editor on

% Copyright 2014-2023 The MathWorks, Inc.

function setVEFilteringOn(state)
    utilsInstance = internal.matlab.variableeditor.peer.PeerUtils.getInstance();
    utilsInstance.FilteringInVEOn = state;
    message.publish('/dtFeatureFlag', struct('status', state));
end
