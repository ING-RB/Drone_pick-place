% Event Data pools being added

% Copyright 2021-2024 The MathWorks, Inc.

classdef PoolEventData < handle & event.EventData
    properties (SetAccess = immutable)
        % Pool object itself
        Pool
        
        % Tag specifying which API owns the pool
        ApiTag
    end
    
    methods
        function obj = PoolEventData(pool, apiTag)
            obj.Pool = pool;
            obj.ApiTag = apiTag;
        end
    end
end
