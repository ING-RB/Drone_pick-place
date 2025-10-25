function handleObjectBeingDestroyed(wp, channelID)
%

%   Copyright 2019-2023 The MathWorks, Inc.

    pHost = wp.get();
    if ~isempty(pHost)
        pHost.unregisterChannel(channelID);
    end
end
