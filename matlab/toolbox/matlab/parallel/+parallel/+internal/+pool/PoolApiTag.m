% Tag specifying the owning API of a given parallel pool

% Copyright 2021 The MathWorks, Inc.

classdef PoolApiTag
    enumeration
        % Pool owned by parpool/gcp
        Parpool
        
        % Pool owned by backgroundPool
        Background
        
        % Pool owned by other internal code
        Internal
    end
end
