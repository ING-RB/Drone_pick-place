function tf = hGetIsUsable(aPool)
%

%   Copyright 2019-2024 The MathWorks, Inc.

% This is invoked when a pool exists on gcp. It exists to allow a pool
% object to report whether it is still usable, even when it is no longer
% connected to the underlying resources. Child classes should override this
% if they support (Connected == false).

tf = isvalid(aPool) && aPool.Connected;
end
