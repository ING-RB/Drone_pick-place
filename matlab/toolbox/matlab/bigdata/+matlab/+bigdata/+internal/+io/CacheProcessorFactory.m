%CacheProcessorFactory
% Factory for building a CacheProcessor

%   Copyright 2018-2022 The MathWorks, Inc.

classdef (Sealed) CacheProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Key that identifies the cache entry corresponding with the CacheProcessor.
        CacheEntryKey (1,1)
        
        % Function to retrieve the CacheEntryStore object for the local
        % process.
        %
        % This must have signature:
        %  cacheEntryStore = fcn()
        GetCacheStoreFunction
        
        % Number of variables to be cached together
        NumVariables (1,1) double
    end
    
    methods
        function obj = CacheProcessorFactory(cacheEntryKey, getCacheStoreFunction, numVariables)
            % Build a CacheProcessorFactory whose processor either captures
            % or retrieves data from cache entries.
            obj.CacheEntryKey = cacheEntryKey;
            obj.GetCacheStoreFunction = getCacheStoreFunction;
            obj.NumVariables = numVariables;
        end
        
        % Build the processor.
        function processor = feval(obj, partitionContext, ~)
            import matlab.bigdata.internal.io.LocalReadProcessor;
            import matlab.bigdata.internal.io.LocalWriteProcessor;
            import matlab.bigdata.internal.io.CacheProcessor;
            cacheEntryStore = feval(obj.GetCacheStoreFunction);
            
            partitionIndex = partitionContext.PartitionIndex;
            [reader, writer] = cacheEntryStore.openOrCreateEntry(obj.CacheEntryKey, partitionIndex);
            if ~isempty(reader)
                reader = LocalReadProcessor(reader, obj.NumVariables);
            end
            if ~isempty(writer)
                writer = LocalWriteProcessor(writer, obj.NumVariables);
            end
            processor = CacheProcessor(reader, writer, obj.NumVariables);
        end
    end
end
