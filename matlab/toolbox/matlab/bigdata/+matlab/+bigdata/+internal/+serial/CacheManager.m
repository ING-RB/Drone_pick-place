%CacheManager
% Helper class that manages the caches for the serial implementation.
%

%   Copyright 2015-2018 The MathWorks, Inc.

classdef CacheManager < handle
    
    properties (SetAccess = immutable)
        % The underlying cache store.
        CacheStore;
    end
    
    properties (SetAccess = private)
        % A list of all CacheEntryKey Ids known by this object.
        CacheEntryIds = string.empty(0, 1);
    end
    
    methods
        % The main constructor.
        function obj = CacheManager()
            import matlab.bigdata.internal.io.DiskCacheStore;
            import matlab.bigdata.internal.io.MemoryCacheStore;
            
            % This CacheManager has both a memory and a disk cache store.
            % CacheStore uses array syntax to manage multiple cache store
            % objects.
            obj.CacheStore = MemoryCacheStore();
            if matlab.bigdata.internal.serial.CacheManager.enableDiskCache()
                obj.CacheStore = [obj.CacheStore; DiskCacheStore()];
            end
        end
        
        % Do all cache related pre-execution tasks.
        function setupForExecution(obj, cacheEntryKeys)
            obj.CacheStore.nextStage();
            
            % We want to ensure cleanup any cache entries relating to tall
            % arrays that have fallen out of scope.
            for cacheEntryKey = cacheEntryKeys(:)'
                if ~any(cacheEntryKey.Id == obj.CacheEntryIds)
                    cacheEntryKey.addInvalidateListener(@obj.cleanupCallback);
                    obj.CacheEntryIds = [obj.CacheEntryIds; cacheEntryKey.Id];
                end
            end
        end
        
        % Cleanup all memory cache usage.
        function dumpMemoryToDisk(obj)
            % This will move all entries from the memory cache store to the
            % disk cache store.
            if matlab.bigdata.internal.serial.CacheManager.enableDiskCache()
                copyEntries(obj.CacheStore(1), obj.CacheStore(2));
            end
            removeAllEntries(obj.CacheStore(1));
        end
    end
    
    methods (Access = private)
        % Helper function that performs cleanup of a cache entry key being
        % deleted.
        function cleanupCallback(obj, cacheEntryKey, ~)
            if ~isvalid(obj)
                return;
            end
            obj.CacheStore.removeEntry(cacheEntryKey);
            obj.CacheEntryIds(obj.CacheEntryIds == cacheEntryKey.Id, :) = [];
        end
    end
    
    methods (Static)
        function out = enableDiskCache(in)
            % Static flag that specifies if Serial back-end should use
            % local disk caching. This is true by default.
            persistent value;
            if isempty(value)
                value = true;
            end
            if nargout
                out = value;
            end
            if nargin
                value = in;
            end
        end
    end
end
