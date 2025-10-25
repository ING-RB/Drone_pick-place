function arguments = wrapNonTallAsBroadcast(arguments)
% Wrap non-tall arguments as BroadcastArray objects.
%
% This exists to send like parameters to workers, which will have height 0
% to minimize communication cost.

%   Copyright 2018 The MathWorks, Inc.

for ii = 1:numel(arguments)
    if ~istall(arguments{ii})
        arguments{ii} = matlab.bigdata.internal.broadcast(arguments{ii});
    end
end
end
