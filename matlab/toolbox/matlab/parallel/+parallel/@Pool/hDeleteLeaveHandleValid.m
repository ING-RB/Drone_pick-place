function hDeleteLeaveHandleValid(aPool)
%

%   Copyright 2019 The MathWorks, Inc.

% This is invoked when a pool is removed from gcp. It exists to allow a pool
% object to cleanup resources without becoming an invalid object. Child
% classes should only override this if they support (Connected == false).

delete(aPool);
end
