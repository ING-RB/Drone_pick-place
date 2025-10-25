% DefaultPoolEngine Implementation of parallel.internal.pool.IPoolEngine for
% - parallel.BackgroundPool
% - matlab.internal.ThreadPool
% - matlab.internal.SerialPool
% 
% This implementation does not support features such as spmd or profiling

% Copyright 2024 The MathWorks, Inc.

classdef DefaultPoolEngine < parallel.internal.pool.IPoolEngine
        
    properties (WeakHandle, SetAccess = immutable, GetAccess = private)
        % Weak handle to parent so we can access it without adding a cyclic
        % dependency. This session lifetime is tied to the pool.
        Pool parallel.Pool = parallel.Pool.empty()
    end

    properties (SetAccess = private, GetAccess = private)
        ConstantAssistant = [];
    end

    methods
        function obj = DefaultPoolEngine(pool)
            arguments
                pool (1,1) parallel.Pool
            end
            obj.Pool = pool;
        end
    end

    % Implement IPoolEngine methods
    methods
        function tf = isSessionRunning(obj)
            tf = ~isempty(obj.Pool) && isvalid(obj.Pool) && obj.Pool.Connected;
        end

        function contextGuard = createSerializationContextGuard(obj)
            contextGuard = parallel.internal.pool.SerializationContextGuard(obj.Pool.hGetUUID());
        end

        function assistant = getConstantAssistant(obj)
            if isempty(obj.ConstantAssistant)
                obj.ConstantAssistant = parallel.internal.constant.ThreadsConstantAssistant();
            end
            assistant = obj.ConstantAssistant;
        end

        function tf = initializeSpmd(obj)
            throwIfShutdown(obj);
            tf = obj.Pool.SpmdEnabled;
        end

        function engine = createParforEngine(obj, rangePartitionMethod, subrangeSize, ...
            maxNumWorkers, initData, ~)
            throwIfShutdown(obj);
            engine = parallel.internal.parfor.ThreadsParforEngine(...
                rangePartitionMethod, subrangeSize, ...
                obj.Pool, maxNumWorkers, initData);
        end

        function info = getCurrentBytesTransferredToInstances(~)
            % Return empty map since no data is actually transferred
            info = containers.Map('KeyType', 'double', 'ValueType', 'any');
        end

        function tf = isAutoAttachSupported(~)
            % Workers and client see the same files, so no need to attach
            tf = false;
        end

        function filesAttached = autoAttachDependentFiles(~, ~)
            % Workers and client see the same files, so no need to attach
            filesAttached = {};
        end

        function triggerUpdateAttachedFiles(~, ~)
            % Noop as we never attach anything
        end

        % Unsupported operations for 
        % - spmd
        % - mpiprofile
        % - partition

        function createRemoteResourceSet(obj, ~, ~)
            obj.Pool.unsupportedFeatureError();
        end

        function setPoolProfilerDataRetrieved(obj)
            obj.Pool.unsupportedFeatureError();
        end

        function createPoolPartition(obj, ~)
            obj.Pool.unsupportedFeatureError();
        end
    end
end
