% Manager tracking all pools in the current MATLAB context.
% Pools are held by weak reference and can only be reached if
% they are still alive via some other external reference.

% Copyright 2021-2024 The MathWorks, Inc.

classdef PoolManager < handle

    properties (Access = private)
        % Map of pools held by a weak reference
        WeakPools
    end

    events (Hidden)
        % A new pool has been added. Used by tests to react to creation of
        % pools other than gcp. The toolbox API for responding to changes
        % to gcp is parallel.internal.parpool.subscribePoolCreation.
        PoolBeingAddedEvent
    end

    methods (Access = private)
        function obj = PoolManager()
            obj.WeakPools = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function addWeakPoolReference(obj, pool, apiTag)
            import parallel.internal.pool.PoolEventData

            poolID = pool.hGetUUID();
            if ~isKey(obj.WeakPools, poolID)
                obj.WeakPools(poolID) = iCreateWeakPoolEntry(pool, apiTag);
                poolEventData = PoolEventData(pool, apiTag);
                notify(obj, "PoolBeingAddedEvent", poolEventData);
            end
        end
    end
    
    methods
        function addPool(obj, pool, apiTag)
            % Add a weak reference to the pool. Allows the pool to be
            % retrieved from the manager if there still exists a strong
            % reference to it elsewhere.
            arguments
                obj (1,1) parallel.internal.pool.PoolManager
                pool (1,1) parallel.Pool
                apiTag (1,1) parallel.internal.pool.PoolApiTag
            end

            cleanupStalePools(obj);
            obj.addWeakPoolReference(pool, apiTag);
        end

        function pools = getAllPools(obj, apiTag)
            % Get all active pools. The caller must provide an API
            % tag specifying which owning APIs to filter the results by.
            arguments
                obj (1,1) parallel.internal.pool.PoolManager
                apiTag (1,1) parallel.internal.pool.PoolApiTag = parallel.internal.pool.PoolApiTag.Parpool
            end

            cleanupStalePools(obj);

            allRefs = obj.WeakPools.values();
            if isempty(allRefs)
                pools = parallel.Pool.empty();
                return
            end

            if nargin > 1
                % Filter by tag if requested
                poolTags = cellfun(@(r) r.Tag, allRefs);
                allRefs = allRefs(poolTags == apiTag);
                if isempty(allRefs)
                    pools = parallel.Pool.empty();
                    return
                end
            end

            % All valid due to cleanupStalePools
            for idx = 1:numel(allRefs)
                pools(idx) = allRefs{idx}.Pool.Handle; %#ok<AGROW>
            end
        end

        function pool = getPoolFromUUID(obj, poolUuid)
            % Retrieve a pool handle given an associated ID. If ID is
            % not found, an empty pool is returned.
            cleanupStalePools(obj);

            if isKey(obj.WeakPools, poolUuid)
                poolRef = obj.WeakPools(poolUuid);
                pool = poolRef.Pool.Handle; % Valid due to cleanupStalePools
            else
                pool = parallel.Pool.empty();
            end
        end
        
        function cleanupStalePools(obj)
            % Clean up all invalid or unusable weak references
            pools = obj.WeakPools.values();
            if ~isempty(pools)
                poolValid = cellfun(@(r) isvalid(r.Pool.Handle) && hGetIsUsable(r.Pool.Handle), pools);
                poolIDs = obj.WeakPools.keys();
                invalidPoolIDs = poolIDs(~poolValid);
                poolsToDelete = obj.WeakPools.values(invalidPoolIDs);
                obj.WeakPools = obj.WeakPools.remove(invalidPoolIDs);

                for idx = 1:numel(poolsToDelete)
                    poolToDelete = poolsToDelete{idx};
                    poolToDelete = poolToDelete.Pool.Handle;
                    if isvalid(poolToDelete)
                        hDeleteLeaveHandleValid(poolToDelete);
                    end
                end
            end
        end
        
        function cleanupAllPools(obj)
            % Do all state manipulation before calling delete
            % as this method might call back into PoolManager.
            cleanupStalePools(obj);

            poolsToDelete = obj.WeakPools.values();
            obj.WeakPools = containers.Map('KeyType', 'char', 'ValueType', 'any');

            for idx = 1:numel(poolsToDelete)
                poolToDelete = poolsToDelete{idx};
                poolToDelete = poolToDelete.Pool.Handle;
                if isvalid(poolToDelete)
                    delete(poolToDelete);
                end
            end
        end
    end
    
    methods (Static)
        function obj = getInstance()
            % Get the singleton PoolManager for this MATLAB context.
            mlock;
            persistent SINGLETON
            if isempty(SINGLETON)
                SINGLETON = parallel.internal.pool.PoolManager();
            end
            obj = SINGLETON;
        end
    end
end

function s = iCreateWeakPoolEntry(pool, apiTag)
s = struct('Pool', matlab.lang.WeakReference(pool), 'Tag', apiTag);
end
