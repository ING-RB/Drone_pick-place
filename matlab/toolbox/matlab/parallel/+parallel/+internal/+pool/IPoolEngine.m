% IPoolEngine All parallel.Pools must implement hGetEngine which returns an
% instance of parallel.internal.pool.IPoolEngine. IPoolEngine encapsulates
% the non user-facing interface for parallel.Pool. This is the means by
% which the parallel language is executed on a pool.
% 

% Copyright 2024 The MathWorks, Inc.

classdef (Abstract) IPoolEngine < handle

    methods (Abstract)
        % Return true if underlying pool Session is valid and running
        tf = isSessionRunning(obj);

        % Create a scoped serialization context. This is used to capture
        % serialization of special types which require further action, such
        % as pool Constants.
        contextGuard = createSerializationContextGuard(obj);

        % Get the parallel.internal.constant.ConstantAssistant for the
        % given pool. This is used to broadcast pool Constants to all
        % workers.
        assistant = getConstantAssistant(obj);

        % Attempt to configure the pool for spmd. Return true if successful and
        % false if not.
        % Throws 'MATLAB:parallel:pool:InvalidPool' error if pool is
        % shutdown
        tf = initializeSpmd(obj);

        % Create a new spmdlang.AbstractRemoteResourceSet for the given
        % pool and number of workers. This will attempt to select idle
        % workers.
        % Throws 'MATLAB:parallel:pool:InvalidPool' error if pool is
        % shutdown
        resourceSet = createRemoteResourceSet(obj, numWorkers, pool);

        % Create a new parallel.internal.parfor.Engine for the given pool.
        % This is used to execute a single parfor block
        % Throws 'MATLAB:parallel:pool:InvalidPool' error if pool is
        % shutdown
        engine = createParforEngine(obj, rangePartitionMethod, subrangeSize, ...
            maxNumWorkers, initData, parforF);

        % Indicate on the shared Session that profiling data has been
        % gathered
        setPoolProfilerDataRetrieved(obj, dataRetrieved);

        % Collect the bytes send and received between the client and all
        % pool workers
        % Throws 'MATLAB:parallel:pool:InvalidPool' error if pool is
        % shutdown
        info = getCurrentBytesTransferredToInstances(obj);

        % Return true if pool supports auto attaching missing sources
        % detected from runtime errors
        tf = isAutoAttachSupported(obj);

        % Analyze the given files and attempt to auto attach missing files
        % to the pool. Returns the files attached, if any
        filesAttached = autoAttachDependentFiles(obj, filesToAnalyse);

        % If any of potentialFiles has been attached to the pool and
        % changed, resend them to the pool. Does not block for update to
        % complete
        triggerUpdateAttachedFiles(obj, potentialFiles);

        % Return a new pool of the same type but which executes work only
        % on the specified workers
        poolPartition = createPoolPartition(obj, desiredWorkers);
    end

    methods
        % Throws 'MATLAB:parallel:pool:InvalidPool' error if pool is
        % shutdown. This should be used to present a standard error for the
        % usage of any shutdown pool
        function throwIfShutdown(obj)
            if ~isSessionRunning(obj)
                error(message('MATLAB:parallel:pool:InvalidPool'));
            end
        end
    end
    
end
