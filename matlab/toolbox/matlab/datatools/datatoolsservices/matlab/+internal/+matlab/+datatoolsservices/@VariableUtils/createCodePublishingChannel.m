% Returns the unique channel name for unique windows appended by the variable
% name.

% Copyright 2020-2022 The MathWorks, Inc.

function channel = createCodePublishingChannel(namespace, channelSuffix)
    if strncmpi(namespace, '/' , 1 )
        channel = [eraseBetween(namespace,1,1) '/' channelSuffix];
    else
        channel = [namespace '/' channelSuffix];
    end
end